import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  
  // 硬件 DHT11 实时变量
  double _temperature = 26.5;
  double _humidity = 55.0;

  // 动态捕获用户的真实 Full Name
  String _userFullName = 'User';

  RealtimeChannel? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _fetchUserFullName();
    _initSupabaseRealtime();
  }

  void _fetchUserFullName() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _userFullName = user.userMetadata?['name'] ?? 
                        user.email?.split('@').first ?? 
                        'User';
      });
    }
  }

  void _initSupabaseRealtime() {
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
                _temperature = (data['temperature'] ?? 26.5).toDouble();
                _humidity = (data['humidity'] ?? 55.0).toDouble();
              });
            }
          },
        );
    
    _statusSubscription?.subscribe();
  }

  @override
  void dispose() {
    if (_statusSubscription != null) {
      Supabase.instance.client.removeChannel(_statusSubscription!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF497E66); // 舒服主绿调
    const Color darkGreenText = Color(0xFF2C3E35); // 优雅墨绿深字

    return Scaffold(
      backgroundColor: Colors.transparent, // 👑 设为透明，完美融入外壳统一绑定的固定背景图
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              
              // 👑 第 1 点修改：彻底删除了顶部原先的绿色AppBar框，换成完全贴合第二张照片的高级左侧问候与右侧头像布局
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $_userFullName!',
                        style: const TextStyle(
                          fontSize: 26, 
                          fontWeight: FontWeight.bold, 
                          color: darkGreenText,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Welcome back to monitoring.',
                        style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                  // 👑 右侧高颜值的舒适头像徽章
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: primaryGreen.withOpacity(0.12),
                    child: const Icon(Icons.person, color: primaryGreen),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // DHT11 实时并排卡片
              Row(
                children: [
                  Expanded(
                    child: _buildDHT11MiniCard(
                      title: 'Temperature',
                      value: '${_temperature.toStringAsFixed(1)} °C',
                      icon: Icons.thermostat,
                      iconColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDHT11MiniCard(
                      title: 'Humidity',
                      value: '${_humidity.toStringAsFixed(0)} %',
                      icon: Icons.water_drop_outlined,
                      iconColor: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 卡片一：Total Carbon Footprint Saved
              _buildOriginalCard(
                child: Row(
                  children: [
                    const Icon(Icons.eco_outlined, size: 36, color: primaryGreen),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Carbon Footprint Saved', 
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_carbonSaved mg CO₂ e', 
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)
                        ),
                      ],
                    )
                  ],
                ),
              ),

              // 卡片二：Plant Hydration (%)
              _buildOriginalCard(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 110, 
                          width: 110, 
                          child: CircularProgressIndicator(
                            value: _moisture / 100, 
                            strokeWidth: 10, 
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            color: primaryGreen,
                          ),
                        ),
                        // 👑 第 3 点修改：因为外部组件已经标注了 (%)，这里去掉多余的 % 符号，直接显示纯净的数字
                        Text(
                          '$_moisture', 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Plant Hydration (%)', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),

              // 卡片三：Carbon Stability Score
              _buildOriginalCard(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 100, 
                          width: 100, 
                          child: CircularProgressIndicator(
                            value: _stabilityScore / 100, 
                            strokeWidth: 8, 
                            backgroundColor: Colors.grey.withOpacity(0.1),
                            color: const Color(0xFFE57373),
                          ),
                        ),
                        Text(
                          '$_stabilityScore / 100', 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Carbon Stability Score', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),

              // 卡片四：Active Policy
              _buildOriginalCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.shield_outlined, size: 36, color: primaryGreen),
                  title: const Text('Active Policy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  subtitle: const Text('Status: Carbon Guarding', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _policyStatus == 'RED' 
                          ? Colors.redAccent 
                          : (_policyStatus == 'YELLOW' ? Colors.orange : const Color(0xFF66BB6A)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _policyStatus, 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDHT11MiniCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6, offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildOriginalCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6, offset: const Offset(0, 3))
        ],
      ),
      child: child,
    );
  }
}