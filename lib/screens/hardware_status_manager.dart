import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HardwareStatusManager {
  // 独立的动态连接状态变量（静态缓存，切页面不闪烁）
  static bool isPiConnected = false;     // myCF (树莓派总开机状态)
  static bool isDhtConnected = false;    // DHT11 传感器状态
  static bool isFloatConnected = false;  // 浮子水位传感器状态

  // 用于检测的缓存变量
  static int _lastCheckedId = -1;
  static int _unchangedCount = 0;
  static Timer? _statusCheckTimer;

  // 初始化定时轮询
  static void startMonitoring(VoidCallback onUpdate) {
    // 首次进入立即检测一次
    checkHardwareConnection(onUpdate);

    // 每 5 秒轮询一次数据库
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      checkHardwareConnection(onUpdate);
    });
  }

  // 停止轮询
  static void stopMonitoring() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
  }

  // 核心检测逻辑
  static Future<void> checkHardwareConnection(VoidCallback onUpdate) async {
    try {
      final supabase = Supabase.instance.client;
      
      final response = await supabase
          .from('dht11_logs')
          .select('id, recorded_at')
          .order('id', ascending: false)
          .limit(1);

      if (response != null && (response as List).isNotEmpty) {
        final lastRecordTimeStr = response.first['recorded_at']?.toString();
        int latestId = int.tryParse(response.first['id'].toString()) ?? -1;

        bool piOnline = false;
        if (lastRecordTimeStr != null) {
          DateTime lastTime = DateTime.parse(lastRecordTimeStr).toLocal();
          Duration difference = DateTime.now().difference(lastTime);
          
          // 超过 15 秒没有新数据，判定树莓派关机 (Unconnected)
          piOnline = difference.inSeconds < 15;
        }

        // 检查 DHT11 脚本是否在持续运行（ID 是否增长）
        if (latestId == _lastCheckedId) {
          _unchangedCount++;
        } else {
          _lastCheckedId = latestId;
          _unchangedCount = 0;
        }
        bool dhtOnline = _unchangedCount < 1 && piOnline; 

        // 树莓派关机时，水位传感器同步断开
        bool floatOnline = piOnline;

        isPiConnected = piOnline;
        isDhtConnected = dhtOnline;
        isFloatConnected = floatOnline;

        onUpdate();
        return;
      }
      
      // 查不到记录时全部置为离线
      isPiConnected = false;
      isDhtConnected = false;
      isFloatConnected = false;
      onUpdate();
      
    } catch (e) {
      debugPrint('Hardware connection check error: $e');
      isPiConnected = false;
      isDhtConnected = false;
      isFloatConnected = false;
      onUpdate();
    }
  }

  // 渲染状态行组件
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