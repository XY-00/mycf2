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
  
  double _temperature = 26.5;
  double _humidity = 55.0;

  String _userFullName = 'LEE XIN YI';
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
                        'LEE XIN YI';
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
        )
        .subscribe();
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
    const Color primaryDarkGreen = Color(0xFF2C4A3E); 
    const Color softIvoryWhite = Color(0xFFF9FBFA); 

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: primaryDarkGreen, 
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 14.0, bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(Icons.person, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hi, $_userFullName!',
                            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Welcome back to monitoring.',
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 👑 修改点 1：这里的 horizontal Padding 缩窄到 14.0，完美拉宽卡片，不再往里缩进
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildDHT11MiniCard('Temperature', '${_temperature.toStringAsFixed(1)} °C', Icons.thermostat, Colors.orange)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDHT11MiniCard('Humidity', '${_humidity.toStringAsFixed(0)} %', Icons.water_drop_outlined, Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildOriginalCard(
                    color: softIvoryWhite, 
                    child: Row(
                      children: [
                        Image.asset('assets/my_ic_carbonfootprint.png', width: 36, height: 36, color: primaryDarkGreen, errorBuilder: (c, e, s) => const Icon(Icons.eco_outlined, size: 36, color: primaryDarkGreen)),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Carbon Footprint Saved', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 4),
                            Text('$_carbonSaved mg CO₂ e', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        )
                      ],
                    ),
                  ),

                  _buildOriginalCard(
                    color: const Color(0xFFEAF2E8), 
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 110, width: 110,
                              child: CircularProgressIndicator(value: _moisture / 100, strokeWidth: 10, backgroundColor: Colors.white.withOpacity(0.5), color: const Color(0xFF5CB85C)),
                            ),
                            Text('$_moisture', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text('Plant Hydration (%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),

                  _buildOriginalCard(
                    color: const Color(0xFFFDECEB), 
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 100, width: 100,
                              child: CircularProgressIndicator(value: _stabilityScore / 100, strokeWidth: 8, backgroundColor: Colors.white.withOpacity(0.5), color: const Color(0xFFEC5B5B)),
                            ),
                            Text('$_stabilityScore / 100', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Carbon Stability Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),

                  _buildOriginalCard(
                    color: softIvoryWhite, 
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.shield_outlined, size: 36, color: primaryDarkGreen),
                      title: const Text('Active Policy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      subtitle: const Text('Status: Carbon Guarding', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: _policyStatus == 'RED' ? Colors.redAccent : (_policyStatus == 'YELLOW' ? Colors.orange : const Color(0xFF66BB6A)), borderRadius: BorderRadius.circular(12)),
                        child: Text(_policyStatus, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDHT11MiniCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF9FBFA), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6, offset: const Offset(0, 3))]),
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

  Widget _buildOriginalCard({required Widget child, required Color color}) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6, offset: const Offset(0, 3))]),
      child: child,
    );
  }
}