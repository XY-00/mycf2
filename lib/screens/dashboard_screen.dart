import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 第一张照片中的原始基础业务数据
  double _carbonSaved = 146.0;
  double _moisture = 62.9;
  int _stabilityScore = 90;
  String _policyStatus = 'GREEN';
  
  // 👑 新增：接收硬件 DHT11 数据的环境参数变量
  double _temperature = 26.5;
  double _humidity = 55.0;

  // 👑 新增：捕获用户真正 Full Name 的变量
  String _userFullName = 'User';

  RealtimeChannel? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _fetchUserFullName();
    _initSupabaseRealtime();
  }

  // 👑 核心修复：真正去拿用户填写的 Full Name 展示在顶端
  void _fetchUserFullName() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        // 读取 signUp 存入的 name，如果没有则降级拿 email 前缀
        _userFullName = user.userMetadata?['name'] ?? 
                        user.email?.split('@').first ?? 
                        'User';
      });
    }
  }

  // 实时流管道：同步监听传感器与硬件 DHT11 变更
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
                
                // 同步硬件 DHT11 数据
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
    // 👑 还原第一张照片中极度柔和舒服的自然浅绿配色方案
    const Color primaryGreen = Color(0xFF497E66); // 经典舒服绿色
    const Color originalBgColor = Color(0xFFF4F7F2); // 干净淡绿浅白背景色

    return Scaffold(
      backgroundColor: originalBgColor,
      // 👑 回归第一张照片原本的顶端 Appbar 结构，同时将标题完美换成“Hi, [Full Name]!”
      appBar: AppBar(
        title: Text(
          'Hi, $_userFullName!', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)
        ), 
        backgroundColor: primaryGreen, 
        centerTitle: true, 
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 👑 需求 3：原有的 'Monitoring the Carbon Footprint...' 次标题文字已被彻底删除

            // 👑 需求 4：在 Total Carbon Footprint Saved 卡片上方，增加当天 DHT11 温湿度动态卡片
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
            const SizedBox(height: 12),

            // 卡片一：Total Carbon Footprint Saved（完全还原第一张照片样式）
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

            // 卡片二：Plant Hydration (%) 圆环卡片（完全还原第一张照片样式）
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
                          color: primaryGreen, // 还原第一张照片的经典绿色弧线
                        ),
                      ),
                      Text(
                        '$_moisture %', 
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

            // 卡片三：Carbon Stability Score 红圆环卡片（完全还原第一张照片样式）
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
                          color: const Color(0xFFE57373), // 还原第一张照片的红色指示圆环
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

            // 卡片四：Active Policy 状态栏（完全还原第一张照片样式）
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
                        : (_policyStatus == 'YELLOW' ? Colors.orange : const Color(0xFF66BB6A)), // 还原最初的舒服嫩绿色胶囊
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
    );
  }

  // DHT11 温湿度并排微调小卡片组件
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

  // 原汁原味第一张照片的通用圆角卡片容器
  Widget _buildOriginalCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 3))
        ],
      ),
      child: child,
    );
  }
}