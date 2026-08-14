import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HardwareStatusManager {
  static bool isPiConnected = false;     
  static bool isDhtConnected = false;    
  static bool isFloatConnected = false;  

  static bool? _lastPiStatus; 
  static Timer? _statusCheckTimer;
  static FlutterLocalNotificationsPlugin? _notificationsPlugin;
  static bool _isInitialized = false;
  
  // 记录各个植物槽位上一次是否已经弹过湿度警报，防止重复轰炸
  static final Map<int, bool> _plantAlertLocks = {};

  static final List<VoidCallback> _listeners = [];

  static void initNotifications(FlutterLocalNotificationsPlugin plugin) {
    _notificationsPlugin = plugin;
  }

  static void startMonitoring(VoidCallback onUpdate) {
    if (!_listeners.contains(onUpdate)) {
      _listeners.add(onUpdate);
    }

    if (_isInitialized) return;
    _isInitialized = true;

    debugPrint('HardwareStatusManager: Global monitoring started successfully!');
    _lastPiStatus = null; 
    checkHardwareConnection();

    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      checkHardwareConnection();
    });
  }

  static void addListener(VoidCallback onUpdate) {
    if (!_listeners.contains(onUpdate)) {
      _listeners.add(onUpdate);
    }
  }

  static void removeListener(VoidCallback onUpdate) {
    _listeners.remove(onUpdate);
  }

  static void stopMonitoring() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
    _isInitialized = false;
    _listeners.clear();
    
    // 👑 彻底重置所有连接状态并清空警报锁
    isPiConnected = false;
    isDhtConnected = false;
    isFloatConnected = false;
    _lastPiStatus = null;
    _plantAlertLocks.clear();
    _notifyListeners();
    debugPrint('HardwareStatusManager: Monitoring stopped and fully reset.');
  }

  static void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  static Future<void> checkHardwareConnection() async {
    try {
      final supabase = Supabase.instance.client;
      
      // 1. 检查树莓派主心跳
      final piResponse = await supabase
          .from('raspberry_pi_status')
          .select('last_seen')
          .order('id', ascending: false)
          .limit(1)
          .timeout(const Duration(seconds: 3));

      bool piOnline = false;
      if (piResponse != null && (piResponse as List).isNotEmpty) {
        final lastSeenStr = piResponse.first['last_seen']?.toString();
        if (lastSeenStr != null) {
          String rawTime = lastSeenStr.contains('+') ? lastSeenStr.split('+')[0] : lastSeenStr.replaceAll('Z', '');
          DateTime piLastTimeLocal = DateTime.parse(rawTime);
          int diffSeconds = DateTime.now().difference(piLastTimeLocal).inSeconds;
          piOnline = (diffSeconds >= -20 && diffSeconds <= 10); 
        }
      }

      // 2. 检查 DHT11 传感器状态
      bool dhtOnline = false;
      try {
        final dhtResponse = await supabase
            .from('dht11_logs')
            .select('recorded_at')
            .order('id', ascending: false)
            .limit(1)
            .timeout(const Duration(seconds: 3));

        if (dhtResponse != null && (dhtResponse as List).isNotEmpty) {
          final recordedStr = dhtResponse.first['recorded_at']?.toString();
          if (recordedStr != null) {
            String rawDhtTime = recordedStr.contains('+') ? recordedStr.split('+')[0] : recordedStr.replaceAll('Z', '');
            DateTime dhtLastTimeLocal = DateTime.parse(rawDhtTime);
            int dhtDiff = DateTime.now().difference(dhtLastTimeLocal).inSeconds;
            dhtOnline = (dhtDiff >= -20 && dhtDiff <= 10);
          }
        }
      } catch (e) {
        dhtOnline = false;
      }

      // 3. 全局后台常驻检查：树莓派在线且任意植物湿度跌到 59% 以下，发横幅通知
      if (piOnline) {
        try {
          final hardwareResponse = await supabase
              .from('hardware_status')
              .select('slot_number, moisture_level, sensor_connected');

          if (hardwareResponse != null) {
            for (var item in hardwareResponse) {
              int slot = item['slot_number'] ?? 1;
              double moisture = (item['moisture_level'] ?? 0.0).toDouble();
              bool sensorConn = item['sensor_connected'] ?? false;

              if (sensorConn && moisture <= 59.0) {
                if (_plantAlertLocks[slot] != true) {
                  _plantAlertLocks[slot] = true; 
                  _sendSystemPushNotification(
                    'SOIL MOISTURE EXCEPTION',
                    'Plant Slot $slot soil moisture dropped to ${moisture.toStringAsFixed(1)}%! Please check if the sensor is properly inserted in soil.'
                  );
                }
              } else if (moisture > 60.0) {
                _plantAlertLocks[slot] = false; 
              }
            }
          }
        } catch (e) {
          debugPrint('Background plant moisture check error: $e');
        }
      }

      // 4. 树莓派上下线通知判定
      if (_lastPiStatus == null) {
        _lastPiStatus = piOnline;
        if (piOnline) {
          _sendSystemPushNotification('myCF Connected', 'System successfully connected to myCF (Raspberry Pi is online).');
        }
      } else {
        if (piOnline != _lastPiStatus) {
          _lastPiStatus = piOnline;
          if (piOnline) {
            _sendSystemPushNotification('myCF Connected', 'System successfully connected to myCF (Raspberry Pi is online).');
          } else {
            _sendSystemPushNotification('CRITICAL WARNING: myCF OFF', 'Cannot connect to myCF! Raspberry Pi is offline or powered off.');
          }
        }
      }

      isPiConnected = piOnline;
      isDhtConnected = dhtOnline;
      isFloatConnected = false; 
      _notifyListeners();
      
    } catch (e) {
      debugPrint('Hardware connection check error: $e');
      if (_lastPiStatus != null && _lastPiStatus != false) {
        _lastPiStatus = false;
        _sendSystemPushNotification('CRITICAL WARNING: myCF OFF', 'Connection error! myCF is offline.');
      }
      isPiConnected = false;
      isDhtConnected = false;
      isFloatConnected = false;
      _notifyListeners();
    }
  }

  static Future<void> _sendSystemPushNotification(String title, String body) async {
    if (_notificationsPlugin == null) return;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mycf_hardware_channel_id',
      'myCF Hardware Status & Plant Alerts',
      channelDescription: 'Notifications for Raspberry Pi and Plant exceptions',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'myCF Alert',
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      category: AndroidNotificationCategory.call, 
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        htmlFormatContent: true,
        htmlFormatContentTitle: true,
      ),
    );

    await _notificationsPlugin!.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  static Widget buildStatusRow(String title, bool isConnected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87), overflow: TextOverflow.ellipsis),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isConnected ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isConnected ? Colors.green.shade200 : Colors.red.shade200),
            ),
            child: Text(
              isConnected ? 'Connected' : 'Unconnected',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isConnected ? Colors.green.shade700 : Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}