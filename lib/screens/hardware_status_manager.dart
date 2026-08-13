import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HardwareStatusManager {
  static bool isPiConnected = false;     
  static bool isDhtConnected = false;    
  static bool isFloatConnected = false;  

  static bool _lastPiStatus = false;
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

    _lastPiStatus = false;
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
          DateTime lastTime = DateTime.parse(lastSeenStr).toLocal();
          Duration difference = DateTime.now().difference(lastTime);
          piOnline = difference.inSeconds < 6; 
        }
      }

      // 严厉修复：必须使用绝对 UTC 时间差对比，防止切页面时被旧时间戳欺骗
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
            DateTime dhtLastTime = DateTime.parse(recordedStr);
            // 必须严格利用 .toUtc() 减去当前 UTC 时间，杜绝时区导致的负数或错误判定
            int dhtDiff = DateTime.now().toUtc().difference(dhtLastTime.toUtc()).inSeconds;
            dhtOnline = (dhtDiff >= 0 && dhtDiff < 7); // 只有 0 到 7 秒之间才算在线！超过或未来时间一律算离线！
          }
        }
      } catch (e) {
        dhtOnline = false;
      }

      if (piOnline != _lastPiStatus) {
        _lastPiStatus = piOnline;
        if (piOnline) {
          _sendNotification(
            'myCF Connected', 
            'System successfully connected to myCF (Raspberry Pi is online).'
          );
        } else {
          _sendNotification(
            'CRITICAL WARNING: myCF OFF', 
            'Cannot connect to myCF! Raspberry Pi is offline or powered off.'
          );
        }
      }

      isPiConnected = piOnline;
      isDhtConnected = dhtOnline; 
      isFloatConnected = false; 

      _notifyListeners();
      
    } catch (e) {
      debugPrint('Hardware connection check error or timeout: $e');
      if (_lastPiStatus != false) {
        _lastPiStatus = false;
        _sendNotification(
          'CRITICAL WARNING: myCF OFF', 
          'Connection error! myCF is offline.'
        );
      }
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