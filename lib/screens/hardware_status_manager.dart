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

  static void initNotifications(FlutterLocalNotificationsPlugin plugin) {
    _notificationsPlugin = plugin;
  }

  static void startMonitoring(VoidCallback onUpdate) {
    if (_isInitialized) return;
    _isInitialized = true;

    _lastPiStatus = false;

    checkHardwareConnection(onUpdate);

    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      checkHardwareConnection(onUpdate);
    });
  }

  static void stopMonitoring() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
    _isInitialized = false;
  }

  static Future<void> checkHardwareConnection(VoidCallback onUpdate) async {
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

      bool dhtOnline = piOnline; 

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

      onUpdate();
      
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
      onUpdate();
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