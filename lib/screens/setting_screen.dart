import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  double _threshold = 59.0;
  bool _manualMode = false;

  // 🌿 这里的控制命令直连 Firebase，树莓派上的 Python 脚本听到后会立刻用 GPIO 拔掉或合上 5V 继电器！
  void _setPumpState(bool turnOn) async {
    await FirebaseDatabase.instance.ref('control_panel').update({
      'manual_pump_trigger': turnOn ? 1 : 0,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(turnOn ? 'Submersible Pump Triggered: ON' : 'Submersible Pump Triggered: OFF')),
      );
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
            // 59% 红色数值滑块控制区
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

            // 手动强刷水泵开关箱
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
                        if (!v) _setPumpState(false); // 关闭手动模式时强行关闭水泵，确保硬件安全
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