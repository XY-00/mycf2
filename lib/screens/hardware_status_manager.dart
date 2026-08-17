// lib/hardware_status_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

class HardwareStatusManager {
  static bool isPiConnected = false;     
  static bool isDhtConnected = false;    
  static bool isFloatConnected = false;  

  static bool? _lastPiStatus; 
  static Timer? _statusCheckTimer;
  static FlutterLocalNotificationsPlugin? _notificationsPlugin;
  static bool _isInitialized = false;
  
  static final Map<int, bool> _plantAlertLocks = {};
  static final List<VoidCallback> _listeners = [];
  static final AudioPlayer _audioPlayer = AudioPlayer();

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
    
    isPiConnected = false;
    isDhtConnected = false;
    isFloatConnected = false;
    _lastPiStatus = null;
    _plantAlertLocks.clear();
    _audioPlayer.dispose();
    _notifyListeners();
    debugPrint('HardwareStatusManager: Monitoring stopped and fully reset.');
  }

  static void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  // 👑 触发水箱 0% 警报横幅与声音
  static Future<void> triggerTankEmptyAlert() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'));
    } catch (e) {
      debugPrint('Audio play error: $e');
    }

    if (_notificationsPlugin != null) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'mycf_tank_alert_channel_id',
        'myCF Water Tank & System Alerts',
        channelDescription: 'Notifications for water tank storage and system alerts',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'myCF Alert',
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(
          'Float sensor detected water tank is empty (0%)! Water pumps have been automatically locked.',
          contentTitle: 'CRITICAL WARNING: TANK EMPTY',
        ),
      );

      await _notificationsPlugin!.show(
        999,
        'CRITICAL WARNING: TANK EMPTY',
        'Float sensor detected water tank is empty (0%)! Water pumps have been automatically locked.',
        const NotificationDetails(android: androidDetails),
      );
    }
  }

  static Future<void> checkHardwareConnection() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        isPiConnected = false;
        isDhtConnected = false;
        isFloatConnected = false;
        _notifyListeners();
        return;
      }
      
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

      // 3. 后台湿度异常警报
      if (piOnline) {
        try {
          final userPlantsResponse = await supabase
              .from('plants')
              .select('slot_number')
              .eq('user_id', user.id) 
              .eq('status', 'active');

          final Set<int> myActiveSlots = {};
          if (userPlantsResponse != null) {
            for (var p in userPlantsResponse) {
              if (p['slot_number'] != null) {
                myActiveSlots.add(p['slot_number'] as int);
              }
            }
          }

          if (myActiveSlots.isNotEmpty) {
            final hardwareResponse = await supabase
                .from('hardware_status')
                .select('slot_number, moisture_level, sensor_connected, updated_at')
                .eq('user_id', user.id); 

            if (hardwareResponse != null) {
              for (var item in hardwareResponse) {
                int slot = item['slot_number'] ?? 1;
                double moisture = (item['moisture_level'] ?? 0.0).toDouble();
                bool sensorConn = item['sensor_connected'] ?? false;

                final updatedAtStr = item['updated_at']?.toString();
                if (updatedAtStr != null) {
                  String rawTime = updatedAtStr.contains('+') ? updatedAtStr.split('+')[0] : updatedAtStr.replaceAll('Z', '');
                  DateTime lastUpdateTime = DateTime.parse(rawTime);
                  int diffSeconds = DateTime.now().difference(lastUpdateTime).inSeconds;
                  if (diffSeconds > 15) {
                    sensorConn = false; 
                  }
                } else {
                  sensorConn = false;
                }

                if (myActiveSlots.contains(slot) && sensorConn && moisture <= 59.0) {
                  if (_plantAlertLocks[slot] != true) {
                    _plantAlertLocks[slot] = true; 
                    _sendSystemPushNotification(
                      100 + slot, 
                      'SOIL MOISTURE EXCEPTION',
                      'Plant Slot $slot soil moisture dropped to ${moisture.toStringAsFixed(1)}%! Please check if the sensor is properly inserted in soil.'
                    );
                  }
                } else if (moisture > 60.0 || !myActiveSlots.contains(slot) || !sensorConn) {
                  _plantAlertLocks[slot] = false; 
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Background plant moisture check error: $e');
        }
      }

      if (_lastPiStatus == null) {
        _lastPiStatus = piOnline;
        if (piOnline) {
          _sendSystemPushNotification(1, 'myCF Connected', 'System successfully connected to myCF (Raspberry Pi is online).');
        }
      } else {
        if (piOnline != _lastPiStatus) {
          _lastPiStatus = piOnline;
          if (piOnline) {
            _sendSystemPushNotification(1, 'myCF Connected', 'System successfully connected to myCF (Raspberry Pi is online).');
          } else {
            _sendSystemPushNotification(2, 'CRITICAL WARNING: myCF OFF', 'Cannot connect to myCF! Raspberry Pi is offline or powered off.');
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
        _sendSystemPushNotification(2, 'CRITICAL WARNING: myCF OFF', 'Connection error! myCF is offline.');
      }
      isPiConnected = false;
      isDhtConnected = false;
      isFloatConnected = false;
      _notifyListeners();
    }
  }

  static Future<void> _sendSystemPushNotification(int notificationId, String title, String body) async {
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
      notificationId, 
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