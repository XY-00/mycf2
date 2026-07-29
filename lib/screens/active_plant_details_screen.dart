import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivePlantDetailsScreen extends StatefulWidget {
  final int slotIndex;
  final String initialName;
  final DateTime initialDate;
  final String initialAvatar;

  const ActivePlantDetailsScreen({
    Key? key, 
    required this.slotIndex, 
    required this.initialName, 
    required this.initialDate, 
    required this.initialAvatar,
  }) : super(key: key);

  @override
  State<ActivePlantDetailsScreen> createState() => _ActivePlantDetailsScreenState();
}

class _ActivePlantDetailsScreenState extends State<ActivePlantDetailsScreen> {
  late String _currentName;
  late DateTime _currentDate;
  late String _currentAvatar;

  bool _isSensorConnected = false;
  bool _isPumpConnected = false;
  bool _isCheckingHardware = true;

  final Map<String, IconData> _avatarMap = {
    'Sunflower 🌻': Icons.wb_sunny_outlined,
    'Cactus 🌵': Icons.grass_rounded, 
    'Rose 🌹': Icons.favorite_border_rounded,
    'Fern 🌿': Icons.eco_outlined,
  };

  @override
  void initState() {
    super.initState();
    _currentName = widget.initialName;
    _currentDate = widget.initialDate;
    _currentAvatar = widget.initialAvatar;
    _fetchHardwareStatus();
  }

