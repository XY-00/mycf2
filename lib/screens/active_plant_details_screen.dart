import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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
  double _moistureLevel = 0.0;
  bool _isCheckingHardware = true;
  
  final List<Map<String, dynamic>> _growthSnapshots = []; 

  Timer? _pollingTimer;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentName = widget.initialName;
    _currentDate = widget.initialDate;
    _currentAvatar = widget.initialAvatar;
    
    _fetchHardwareAndMoistureStatus();

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchHardwareAndMoistureStatus();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchHardwareAndMoistureStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      int slotNumber = widget.slotIndex + 1;
      
      // 👑 严格按当前登录用户的 user_id 和 slot_number 联合查询，并按 updated_at 倒序获取最新的一条实时状态
      final response = await Supabase.instance.client
          .from('hardware_status')
          .select()
          .eq('slot_number', slotNumber)
          .eq('user_id', user.id)
          .order('updated_at', ascending: false) // 确保拿到的是树莓派最近一次写入的最新数据
          .limit(1)
          .maybeSingle();

      if (response != null && mounted) {
        bool sensorConn = response['sensor_connected'] ?? false;
        bool pumpConn = response['pump_connected'] ?? false;
        double moisture = (response['moisture_level'] ?? 0.0).toDouble();

        // 👑 增加时间戳双重校验：检查这行数据的更新时间是否在最近 15 秒内
        // 如果树莓派关机或停止运行，旧数据的 updated_at 会停留在过去，直接强制判定为未连接！
        final updatedAtStr = response['updated_at']?.toString();
        if (updatedAtStr != null) {
          String rawTime = updatedAtStr.contains('+') ? updatedAtStr.split('+')[0] : updatedAtStr.replaceAll('Z', '');
          DateTime lastUpdateTime = DateTime.parse(rawTime);
          int diffSeconds = DateTime.now().difference(lastUpdateTime).inSeconds;
          
          if (diffSeconds > 15) {
            sensorConn = false;
            pumpConn = false;
          }
        } else {
          sensorConn = false;
          pumpConn = false;
        }

        setState(() {
          _isSensorConnected = sensorConn;
          _isPumpConnected = pumpConn;
          _moistureLevel = moisture;
          _isCheckingHardware = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isSensorConnected = false;
            _isPumpConnected = false;
            _moistureLevel = 0.0;
            _isCheckingHardware = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSensorConnected = false;
          _isPumpConnected = false;
          _isCheckingHardware = false;
        });
      }
      print('Error fetching hardware status: $e');
    }
  }

  int get _calcDays => DateTime.now().difference(_currentDate).inDays;

  void _openEditBottomSheet() {
    final nameCtrl = TextEditingController(text: _currentName);
    String tempAvatar = _currentAvatar;
    File? tempImageFile = (_currentAvatar.startsWith('/') || _currentAvatar.startsWith('file://')) ? File(_currentAvatar) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setPopupState) {
          Future<void> pickImage(ImageSource source) async {
            final XFile? picked = await _picker.pickImage(source: source, imageQuality: 80);
            if (picked != null) {
              setPopupState(() {
                tempImageFile = File(picked.path);
                tempAvatar = picked.path;
              });
            }
          }

          void showSourceDialog() {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Change Photo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        setPopupState(() {
                          tempAvatar = '';
                          tempImageFile = null;
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2C4A3E)),
                      title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onTap: () {
                        Navigator.pop(ctx);
                        pickImage(ImageSource.camera);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF2C4A3E)),
                      title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onTap: () {
                        Navigator.pop(ctx);
                        pickImage(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          bool isTempLocal = tempAvatar.startsWith('/') || tempAvatar.startsWith('file://');
          bool tempFileExists = isTempLocal && tempImageFile != null && tempImageFile!.existsSync();

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 24, 
                right: 24, 
                top: 24, 
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text('Edit Plant Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: showSourceDialog,
                          child: Container(
                            width: 85,
                            height: 85,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF2C4A3E), width: 2),
                              image: tempFileExists
                                  ? DecorationImage(image: FileImage(tempImageFile!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: !tempFileExists
                                ? const Center(child: Text('🌱', style: TextStyle(fontSize: 34)))
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: showSourceDialog,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2C4A3E)),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0, bottom: 6.0),
                    child: Text('Plant Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
                  ),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C4A3E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        String finalAvatar = tempAvatar;
                        if (tempImageFile != null && tempImageFile!.existsSync() && !tempImageFile!.path.contains('app_flutter')) {
                          final appDir = await getApplicationDocumentsDirectory();
                          String fileName = 'plant_${DateTime.now().millisecondsSinceEpoch}.png';
                          final permanentImage = await tempImageFile!.copy('${appDir.path}/$fileName');
                          finalAvatar = permanentImage.path;
                        }

                        setState(() {
                          _currentName = nameCtrl.text.trim();
                          _currentAvatar = finalAvatar;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openGrowthHistoryGallery(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF4F7F5),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
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
                        Text(_currentName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        const Text('Growth History', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Expanded(
                child: _growthSnapshots.isEmpty
                    ? const Center(
                        child: Text(
                          'No growth history yet',
                          style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      )
                    : ListView(controller: scrollController, children: const []),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
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
    
    bool isLocalFile = _currentAvatar.startsWith('/') || _currentAvatar.startsWith('file://');
    bool fileExists = isLocalFile && File(_currentAvatar).existsSync();

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/app_background.png'), fit: BoxFit.cover),
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
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
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
                                          child: Text(_isSensorConnected ? 'Connected' : 'Unconnected', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isSensorConnected ? Colors.green.shade700 : Colors.red.shade700)),
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
                                          child: Text(_isPumpConnected ? 'Connected' : 'Unconnected', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isPumpConnected ? Colors.blue.shade700 : Colors.red.shade700)),
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
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black12),
                                      image: fileExists
                                          ? DecorationImage(image: FileImage(File(_currentAvatar)), fit: BoxFit.cover)
                                          : null,
                                    ),
                                    child: !fileExists
                                        ? const Center(child: Text('🌱', style: TextStyle(fontSize: 28)))
                                        : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Moisture: ', 
                                            style: TextStyle(
                                              fontSize: 11, 
                                              fontWeight: FontWeight.bold, 
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            '${_moistureLevel.toStringAsFixed(1)}%', 
                                            style: TextStyle(
                                              fontSize: 11, 
                                              fontWeight: FontWeight.bold, 
                                              color: _moistureLevel <= 59.0 ? Colors.red : (_moistureLevel < 63.0 ? Colors.orange : Colors.green),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!_isSensorConnected)
                                        const Text(
                                          '(Last Record)', 
                                          style: TextStyle(fontSize: 8, color: Colors.grey, fontStyle: FontStyle.italic),
                                        ),
                                    ],
                                  ),
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
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: unifiedCardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
                          ),
                          child: _growthSnapshots.isEmpty
                              ? Column(
                                  children: const [
                                    Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 12.0),
                                        child: Text(
                                          'No growth history yet',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
}