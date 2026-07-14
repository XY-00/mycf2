import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 👑 移除了旧 firebase 导入，修改为 supabase 导入

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  double _threshold = 59.0;
  bool _manualMode = false;

  // 👑 核心修改：移除旧 FirebaseDatabase 命令，转为用最简洁的 Supabase 执行远程水泵模式切换
  void _setPumpState(bool turnOn) async {
    try {
      await Supabase.instance.client
          .from('control_panel')
          .update({'manual_pump_trigger': turnOn ? 1 : 0})
          .eq('id', 1); // 假设你的控制面板表里有一行基础配置 id 为 1

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(turnOn ? 'Submersible Pump Triggered: ON' : 'Submersible Pump Triggered: OFF')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update control panel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setting', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF497E66), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Carbon Red-line Target Controls', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${_threshold.toStringAsFixed(1)} %', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Slider(
                      value: _threshold,
                      min: 40,
                      max: 80,
                      activeColor: const Color(0xFF497E66),
                      onChanged: (v) => setState(() => _threshold = v)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  SwitchListTile(
                      title: const Text('Enable Manual Override Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                      value: _manualMode,
                      activeColor: const Color(0xFF497E66),
                      onChanged: (v) {
                        setState(() => _manualMode = v);
                        if (!v) _setPumpState(false); 
                      }
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _manualMode ? () => _setPumpState(true) : null,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2A154)),
                      child: const Text('Activate 5V Submersible Pump Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}