import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _carbonSaved = 146.0;
  double _moisture = 62.9;
  int _stabilityScore = 90;
  String _policyStatus = 'GREEN';

  @override
  void initState() {
    super.initState();
    // 🌿 秒级监听并接收树莓派通过 Firebase 上传的环境及水泵动态数据流
    FirebaseDatabase.instance.ref('live_status').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          _moisture = (data['soil_moisture'] ?? 62.9).toDouble();
          _carbonSaved = (data['carbon_saved'] ?? 146.0).toDouble();
          _stabilityScore = (data['stability_score'] ?? 90).toInt();
          _policyStatus = data['traffic_light_state'] ?? 'GREEN';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF497E66), centerTitle: true, elevation: 0),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/app_background.png', fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.15))),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('Monitoring the Carbon Footprint for Soil and Plant', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                // 🌿 1. 降碳总量展示区：调用你的 my_ic_carbonfootprint
                _buildCard(
                    child: Row(
                      children: [
                        Image.asset('assets/my_ic_carbonfootprint.png', width: 45, height: 45),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Carbon Footprint Saved', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text('$_carbonSaved mg CO₂ e', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    )
                ),

                // 🌿 2. 核心水分环形卡
                _buildCard(
                    color: _moisture < 59.0 ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(height: 110, width: 110, child: CircularProgressIndicator(value: _moisture / 100, strokeWidth: 10, color: _moisture < 59.0 ? Colors.orange : Colors.green)),
                            Text('$_moisture %', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Plant Hydration (%)', style: TextStyle(fontWeight: FontWeight.bold))
                      ],
                    )
                ),

                // 🌿 3. 碳稳定度百分环
                _buildCard(
                    color: const Color(0xFFFFEBEE),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(height: 100, width: 100, child: CircularProgressIndicator(value: _stabilityScore / 100, strokeWidth: 8, color: Colors.redAccent)),
                            Text('$_stabilityScore / 100', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Carbon Stability Score', style: TextStyle(fontWeight: FontWeight.bold))
                      ],
                    )
                ),

                // 🌿 4. 安全策略等级联动：调用你的 my_ic_activepolicy
                _buildCard(
                    child: ListTile(
                      leading: Image.asset('assets/my_ic_activepolicy.png', width: 40, height: 40),
                      title: const Text('Active Policy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      subtitle: const Text('Status: Carbon Guarding', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: _policyStatus == 'RED' ? Colors.red : (_policyStatus == 'YELLOW' ? Colors.amber : Colors.green), borderRadius: BorderRadius.circular(12)),
                        child: Text(_policyStatus, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, Color color = Colors.white}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 4))]),
      child: child,
    );
  }
}