  Future<void> _fetchHardwareStatus() async {
    try {
      int slotNumber = widget.slotIndex + 1;
      final response = await Supabase.instance.client
          .from('hardware_status')
          .select()
          .eq('slot_number', slotNumber)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _isSensorConnected = response['sensor_connected'] ?? false;
          _isPumpConnected = response['pump_connected'] ?? false;
          _isCheckingHardware = false;
        });
      } else {
        setState(() => _isCheckingHardware = false);
      }
    } catch (e) {
      setState(() => _isCheckingHardware = false);
      print('Error fetching hardware status: $e');
    }
  }

  int get _calcDays => DateTime.now().difference(_currentDate).inDays;

  void _openEditBottomSheet() {
    final nameCtrl = TextEditingController(text: _currentName);
    String tempAvatar = _currentAvatar;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setPopupState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Plant Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
              const SizedBox(height: 14),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Plant Name', border: OutlineInputBorder())),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: tempAvatar,
                decoration: const InputDecoration(labelText: 'Change Avatar', border: OutlineInputBorder()),
                items: ['Sunflower 🌻', 'Cactus 🌵', 'Rose 🌹', 'Fern 🌿'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setPopupState(() => tempAvatar = val!),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C4A3E)),
                  onPressed: () {
                    setState(() {
                      _currentName = nameCtrl.text.trim();
                      _currentAvatar = tempAvatar;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // 👑 优化后的 View all 相册弹窗：按日期分组，时间显示为黑色字体
  void _openGrowthHistoryGallery(BuildContext context) {
    // 模拟按日期分类的快照数据结构
    final Map<String, List<Map<String, dynamic>>> groupedSnapshots = {
      'Today, 29 July 2026': [
        {'time': '12:00 PM', 'moisture': 64, 'image': 'assets/analytic_plant.jpg'},
        {'time': '11:30 AM', 'moisture': 63, 'image': 'assets/analytic_plant.jpg'},
        {'time': '11:00 AM', 'moisture': 62, 'image': 'assets/analytic_plant.jpg'},
        {'time': '10:30 AM', 'moisture': 61, 'image': 'assets/analytic_plant.jpg'},
        {'time': '10:00 AM', 'moisture': 60, 'image': 'assets/analytic_plant.jpg'},
      ],
      '28 July 2026': [
        {'time': '12:00 PM', 'moisture': 58, 'image': 'assets/analytic_plant.jpg'},
        {'time': '10:00 AM', 'moisture': 55, 'image': 'assets/analytic_plant.jpg'},
      ],
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF4F7F5),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // 👑 严格改为 Growth History
                        const Text(
                          'Growth History',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: groupedSnapshots.entries.map((entry) {
                    String dateKey = entry.key;
                    List<Map<String, dynamic>> snapshots = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            dateKey,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E)),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: snapshots.length,
                          itemBuilder: (context, index) {
                            final item = snapshots[index];
                            return _growthThumbnailWithMoisture(
                              item['image'],
                              item['moisture'],
                              item['time'],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Complete Plant', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
        content: Text('Are you sure you want to complete and archive "$_currentName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5CB85C)),
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context, {'action': 'complete'}); 
            },
            child: const Text('Yes, Complete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Plant', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text('Are you sure you want to delete "$_currentName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context, {'action': 'delete'}); 
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF2C4A3E);
    const Color unifiedCardBg = Color(0xFFF0F5F1); 
    int slotNum = widget.slotIndex + 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/app_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(color: Colors.white.withOpacity(0.78)), 
            Column(
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
                      padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 10.0, bottom: 16.0), 
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context, {'action': 'update', 'name': _currentName, 'date': _currentDate, 'avatar': _currentAvatar}),
                          ),
                          Text('Plant $slotNum', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3)),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                            onPressed: _openEditBottomSheet,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                          child: Text('Slot $slotNum Hardware Status', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: unifiedCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
                          ),
                          child: _isCheckingHardware
                              ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2, color: primaryDarkGreen)))
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Soil Moisture Sensor $slotNum', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _isSensorConnected ? Colors.green.shade50 : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: _isSensorConnected ? Colors.green.shade200 : Colors.red.shade200),
                                          ),
                                          child: Text(
                                            _isSensorConnected ? 'Connected' : 'Unconnected',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isSensorConnected ? Colors.green.shade700 : Colors.red.shade700),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Water Pump $slotNum', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _isPumpConnected ? Colors.blue.shade50 : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: _isPumpConnected ? Colors.blue.shade200 : Colors.red.shade200),
                                          ),
                                          child: Text(
                                            _isPumpConnected ? 'Connected' : 'Unconnected',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isPumpConnected ? Colors.blue.shade700 : Colors.red.shade700),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 20),

                        const Padding(
                          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                          child: Text('Plant Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: unifiedCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    child: Icon(_avatarMap[_currentAvatar] ?? Icons.eco, size: 54, color: primaryDarkGreen),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text('Moisture: 62%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Plant Name', style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(_currentName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 16, color: primaryDarkGreen),
                                        const SizedBox(width: 6),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Age: $_calcDays Days', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                                            Text('Planted: ${_currentDate.day}/${_currentDate.month}/${_currentDate.year}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                          child: Text('Soil Moisture Levels & Targets', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: unifiedCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: _screenshotBox('Field Capacity', '75 %', 'moisture level maximum plant health and growth', Colors.green, const Color(0xFFD4EDDA), const Color(0xFF28A745))),
                                    const SizedBox(width: 5),
                                    Expanded(child: _screenshotBox('Carbon Safe Line', '59 %', 'irrigation on before reaching this point\n ', Colors.amber.shade800, const Color(0xFFFFF3CD), const Color(0xFF856404))),
                                    const SizedBox(width: 5),
                                    Expanded(child: _screenshotBox('Wilting Point', '45 %', 'plant cannot recover moisture\n ', Colors.red, const Color(0xFFF8D7DA), const Color(0xFF721C24))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                          child: Text('Growth History', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: unifiedCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _growthThumbnailWithMoisture('assets/analytic_plant.jpg', 62, '12:00 PM')),
                                  const SizedBox(width: 8),
                                  Expanded(child: _growthThumbnailWithMoisture('assets/analytic_plant.jpg', 58, '12:00 PM')),
                                  const SizedBox(width: 8),
                                  Expanded(child: _growthThumbnailWithMoisture('assets/analytic_plant.jpg', 65, '12:00 PM')),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => _openGrowthHistoryGallery(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                                    child: const Text('View all', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5CB85C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2),
                              onPressed: _confirmComplete,
                              child: const Text('Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                            label: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: _confirmDelete,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _screenshotBox(String title, String percent, String desc, Color dotColor, Color boxBgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(color: boxBgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: dotColor.withOpacity(0.5), width: 1.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.visible, style: TextStyle(fontSize: 8, color: textColor, fontWeight: FontWeight.bold))),
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
            ],
          ), 
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Center(child: Text(percent, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor, height: 1.0))),
          ),
          Text(desc, style: TextStyle(fontSize: 7.5, color: textColor.withOpacity(0.85), height: 1.15), maxLines: 3, overflow: TextOverflow.visible),
        ],
      ),
    );
  }

  // 👑 时间已改为黑色粗体
  Widget _growthThumbnailWithMoisture(String assetPath, int moisturePercent, String timeString) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          image: DecorationImage(
            image: AssetImage(assetPath),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 4,
              child: Text(
                timeString,
                style: const TextStyle(
                  color: Colors.black87, // 黑色字体
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C4A3E).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$moisturePercent%',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}