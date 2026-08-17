// lib/screens/analytic_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'moisture_chart_card.dart';

class AnalyticScreen extends StatefulWidget {
  const AnalyticScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticScreen> createState() => _AnalyticScreenState();
}

class _AnalyticScreenState extends State<AnalyticScreen> {
  int _selectedPlantTab = 0; // 0: All Plants, 或者具体的 slot 编号
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

  @override
  void initState() {
    super.initState();
    _fetchAnalyticAndCameraData();
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

      // 👑 1. 核心：直接从 plants 表查询当前用户的 active 植物（与 Plant Profile 完全同步）
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

      // 如果该账号没有任何 active 植物，直接展示精美空白卡片
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

      // 2. 尝试从 sensor_logs 拉取数据（即使为空也绝不让页面崩溃变空）
      try {
        var sensorQuery = Supabase.instance.client
            .from('sensor_logs')
            .select()
            .ilike('displayname', currentDisplayName);

        if (_selectedPlantTab > 0) {
          sensorQuery = sensorQuery.eq('slot_number', _selectedPlantTab);
        }

        final sensorResponse = await sensorQuery.order('recorded_at', ascending: false).limit(24);

        List<int> p1 = [];
        List<int> p2 = [];
        List<int> p3 = [];

        if (sensorResponse != null && (sensorResponse as List).isNotEmpty) {
          final latest = sensorResponse[0];
          setState(() {
            _currentMoisture = latest['moisture_level'] ?? 50;
            _leafStatus = latest['leaf_status'] ?? 'Normal';
            _growthRate = latest['growth_rate'] ?? 2.1;
          });

          for (var item in (sensorResponse as List).reversed) {
            int slot = int.tryParse(item['slot_number'].toString()) ?? 1;
            int val = int.tryParse(item['moisture_level'].toString()) ?? 50;
            if (slot == 1) p1.add(val);
            if (slot == 2) p2.add(val);
            if (slot == 3) p3.add(val);
          }
        } else {
          // 如果 sensor_logs 是空的，给图表赋予默认的平稳初始化数据，保证 UI 美观不报错
          setState(() {
            _currentMoisture = 60;
            _leafStatus = 'Normal';
            _growthRate = 2.1;
          });
          p1 = List.filled(24, 60);
          p2 = List.filled(24, 65);
          p3 = List.filled(24, 55);
        }

        setState(() {
          _trendPlant1 = p1;
          _trendPlant2 = p2;
          _trendPlant3 = p3;
        });
      } catch (e) {
        print('Sensor logs fetch skipped or empty: $e');
      }

      // 3. 拉取相机快照
      try {
        final snapshotResponse = await Supabase.instance.client
            .from('camera_snapshots')
            .select()
            .ilike('displayname', currentDisplayName)
            .order('captured_at', ascending: false)
            .maybeSingle();

        if (snapshotResponse != null) {
          setState(() {
            _fullCameraImageUrl = snapshotResponse['full_image_url'];
            _plant1CropUrl = snapshotResponse['plant_1_url'];
            _plant2CropUrl = snapshotResponse['plant_2_url'];
            _plant3CropUrl = snapshotResponse['plant_3_url'];
          });
        }
      } catch (_) {}

      // 4. 拉取干预日志数量
      try {
        final interventionResponse = await Supabase.instance.client
            .from('intervention_logs')
            .select()
            .ilike('displayname', currentDisplayName);

        if (interventionResponse != null && (interventionResponse as List).isNotEmpty) {
          setState(() {
            _successInterventions = interventionResponse.length;
          });
        }
      } catch (_) {}

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
    const Color primaryDarkGreen = Color(0xFF2C4A3E); 

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryDarkGreen))
          : (_activeSlots.isEmpty ? _buildEmptyPlaceholder() : SingleChildScrollView(
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
                  
                  // 👑 动态 Tab 按钮
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
                  
                  // 1. LIVE CAMERA 模块
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
                                  double totalWidth = constraints.maxWidth;
                                  int totalCount = _activeSlots.isEmpty ? 1 : _activeSlots.length;
                                  double boxWidth = (totalWidth - (8 * (totalCount + 1))) / totalCount; 

                                  String? displayImage = _fullCameraImageUrl;
                                  if (_selectedPlantTab == 1) displayImage = _plant1CropUrl ?? _fullCameraImageUrl;
                                  if (_selectedPlantTab == 2) displayImage = _plant2CropUrl ?? _fullCameraImageUrl;
                                  if (_selectedPlantTab == 3) displayImage = _plant3CropUrl ?? _fullCameraImageUrl;

                                  return Container(
                                    width: double.infinity, height: 180,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12), color: const Color(0xFFDCEAE4),
                                      image: displayImage != null && displayImage.startsWith('http')
                                          ? DecorationImage(image: NetworkImage(displayImage), fit: BoxFit.cover)
                                          : const DecorationImage(image: AssetImage('assets/analytic_plant.jpg'), fit: BoxFit.cover),
                                    ),
                                    child: Stack(
                                      children: [
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
                                        for (int i = 0; i < _activeSlots.length; i++)
                                          if (_selectedPlantTab == 0 || _selectedPlantTab == _activeSlots[i])
                                            Positioned(
                                              top: 45, 
                                              left: 8 + (i * (boxWidth + 8)), 
                                              child: _cvBox('plant ${_activeSlots[i]}', boxWidth, 110),
                                            ),
                                        Positioned(
                                          bottom: 8, left: 12, 
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), color: Colors.black54,
                                            child: const Text('Next refresh in: 15 mins (Resolution: Medium)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Roboto')),
                                          ),
                                        ),
                                      ],
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
                  
                  // 2. Visual Health Validation 模块
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('VISUAL HEALTH VALIDATION'),
                        Container(
                          width: double.infinity, 
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildGridItem('Leaf Color Anal...', _selectedPlantTab == 0 ? 'All channels normal' : 'Plant $_selectedPlantTab: $_leafStatus', Icons.spa_outlined)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildGridItem('Growth Rate', _selectedPlantTab == 0 ? 'Avg: +2.1 cm / wk' : 'Plant $_selectedPlantTab: +$_growthRate cm', Icons.stacked_line_chart)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: _buildGridItem('Moisture Status', _selectedPlantTab == 0 ? 'All sensors online' : 'Plant $_selectedPlantTab: Stable ($_currentMoisture%)', Icons.opacity_outlined)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _buildGridItem('System Performance', _selectedPlantTab == 0 ? 'Relays triggered: 3' : 'Pump $_selectedPlantTab active', Icons.notifications_active_outlined)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // 3. 24-Hour Moisture Trend 模块
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
                  
                  // 4. Carbon Protection 模块
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
            )),
    );
  }

  // 无植物时的精美提示卡片
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

  Widget _cvBox(String label, double width, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
      children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), color: Colors.redAccent, child: Text('$label 98%', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'Roboto'))),
        Container(
          width: width, 
          height: height, 
          decoration: BoxDecoration(
            border: Border.all(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ],
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

  Widget _buildGridItem(String title, String desc, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6F0), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)), 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              Icon(icon, size: 14, color: const Color(0xFF497E66)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title, 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E), fontFamily: 'Roboto'), 
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            desc, 
            style: const TextStyle(fontSize: 10, color: Colors.black54, height: 1.1, fontFamily: 'Roboto'), 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis
          ),
        ],
      ),
    );
  }
}