// lib/screens/analytic_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'moisture_chart_card.dart';

class AnalyticScreen extends StatefulWidget {
  const AnalyticScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticScreen> createState() => _AnalyticScreenState();
}

class _AnalyticScreenState extends State<AnalyticScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; 

  int _selectedPlantTab = 0; 
  bool _isLoading = true;

  List<int> _activeSlots = []; 

  int _currentMoisture = 0;
  String _leafStatus = 'Normal';
  num _growthRate = 2.1;
  int _successInterventions = 3;

  List<int> _trendPlant1 = [];
  List<int> _trendPlant2 = [];
  List<int> _trendPlant3 = [];

  String? _fullCameraImageUrl;
  String? _plant1CropUrl;
  String? _plant2CropUrl;
  String? _plant3CropUrl;

  Timer? _countdownTimer;
  String _countdownText = '15 mins';

  @override
  void initState() {
    super.initState();
    _fetchAnalyticAndCameraData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(String capturedAtStr, int intervalMinutes) {
    _countdownTimer?.cancel();
    DateTime? capturedTime;
    try {
      capturedTime = DateTime.parse(capturedAtStr);
    } catch (_) {
      capturedTime = DateTime.now();
    }

    final targetTime = capturedTime.add(Duration(minutes: intervalMinutes));

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final difference = targetTime.difference(now);

      if (difference.isNegative) {
        if (mounted) setState(() => _countdownText = 'Refreshing soon...');
      } else {
        int mins = difference.inMinutes;
        int secs = difference.inSeconds % 60;
        if (mounted) setState(() => _countdownText = '${mins}m ${secs}s');
      }
    });
  }

  String _getCurrentDisplayName() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'LEE XIN YI';
    final metadataName = user.userMetadata?['name'];
    if (metadataName != null && metadataName.toString().isNotEmpty) {
      return metadataName.toString();
    }
    if (user.email != null && user.email!.contains('@')) {
      return user.email!.split('@')[0].toUpperCase();
    }
    return 'LEE XIN YI';
  }

  List<int> _calculateDailyHourlyAverages(List<dynamic> rawRows, int slotNum) {
    Map<int, List<double>> hourlyBuckets = {};
    DateTime now = DateTime.now();
    int currentHour = now.hour;

    for (var row in rawRows) {
      int rowSlot = int.tryParse(row['slot_number'].toString()) ?? 1;
      if (rowSlot != slotNum) continue;

      String timeStr = row['recorded_at'] ?? '';
      try {
        DateTime dt = DateTime.parse(timeStr).toLocal();
        if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
          int hour = dt.hour;
          if (hour <= currentHour) {
            double moisture = double.tryParse(row['moisture_level'].toString()) ?? 0.0;
            hourlyBuckets.putIfAbsent(hour, () => [0.0, 0.0]);
            hourlyBuckets[hour]![0] += moisture;
            hourlyBuckets[hour]![1] += 1;
          }
        }
      } catch (_) {}
    }

    List<int> result = [];
    int lastValidValue = 0;

    for (int i = 0; i <= currentHour; i++) {
      if (hourlyBuckets.containsKey(i) && hourlyBuckets[i]![1] > 0) {
        double total = hourlyBuckets[i]![0];
        double count = hourlyBuckets[i]![1];
        lastValidValue = (total / count).round();
        result.add(lastValidValue);
      } else {
        result.add(lastValidValue);
      }
    }

    return result;
  }

  Future<void> _fetchAnalyticAndCameraData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _activeSlots = [];
          _isLoading = false;
        });
        return;
      }

      String currentDisplayName = _getCurrentDisplayName();

      final plantsResponse = await Supabase.instance.client
          .from('plants')
          .select('slot_number')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .order('slot_number', ascending: true);

      List<int> detectedSlots = [];
      if (plantsResponse != null && (plantsResponse as List).isNotEmpty) {
        for (var item in plantsResponse) {
          int slot = item['slot_number'] ?? 1;
          if (!detectedSlots.contains(slot)) {
            detectedSlots.add(slot);
          }
        }
      }

      if (detectedSlots.isEmpty) {
        setState(() {
          _activeSlots = [];
          _isLoading = false;
        });
        return;
      }

      if (_selectedPlantTab != 0 && !detectedSlots.contains(_selectedPlantTab)) {
        _selectedPlantTab = 0;
      }

      try {
        final sensorResponse = await Supabase.instance.client
            .from('sensor_logs')
            .select()
            .ilike('displayname', currentDisplayName)
            .order('recorded_at', ascending: false)
            .limit(1000);

        if (sensorResponse != null && (sensorResponse as List).isNotEmpty) {
          final latest = sensorResponse[0];
          setState(() {
            _currentMoisture = latest['moisture_level'] ?? 50;
            _leafStatus = latest['leaf_status'] ?? 'Normal';
            _growthRate = latest['growth_rate'] ?? 2.1;
          });
        }

        List<int> p1 = _calculateDailyHourlyAverages(sensorResponse ?? [], 1);
        List<int> p2 = _calculateDailyHourlyAverages(sensorResponse ?? [], 2);
        List<int> p3 = _calculateDailyHourlyAverages(sensorResponse ?? [], 3);

        setState(() {
          _trendPlant1 = detectedSlots.contains(1) ? p1 : [];
          _trendPlant2 = detectedSlots.contains(2) ? p2 : [];
          _trendPlant3 = detectedSlots.contains(3) ? p3 : [];
        });
      } catch (e) {
        print('Sensor logs fetch skipped: $e');
      }

      try {
        // 👑 改进：先尝试按 user_id 查
        var snapshotsList = await Supabase.instance.client
            .from('camera_snapshots')
            .select()
            .eq('user_id', user.id)
            .order('captured_at', ascending: false)
            .limit(10);

        // 如果按 user_id 没查到，则放宽限制获取全局最新快照（兼容树莓派上传时未绑定 user_id 的情况）
        if (snapshotsList == null || (snapshotsList as List).isEmpty) {
          snapshotsList = await Supabase.instance.client
              .from('camera_snapshots')
              .select()
              .order('captured_at', ascending: false)
              .limit(10);
        }

        String? bestFull;
        String? bestP1;
        String? bestP2;
        String? bestP3;
        String? latestCapturedAt;

        if (snapshotsList != null && (snapshotsList as List).isNotEmpty) {
          for (var row in snapshotsList) {
            bestFull ??= row['full_image_url']?.toString();
            bestP1 ??= row['plant_1_url']?.toString();
            bestP2 ??= row['plant_2_url']?.toString();
            bestP3 ??= row['plant_3_url']?.toString();
            latestCapturedAt ??= row['captured_at']?.toString();

            if (bestFull != null && bestP1 != null && bestP2 != null && bestP3 != null) {
              break;
            }
          }

          setState(() {
            _fullCameraImageUrl = bestFull;
            _plant1CropUrl = bestP1;
            _plant2CropUrl = bestP2;
            _plant3CropUrl = bestP3;
          });
        }

        int freqMins = 30;
        try {
          final sysRes = await Supabase.instance.client
              .from('system_control')
              .select('capture_frequency_minutes')
              .eq('id', 1)
              .maybeSingle();
          if (sysRes != null && sysRes['capture_frequency_minutes'] != null) {
            freqMins = sysRes['capture_frequency_minutes'];
          }
        } catch (e) {
          debugPrint('Error fetching frequency from system_control: $e');
        }

        if (latestCapturedAt != null) {
          _startCountdown(latestCapturedAt, freqMins);
        }

      } catch (e) {
        print('Error fetching smart camera snapshots: $e');
      }

      setState(() {
        _activeSlots = detectedSlots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching analytic & camera data: $e');
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedPlantTab = index;
      _isLoading = true;
    });
    _fetchAnalyticAndCameraData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const Color primaryDarkGreen = Color(0xFF2C4A3E); 

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryDarkGreen))
          : (_activeSlots.isEmpty ? _buildEmptyPlaceholder() : RefreshIndicator(
              color: primaryDarkGreen,
              onRefresh: _fetchAnalyticAndCameraData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
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
                            mainAxisAlignment: MainAxisAlignment.center, 
                            children: const [
                              Text('Analysis Report', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3, fontFamily: 'Roboto')),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          _buildTabButton('All Plants', 0),
                          ..._activeSlots.map((slot) => _buildTabButton('Plant $slot', slot)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('LIVE CAMERA MONITOR'),
                          Container(
                            width: double.infinity, padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
                            ),
                            child: Column(
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    String? displayImage;
                                    if (_selectedPlantTab == 1) {
                                      displayImage = (_plant1CropUrl != null && _plant1CropUrl!.isNotEmpty) 
                                          ? _plant1CropUrl 
                                          : (_fullCameraImageUrl ?? _plant2CropUrl ?? _plant3CropUrl);
                                    } else if (_selectedPlantTab == 2) {
                                      displayImage = (_plant2CropUrl != null && _plant2CropUrl!.isNotEmpty) 
                                          ? _plant2CropUrl 
                                          : (_fullCameraImageUrl ?? _plant1CropUrl ?? _plant3CropUrl);
                                    } else if (_selectedPlantTab == 3) {
                                      displayImage = (_plant3CropUrl != null && _plant3CropUrl!.isNotEmpty) 
                                          ? _plant3CropUrl 
                                          : (_fullCameraImageUrl ?? _plant1CropUrl ?? _plant2CropUrl);
                                    } else {
                                      displayImage = (_fullCameraImageUrl != null && _fullCameraImageUrl!.isNotEmpty) 
                                          ? _fullCameraImageUrl 
                                          : (_plant1CropUrl ?? _plant2CropUrl ?? _plant3CropUrl);
                                    }

                                    return Container(
                                      width: double.infinity, height: 180,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12), 
                                        color: const Color(0xFFDCEAE4),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            displayImage != null && displayImage.isNotEmpty && displayImage.startsWith('http')
                                                ? Image.network(
                                                    displayImage,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Center(
                                                        child: Text('Image Load Failed', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                                      );
                                                    },
                                                  )
                                                : const Center(
                                                    child: Text('No Camera Snapshot Available', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                                  ),
                                            Positioned(
                                              top: 12, left: 12, 
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)), 
                                                child: Row(
                                                  children: const [
                                                    Icon(Icons.circle, color: Colors.white, size: 8),
                                                    SizedBox(width: 4),
                                                    Text('LIVE CAMERA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Roboto')),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 8, left: 12, 
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                                                color: Colors.black54,
                                                child: Text('Next refresh in: $_countdownText', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Roboto')),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('24-HOUR MOISTURE TREND (${_selectedPlantTab == 0 ? "OVERVIEW" : "PLANT $_selectedPlantTab"})'),
                          MoistureChartCard(
                            selectedTab: _selectedPlantTab,
                            activeSlots: _activeSlots,
                            trendPlant1: _trendPlant1,
                            trendPlant2: _trendPlant2,
                            trendPlant3: _trendPlant3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('CARBON PROTECTION'),
                          Container(
                            width: double.infinity, padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white, 
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F6F0), 
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 3)],
                                    ),
                                    child: Column(
                                      children: [
                                        Text('$_successInterventions', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryDarkGreen, fontFamily: 'Roboto')),
                                        const SizedBox(height: 2),
                                        const Text('Successful Interventions', style: TextStyle(fontSize: 10.5, color: Colors.black54, fontWeight: FontWeight.w500, fontFamily: 'Roboto')),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F6F0), 
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 3)],
                                    ),
                                    child: Column(
                                      children: [
                                        const Text('100 %', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF3B7A69), fontFamily: 'Roboto')), 
                                        const SizedBox(height: 2),
                                        const Text('Protection Rate', style: TextStyle(fontSize: 10.5, color: Colors.black54, fontWeight: FontWeight.w500, fontFamily: 'Roboto')),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            )),
    );
  }

  Widget _buildEmptyPlaceholder() {
    const Color primaryDarkGreen = Color(0xFF2C4A3E);
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: primaryDarkGreen, 
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 14.0, bottom: 16.0), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: const [
                  Text('Analysis Report', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'No plants found',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Please add a plant in Plant Profile to view the analysis report.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C4A3E),
          fontFamily: 'Roboto',
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    bool isSelected = _selectedPlantTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2), padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: isSelected ? const Color(0xFF2C4A3E) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? const Color(0xFF2C4A3E) : Colors.black12)),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87, fontFamily: 'Roboto')),
        ),
      ),
    );
  }
}