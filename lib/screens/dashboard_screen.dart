// lib/dashboard_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'setting_screen.dart'; 
import 'hardware_status_manager.dart'; 

import 'calculator_carbon.dart';
import 'calculator_hydration.dart';
import 'calculator_stability.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 👑 保持页面滚动位置记忆

  double _carbonSaved = 0.0;
  double _moisture = 62.9;
  int _stabilityScore = 90;
  double? _temperature; 
  double? _humidity;    
  String? _lastRecordedTimeString; 
  bool _isLoadingDHT = true; 
  RealtimeChannel? _statusSubscription;
  RealtimeChannel? _systemControlSubscription; 
  
  bool _isWaterLevelNormal = true;
  double _waterPercentage = 100.0;
  bool _hasTriggeredWaterAlert = false; 
  
  Timer? _offlineCheckTimer;
  DateTime? _lastDataUpdateTime;

  @override
  void initState() {
    super.initState();
    HardwareStatusManager.isDhtConnected = false; 
    
    _initData();
    _fetchTotalCarbonFromDatabase();
    _fetchLatestDHTData(); 
    _fetchWaterTankStatus(); 
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
      
      // 👑 12秒缓冲区：平衡灵敏度与防反复横跳
      bool isConnected = (diff >= 0 && diff < 12);
      
      String updatedRelativeTime = _getRelativeTime(_lastDataUpdateTime!);

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

  Future<void> _fetchWaterTankStatus() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      final response = await supabase
          .from('system_control')
          .select('is_water_normal, water_percentage, current_user_id')
          .eq('id', 1)
          .maybeSingle();

      if (response != null && mounted) {
        String? recordUserId = response['current_user_id']?.toString();
        // 👑 严格按当前登录用户隔离：只有当这条水箱状态明确属于当前登录用户时，才允许触发警报
        bool isForThisUser = (currentUser != null && recordUserId == currentUser.id);

        var rawNormal = response['is_water_normal'];
        bool isNormal = true;
        if (rawNormal is bool) {
          isNormal = rawNormal;
        } else if (rawNormal is String) {
          isNormal = rawNormal.toLowerCase() == 'true';
        } else if (rawNormal is num) {
          isNormal = rawNormal != 0;
        }

        double pct = (response['water_percentage'] ?? (isNormal ? 100.0 : 0.0)).toDouble();
        
        setState(() {
          _isWaterLevelNormal = isNormal;
          _waterPercentage = pct;
        });

        // 👑 只有当水位确实是 Empty 且属于当前登录用户时才报警；若恢复 Normal 则重置
        if (!isNormal && isForThisUser) {
          if (!_hasTriggeredWaterAlert) {
            _hasTriggeredWaterAlert = true;
            HardwareStatusManager.triggerTankEmptyAlert();
          }
        } else if (isNormal) {
          _hasTriggeredWaterAlert = false; 
        }
      }
    } catch (e) {
      debugPrint('Fetch water tank status error: $e');
    }
  }

  Future<void> _fetchTotalCarbonFromDatabase() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('eco_impact_history').select('saved_amount');

      if (response != null && (response as List).isNotEmpty) {
        double total = CarbonCalculator.calculateTotal(response);
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
          
          // 👑 初始化判断采用 12 秒缓冲区
          bool isOnline = (diffSeconds >= 0 && diffSeconds < 12);

          double rawHum = double.tryParse(latest['humidity']?.toString() ?? '62.9') ?? 62.9;
          double calculatedHydration = HydrationCalculator.calculatePercentage(rawHum);
          int calculatedScore = StabilityCalculator.calculateScore(calculatedHydration);

          if (mounted) {
            setState(() {
              _temperature = double.tryParse(latest['temperature']?.toString() ?? '');
              _humidity = rawHum;
              _moisture = calculatedHydration; 
              _stabilityScore = calculatedScore; 
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
              double rawHum = double.tryParse(data['humidity']?.toString() ?? '62.9') ?? 62.9;
              double calculatedHydration = HydrationCalculator.calculatePercentage(rawHum);
              int calculatedScore = StabilityCalculator.calculateScore(calculatedHydration);

              if (mounted) {
                setState(() {
                  _temperature = double.tryParse(data['temperature']?.toString() ?? '');
                  _humidity = rawHum;
                  _moisture = calculatedHydration;
                  _stabilityScore = calculatedScore;
                  _lastRecordedTimeString = relativeTime;
                  HardwareStatusManager.isDhtConnected = true;
                  _isLoadingDHT = false;
                });
              }
            }
          },
        )
        .subscribe();

    // 👑 实时监听 system_control 水箱状态变化，完美支持 Full <-> Empty 双向切换与用户严格隔离
    _systemControlSubscription = Supabase.instance.client
        .channel('public:system_control_water_channel_v7')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'system_control',
          callback: (payload) {
            final data = payload.newRecord;
            if (data.isNotEmpty && mounted) {
              final currentUser = Supabase.instance.client.auth.currentUser;
              String? recordUserId = data['current_user_id']?.toString();
              bool isForThisUser = (currentUser != null && recordUserId == currentUser.id);

              var rawNormal = data['is_water_normal'];
              bool isNormal = true;
              if (rawNormal is bool) {
                isNormal = rawNormal;
              } else if (rawNormal is String) {
                isNormal = rawNormal.toLowerCase() == 'true';
              } else if (rawNormal is num) {
                isNormal = rawNormal != 0;
              }

              double pct = (data['water_percentage'] ?? (isNormal ? 100.0 : 0.0)).toDouble();

              setState(() {
                _isWaterLevelNormal = isNormal;
                _waterPercentage = pct;
              });

              // 👑 双向触发控制：只有当前登录用户匹配且水箱空了才报警；一旦变成 Normal/Full，立刻重置报警锁并双向刷新为满水状态
              if (!isNormal && isForThisUser) {
                if (!_hasTriggeredWaterAlert) {
                  _hasTriggeredWaterAlert = true;
                  HardwareStatusManager.triggerTankEmptyAlert();
                }
              } else if (isNormal) {
                _hasTriggeredWaterAlert = false;
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
    if (_systemControlSubscription != null) {
      Supabase.instance.client.removeChannel(_systemControlSubscription!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 👑 保持页面滚动位置记忆
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
                            Text(
                              'Water Tank Storage (${_waterPercentage.toStringAsFixed(0)}%)', 
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)
                            ),
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
                            value: _waterPercentage / 100.0, 
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