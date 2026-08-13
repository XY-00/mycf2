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

    debugPrint('HardwareStatusManager: Monitoring started successfully!');
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
  }

  static void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  static Future<void> checkHardwareConnection() async {
    try {
      final supabase = Supabase.instance.client;
      
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
          // 👑 终极核心修复：切掉 Supabase 强加的 "+00" 时区尾巴
          // 把 "2026-08-13 20:16:45+00" 变成干净的 "2026-08-13 20:16:45"
          String rawTime = lastSeenStr;
          if (rawTime.contains('+')) {
            rawTime = rawTime.split('+')[0];
          } else if (rawTime.endsWith('Z')) {
            rawTime = rawTime.replaceAll('Z', '');
          }

          // 这样 Flutter 就会把它当做和手机一模一样的本地时间
          DateTime piLastTimeLocal = DateTime.parse(rawTime);
          int diffSeconds = DateTime.now().difference(piLastTimeLocal).inSeconds;
          
          debugPrint('Pi LastSeen (Clean Local): $piLastTimeLocal, Now: ${DateTime.now()}, Diff: $diffSeconds');
          
          // 树莓派每 2 秒发一次。误差允许 -10秒 到 6秒。超过 6 秒即判定关机离线！
          piOnline = (diffSeconds >= -10 && diffSeconds <= 6); 
        }
      }

      // DHT11 也做同样的切除时差处理
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
            String rawDhtTime = recordedStr;
            if (rawDhtTime.contains('+')) rawDhtTime = rawDhtTime.split('+')[0];
            else if (rawDhtTime.endsWith('Z')) rawDhtTime = rawDhtTime.replaceAll('Z', '');

            DateTime dhtLastTimeLocal = DateTime.parse(rawDhtTime);
            int dhtDiff = DateTime.now().difference(dhtLastTimeLocal).inSeconds;
            dhtOnline = (dhtDiff >= -10 && dhtDiff <= 7);
          }
        }
      } catch (e) {
        dhtOnline = false;
      }

      // 👑 完美逻辑控制：
      if (_lastPiStatus == null) {
        // 【1. 登录瞬间（第一次检查）】
        _lastPiStatus = piOnline;
        if (piOnline) {
          // 需求：如果 login 时已经开机了，就直接出弹窗
          _sendNotification(
            'myCF Connected', 
            'System successfully connected to myCF (Raspberry Pi is online).'
          );
        }
        // 需求：如果没有开机，就不需要弹窗（静默过去，直接变 Unconnected）
        debugPrint('Initial Pi Status initialized. Is Online: $piOnline');
      } else {
        // 【2. 运行过程中的状态改变】
        if (piOnline != _lastPiStatus) {
          _lastPiStatus = piOnline;
          if (piOnline) {
            _sendNotification(
              'myCF Connected', 
              'System successfully connected to myCF (Raspberry Pi is online).'
            );
          } else {
            // 需求：如果关机了，大概 5~6 秒这样就会因为超时跳到这里，弹出关机信息！
            _sendNotification(
              'CRITICAL WARNING: myCF OFF', 
              'Cannot connect to myCF! Raspberry Pi is offline or powered off.'
            );
          }
        }
      }

      isPiConnected = piOnline;
      isDhtConnected = dhtOnline; 
      isFloatConnected = false; 

      _notifyListeners();
      
    } catch (e) {
      debugPrint('Hardware connection check error or timeout: $e');
      if (_lastPiStatus != null && _lastPiStatus != false) {
        _lastPiStatus = false;
        _sendNotification(
          'CRITICAL WARNING: myCF OFF', 
          'Connection error! myCF is offline.'
        );
      }
      _lastPiStatus = false;
      isPiConnected = false;
      isDhtConnected = false;
      isFloatConnected = false;
      
      _notifyListeners();
    }
  }

  static Future<void> _sendNotification(String title, String body) async {
    if (_notificationsPlugin == null) return;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mycf_hardware_channel_id',
      'myCF Hardware Status Alerts',
      channelDescription: 'Notifications for Raspberry Pi connection changes',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'myCF Hardware Alert',
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

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin!.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
    );
  }

  static Widget buildStatusRow(String title, bool isConnected) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title, 
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87), 
              overflow: TextOverflow.ellipsis,
            ),
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