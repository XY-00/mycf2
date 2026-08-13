import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'setting_screen.dart'; 
import 'hardware_status_manager.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _carbonSaved = 0.0;
  double _moisture = 62.9;
  int _stabilityScore = 90;
  double? _temperature; 
  double? _humidity;    
  String? _lastRecordedTimeString; 
  bool _isLoadingDHT = true; 
  RealtimeChannel? _statusSubscription;
  bool _isWaterLevelNormal = true;
  
  Timer? _offlineCheckTimer;
  DateTime? _lastDataUpdateTime;

  @override
  void initState() {
    super.initState();
    HardwareStatusManager.isDhtConnected = false; 
    
    _initData();
    _fetchTotalCarbonFromDatabase();
    _fetchLatestDHTData(); 
    _initSupabaseRealtime();
    
    _offlineCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkConnectivity();
    });
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final absSeconds = difference.inSeconds.abs();
    final absMinutes = difference.inMinutes.abs();
    final absHours = difference.inHours.abs();
    final absDays = difference.inDays.abs();

    if (absSeconds < 60) {
      return 'Just now';
    } else if (absMinutes < 60) {
      return '$absMinutes minute${absMinutes == 1 ? '' : 's'} ago';
    } else if (absHours < 24) {
      return '$absHours hour${absHours == 1 ? '' : 's'} ago';
    } else if (absDays < 30) {
      return '$absDays day${absDays == 1 ? '' : 's'} ago';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  void _checkConnectivity() {
    if (_lastDataUpdateTime != null) {
      final now = DateTime.now();
      final diff = now.difference(_lastDataUpdateTime!).inSeconds;
      bool isConnected = (diff >= 0 && diff < 7);
      
      String updatedRelativeTime = _getRelativeTime(_lastDataUpdateTime!);

      // 实时检测连接状态或时间文案变化，立刻刷新
      if (HardwareStatusManager.isDhtConnected != isConnected || _lastRecordedTimeString != updatedRelativeTime) {
        if (mounted) {
          setState(() {
            HardwareStatusManager.isDhtConnected = isConnected;
            _lastRecordedTimeString = updatedRelativeTime; 
          });
        }
      }
    }
  }

  Future<void> _initData() async {
    await UserProfileCache.load();
    if (mounted) setState(() {});
  }

  Future<void> _fetchTotalCarbonFromDatabase() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('eco_impact_history').select('saved_amount');

      if (response != null && (response as List).isNotEmpty) {
        double total = 0.0;
        for (var item in response) {
          total += double.tryParse(item['saved_amount'].toString()) ?? 0.0;
        }
        if (mounted) setState(() => _carbonSaved = total);
      }
    } catch (e) {
      debugPrint('Database carbon fetch error: $e');
    }
  }

  Future<void> _fetchLatestDHTData() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('dht11_logs')
          .select('temperature, humidity, recorded_at')
          .order('id', ascending: false)
          .limit(1);

      if (response != null && (response as List).isNotEmpty) {
        final latest = response.first;
        final timeStr = latest['recorded_at']?.toString();
        
        if (timeStr != null) {
          DateTime lastTime = DateTime.parse(timeStr.replaceAll('Z', '').replaceAll(RegExp(r'[+-]\d{2}:\d{2}$'), ''));
          _lastDataUpdateTime = lastTime; 
          
          String relativeTime = _getRelativeTime(lastTime);
          int diffSeconds = DateTime.now().difference(lastTime).inSeconds;
          bool isOnline = (diffSeconds >= 0 && diffSeconds < 7);

          if (mounted) {
            setState(() {
              _temperature = double.tryParse(latest['temperature']?.toString() ?? '');
              _humidity = double.tryParse(latest['humidity']?.toString() ?? '');
              _lastRecordedTimeString = relativeTime;
              HardwareStatusManager.isDhtConnected = isOnline;
              _isLoadingDHT = false; 
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            HardwareStatusManager.isDhtConnected = false;
            _isLoadingDHT = false; 
          });
        }
      }
    } catch (e) {
      debugPrint('Fetch latest DHT error: $e');
      if (mounted) {
        setState(() {
          HardwareStatusManager.isDhtConnected = false;
          _isLoadingDHT = false; 
        });
      }
    }
  }

  void _initSupabaseRealtime() {
    _statusSubscription = Supabase.instance.client
        .channel('public:dht11_logs_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'dht11_logs',
          callback: (payload) {
            final data = payload.newRecord;
            if (data.isNotEmpty) {
              final timeStr = data['recorded_at']?.toString();
              if (timeStr != null) {
                _lastDataUpdateTime = DateTime.parse(timeStr.replaceAll('Z', '').replaceAll(RegExp(r'[+-]\d{2}:\d{2}$'), ''));
              } else {
                _lastDataUpdateTime = DateTime.now();
              }
              
              String relativeTime = _getRelativeTime(_lastDataUpdateTime!);

              if (mounted) {
                setState(() {
                  _temperature = double.tryParse(data['temperature']?.toString() ?? '');
                  _humidity = double.tryParse(data['humidity']?.toString() ?? '');
                  _lastRecordedTimeString = relativeTime;
                  HardwareStatusManager.isDhtConnected = true;
                  _isLoadingDHT = false;
                });
              }
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _offlineCheckTimer?.cancel();
    if (_statusSubscription != null) {
      Supabase.instance.client.removeChannel(_statusSubscription!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF2C4A3E); 
    const Color softIvoryWhite = Color(0xFFF9FBFA);

    bool isAvatarLocal = UserProfileCache.avatarPath.isNotEmpty && (UserProfileCache.avatarPath.startsWith('/') || UserProfileCache.avatarPath.startsWith('file://'));
    bool avatarExists = isAvatarLocal && File(UserProfileCache.avatarPath).existsSync();

    bool isConnected = HardwareStatusManager.isDhtConnected;

    String tempStr = _isLoadingDHT ? 'loading' : (_temperature != null ? '${_temperature!.toStringAsFixed(1)} °C' : '-- °C');
    String humStr = _isLoadingDHT ? 'loading' : (_humidity != null ? '${_humidity!.toStringAsFixed(0)} %' : '-- %');

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
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          image: avatarExists ? DecorationImage(image: FileImage(File(UserProfileCache.avatarPath)), fit: BoxFit.cover) : null,
                        ),
                        child: !avatarExists ? const Icon(Icons.person, color: Colors.white, size: 22) : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Hi, ${UserProfileCache.profileName}!', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 1),
                            Text('Welcome back to monitoring.', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _miniCard('Temperature', tempStr, Icons.thermostat, Colors.orange, isConnected)),
                      const SizedBox(width: 12),
                      Expanded(child: _miniCard('Humidity', humStr, Icons.water_drop_outlined, Colors.blue, isConnected)),
                    ],
                  ),
                  
                  if (!isConnected && !_isLoadingDHT) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _lastRecordedTimeString != null
                                  ? 'Sensor Offline (Last recorded: $_lastRecordedTimeString)'
                                  : 'Sensor Offline (Showing last recorded data)',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),
                  _buildCard(softIvoryWhite, Row(
                    children: [
                      Image.asset('assets/my_ic_carbonfootprint.png', width: 36, height: 36, color: primaryDarkGreen),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Carbon Footprint Saved', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text('${_carbonSaved.toStringAsFixed(1)} mg CO₂ e', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      )
                    ],
                  )),
                  _buildCard(const Color(0xFFEAF2E8), Column(
                    children: [
                      const SizedBox(height: 10),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(height: 110, width: 110, child: CircularProgressIndicator(value: _moisture / 100, strokeWidth: 10, backgroundColor: Colors.white.withOpacity(0.5), color: const Color(0xFF5CB85C))),
                          Text('$_moisture', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text('Plant Hydration (%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                    ],
                  )),
                  _buildCard(const Color(0xFFFDECEB), Column(
                    children: [
                      const SizedBox(height: 10),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(height: 100, width: 100, child: CircularProgressIndicator(value: _stabilityScore / 100, strokeWidth: 8, backgroundColor: Colors.white.withOpacity(0.5), color: const Color(0xFFEC5B5B))),
                          Text('$_stabilityScore / 100', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Carbon Stability Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                    ],
                  )),
                  _buildCard(
                    _isWaterLevelNormal ? softIvoryWhite : const Color(0xFFFCE8E6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Water Tank Storage (Float Sensor)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                            Icon(
                              _isWaterLevelNormal ? Icons.check_circle : Icons.error_rounded,
                              color: _isWaterLevelNormal ? Colors.green : Colors.red,
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _isWaterLevelNormal ? 0.85 : 0.05,
                            minHeight: 12,
                            backgroundColor: Colors.black12,
                            color: _isWaterLevelNormal ? Colors.blue : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isWaterLevelNormal 
                              ? 'Status: Normal' 
                              : 'CRITICAL WARNING: TANK EMPTY - WATER PUMPS LOCKED',
                          style: TextStyle(
                            fontSize: 11, 
                            fontWeight: FontWeight.bold, 
                            color: _isWaterLevelNormal ? Colors.green : Colors.red
                          ),
                        )
                      ],
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

  Widget _miniCard(String title, String value, IconData icon, Color iconColor, bool isConnected) {
    bool isFetching = (value == 'loading');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFA), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: isConnected ? Colors.black12 : Colors.orange.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Icon(icon, color: isConnected ? iconColor : Colors.grey, size: 22),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              isFetching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2C4A3E)),
                    )
                  : Text(
                      value, 
                      style: TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.bold, 
                        color: isConnected ? Colors.black87 : Colors.black54,
                      ),
                    ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCard(Color color, Widget child) {
    return Container(
      width: double.infinity, 
      margin: const EdgeInsets.only(bottom: 14), 
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.black12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }
}