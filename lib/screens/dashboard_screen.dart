import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 👑 移除了旧 firebase 导入，修改为 supabase 导入

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

  // 👑 声明一个用来取消 Supabase 实时流订阅的变量
  RealtimeChannel? _statusSubscription;

  @override
  void initState() {
    super.initState();
    // 👑 核心修改：将旧的 Firebase 监听改成 Supabase 最精简的实时数据流流监听
    // 树莓派写入到 supabase 的 live_status 表后，这里会立刻收到推送并刷新页面
    _statusSubscription = Supabase.instance.client
        .channel('public:live_status')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'live_status',
          callback: (payload) {
            final data = payload.newRecord;
            if (data.isNotEmpty) {
              setState(() {
                _moisture = (data['soil_moisture'] ?? 62.9).toDouble();
                _carbonSaved = (data['carbon_saved'] ?? 146.0).toDouble();
                _stabilityScore = (data['stability_score'] ?? 90).toInt();
                _policyStatus = data['traffic_light_state'] ?? 'GREEN';
              });
            }
          },
        );
    
    _statusSubscription?.subscribe();
  }

  @override
  void dispose() {
    // 👑 退出时安全注销实时流通道，保持项目绝对干净高效
    if (_statusSubscription != null) {
      Supabase.instance.client.removeChannel(_statusSubscription!);
    }
    super.dispose();
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