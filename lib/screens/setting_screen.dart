// lib/setting_screen.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'login_screen.dart';
import 'hardware_status_manager.dart';

class UserProfileCache {
  static String avatarPath = '';
  static String profileName = '';
  static String profileEmail = '';

  static String _getUserKey(String baseKey) {
    final user = Supabase.instance.client.auth.currentUser;
    final uid = user?.id ?? 'default_user';
    return '${baseKey}_$uid';
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    avatarPath = prefs.getString(_getUserKey('global_user_avatar')) ?? '';
    
    final user = Supabase.instance.client.auth.currentUser;
    String regName = 'LEE XIN YI';
    String regEmail = 'leexinyi@example.com';
    if (user != null) {
      regName = user.userMetadata?['name'] ?? 
                user.userMetadata?['full_name'] ?? 
                user.userMetadata?['displayname'] ?? 
                user.email?.split('@').first ?? 'LEE XIN YI';
      regEmail = user.email ?? 'leexinyi@example.com';
    }

    profileName = prefs.getString(_getUserKey('global_user_name')) ?? regName;
    profileEmail = prefs.getString(_getUserKey('global_user_email')) ?? regEmail;
  }

  static Future<void> save(String name, String email, String avatar) async {
    final prefs = await SharedPreferences.getInstance();
    profileName = name;
    profileEmail = email;
    avatarPath = avatar;
    await prefs.setString(_getUserKey('global_user_name'), name);
    await prefs.setString(_getUserKey('global_user_email'), email);
    await prefs.setString(_getUserKey('global_user_avatar'), avatar);
  }
}

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 保持页面滚动位置，切走再回来不用重新划

  static double _minimumMoistureStart = 59.0;
  static double _maxMoistureStop = 80.0;
  static String _selectedAutoMode = 'Full Auto';
  
  String _selectedFrequency = '30 min';
  String _selectedQuality = 'Medium';

  bool _autoLockPumpsOnEmpty = true;
  bool _tankAlertSoundEnabled = true;

  bool _isPumpActive = false;
  int _remainingSeconds = 0;
  Timer? _pumpTimer;

  final ImagePicker _picker = ImagePicker();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  final AudioPlayer _audioPlayer = AudioPlayer();

  late final VoidCallback _statusListener;

  @override
  void initState() {
    super.initState();
    _initData();
    _initNotifications();

    HardwareStatusManager.initNotifications(_notificationsPlugin);
    
    _statusListener = () {
      if (mounted) setState(() {});
    };

    HardwareStatusManager.addListener(_statusListener);

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    HardwareStatusManager.removeListener(_statusListener);
    _pumpTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await UserProfileCache.load();
    if (mounted) setState(() {});
  }

  void _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _playAlarmSound() async {
    if (!_tankAlertSoundEnabled) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'));
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  Future<void> _showSystemNotification(String title, String body, {bool playSound = true}) async {
    if (playSound && _tankAlertSoundEnabled) {
      _playAlarmSound(); 
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'mycf_tank_alert_channel_id',
      'myCF Water Tank & System Alerts',
      channelDescription: 'Notifications for water tank storage and system alerts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'myCF Alert',
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: false, 
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        htmlFormatContent: true,
        htmlFormatContentTitle: true,
      ),
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void _showModeChangeDialog(String modeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('System Mode Updated', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
        content: Text('Successfully switched to $modeName mode.', style: const TextStyle(fontSize: 13, color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF2C4A3E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _simulateTankEmptyAlert() {
    if (_isPumpActive) {
      _pumpTimer?.cancel();
      setState(() {
        _isPumpActive = false;
        _remainingSeconds = 0;
      });
    }

    _showSystemNotification(
      'CRITICAL WARNING: TANK EMPTY', 
      'Float sensor detected water tank is empty! Water pumps have been automatically locked to prevent dry burning.',
      playSound: true,
    );
  }

  void _toggleManualPump() {
    if (_isPumpActive) {
      _pumpTimer?.cancel();
      setState(() {
        _isPumpActive = false;
        _remainingSeconds = 0;
      });
      _showSystemNotification('Water Pump Stopped', 'Manual water pump has been stopped successfully.', playSound: false);
    } else {
      setState(() {
        _isPumpActive = true;
        _remainingSeconds = 10; 
      });

      _showSystemNotification('Water Pump Activated', 'Manual water pump activated for 10 seconds.', playSound: false);

      _pumpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 1) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          timer.cancel();
          setState(() {
            _isPumpActive = false;
            _remainingSeconds = 0;
          });
          _showSystemNotification('Water Pump Stopped', 'Water pump automatically stopped (Timer finished).', playSound: false);
        }
      });
    }
  }

  void _openProfileEditSheet() {
    final nameCtrl = TextEditingController(text: UserProfileCache.profileName);
    final emailCtrl = TextEditingController(text: UserProfileCache.profileEmail);
    String tempAvatar = UserProfileCache.avatarPath;
    File? tempImageFile = (tempAvatar.isNotEmpty && (tempAvatar.startsWith('/') || tempAvatar.startsWith('file://'))) ? File(tempAvatar) : null;

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

          bool isTempLocal = tempAvatar.isNotEmpty && (tempAvatar.startsWith('/') || tempAvatar.startsWith('file://'));
          bool tempFileExists = isTempLocal && tempImageFile != null && tempImageFile!.existsSync();

          return Padding(
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
                  child: Text('Edit User Profile', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
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
                              ? const Center(child: Icon(Icons.person, size: 40, color: Color(0xFF2C4A3E)))
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
                const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
                const SizedBox(height: 4),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Email Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
                const SizedBox(height: 4),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
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
                        String fileName = 'user_${DateTime.now().millisecondsSinceEpoch}.png';
                        final permanentImage = await tempImageFile!.copy('${appDir.path}/$fileName');
                        finalAvatar = permanentImage.path;
                      }

                      await UserProfileCache.save(nameCtrl.text.trim(), emailCtrl.text.trim(), finalAvatar);
                      if (mounted) setState(() {});
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void _triggerSemiAutoNotification() {
    _showSystemNotification('Semi Auto Alert', 'Soil moisture dropped below minimum moisture start threshold!', playSound: false);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFF7F5EA),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.notifications_active_rounded, color: Colors.orange, size: 26),
                  SizedBox(width: 8),
                  Text('Semi Auto Alert', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Soil moisture has dropped below the minimum moisture start threshold in Semi Auto mode.\n\nWould you like to trigger irrigation now, or ignore and water manually later?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.grey)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showSystemNotification('Semi Auto Ignored', 'Irrigation ignored. Switch to Manual mode to water later.', playSound: false);
                      },
                      child: const Text('Ignore', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C4A3E),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showSystemNotification('Water Pump Activated', 'Water Pump activated successfully in Semi Auto!', playSound: false);
                      },
                      child: const Text('Pump Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须保留以支持 KeepAlive 滚动保持
    const Color primaryGreen = Color(0xFF2C4A3E); 
    const Color softIvoryWhite = Color(0xFFF9FBFA); 

    bool isAvatarLocal = UserProfileCache.avatarPath.isNotEmpty && (UserProfileCache.avatarPath.startsWith('/') || UserProfileCache.avatarPath.startsWith('file://'));
    bool avatarExists = isAvatarLocal && File(UserProfileCache.avatarPath).existsSync();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: primaryGreen, 
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
                    Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 21, letterSpacing: -0.3)),
                  ],
                ),
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0), 
              children: [
                _buildSectionTitle('USER ACCOUNT'),
                Container(
                  width: double.infinity, 
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: softIvoryWhite, 
                    borderRadius: BorderRadius.circular(16), 
                    border: Border.all(color: Colors.black12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16), 
                    onTap: _openProfileEditSheet, 
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryGreen,
                              image: avatarExists ? DecorationImage(image: FileImage(File(UserProfileCache.avatarPath)), fit: BoxFit.cover) : null,
                            ),
                            child: !avatarExists ? const Icon(Icons.person, color: Colors.white, size: 24) : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(UserProfileCache.profileName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(height: 3),
                                Text(UserProfileCache.profileEmail, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),

                _buildSectionTitle('HARDWARE & SENSORS STATUS'),
                _buildGroupPanel([
                  Row(
                    children: const [
                      Icon(Icons.router_rounded, size: 16, color: primaryGreen),
                      SizedBox(width: 6),
                      Text('System Connection Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  HardwareStatusManager.buildStatusRow('myCF', HardwareStatusManager.isPiConnected),
                  HardwareStatusManager.buildStatusRow('Camera Module', false),
                  HardwareStatusManager.buildStatusRow('Float Water Level Sensor', HardwareStatusManager.isFloatConnected),
                ]),

                _buildSectionTitle('OPERATION & CONTROL'),
                _buildGroupPanel([
                  Row(
                    children: const [
                      Icon(Icons.shutter_speed, size: 16, color: primaryGreen),
                      SizedBox(width: 6),
                      Text('System Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildModeBtn('Full Auto', _selectedAutoMode == 'Full Auto', () {
                        setState(() => _selectedAutoMode = 'Full Auto');
                        _showModeChangeDialog('Full Auto');
                      }),
                      _buildModeBtn('Semi Auto', _selectedAutoMode == 'Semi Auto', () {
                        setState(() {
                          _selectedAutoMode = 'Semi Auto';
                          _triggerSemiAutoNotification();
                        });
                        _showModeChangeDialog('Semi Auto');
                      }),
                      _buildModeBtn('Manual', _selectedAutoMode == 'Manual', () {
                        setState(() {
                          _selectedAutoMode = 'Manual';
                        });
                        _showModeChangeDialog('Manual');
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: const [Icon(Icons.waves, size: 14, color: Colors.black54), SizedBox(width: 4), Text('Minimum Moisture Start', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen))]),
                      Text('${_minimumMoistureStart.toStringAsFixed(1)} %', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen)),
                    ],
                  ),
                  Slider(
                    value: _minimumMoistureStart, min: 0, max: 100, activeColor: primaryGreen, inactiveColor: Colors.black12,
                    onChanged: (val) => setState(() => _minimumMoistureStart = val),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: const [Icon(Icons.stop_circle_outlined, size: 14, color: Colors.black54), SizedBox(width: 4), Text('Max Moisture Stop Limit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen))]),
                      Text('${_maxMoistureStop.toStringAsFixed(1)} %', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen)),
                    ],
                  ),
                  Slider(
                    value: _maxMoistureStop, min: 50, max: 100, activeColor: primaryGreen, inactiveColor: Colors.black12,
                    onChanged: (val) => setState(() => _maxMoistureStop = val),
                  ),
                ]),

                _buildSectionTitle('CAMERA & VISION SETTINGS'),
                _buildGroupPanel([
                  Row(
                    children: const [
                      Icon(Icons.camera_alt_outlined, size: 16, color: Colors.teal),
                      SizedBox(width: 6),
                      Text('Camera Customization', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildDropdownRow('Capture Frequency', _selectedFrequency, ['15 min', '30 min', '60 min'], (v) => setState(() => _selectedFrequency = v!)),
                  const SizedBox(height: 8),
                  _buildDropdownRow('Image Quality', _selectedQuality, ['Low', 'Medium', 'High'], (v) => setState(() => _selectedQuality = v!)),
                ]),

                _buildSectionTitle('MANUAL OVERRIDE'),
                _buildGroupPanel([
                  Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, size: 16, color: Colors.redAccent),
                      SizedBox(width: 6),
                      Text('Hardware Direct Control', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(child: Text('Water Pump Direct Control', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87))),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (_selectedAutoMode == 'Manual') 
                                ? (_isPumpActive ? Colors.redAccent : const Color(0xFFC3BADB)) 
                                : Colors.grey.shade300, 
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.black38, width: 0.8))
                          ),
                          onPressed: (_selectedAutoMode == 'Manual') ? () => _toggleManualPump() : null,
                          child: Text(
                            _isPumpActive ? 'Stop Pump (${_remainingSeconds}s)' : 'Activate Pump', 
                            style: TextStyle(
                              color: (_selectedAutoMode == 'Manual') ? (_isPumpActive ? Colors.white : Colors.black87) : Colors.grey, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 11
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  if (_selectedAutoMode != 'Manual')
                    const Padding(
                      padding: EdgeInsets.only(top: 6.0),
                      child: Text('*(Switch System Mode to Manual to unlock override)*', style: TextStyle(fontSize: 10, color: Colors.redAccent, fontStyle: FontStyle.italic)),
                    ),
                ]),

                _buildSectionTitle('WATER TANK STORAGE & PROTECTION'),
                _buildGroupPanel([
                  Row(
                    children: const [
                      Icon(Icons.water_drop_rounded, size: 16, color: Colors.blue),
                      SizedBox(width: 6),
                      Text('Float Water Level Sensor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(child: Text('Auto-Lock Pumps When Tank Empty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87))),
                      Switch(
                        value: _autoLockPumpsOnEmpty, 
                        activeColor: primaryGreen, 
                        onChanged: (v) => setState(() => _autoLockPumpsOnEmpty = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(child: Text('Tank Empty Alert Sound & Banner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87))),
                      Switch(
                        value: _tankAlertSoundEnabled, 
                        activeColor: primaryGreen, 
                        onChanged: (v) => setState(() => _tankAlertSoundEnabled = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _simulateTankEmptyAlert(),
                      icon: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                      label: const Text('Test Tank Empty Alert (Simulate Sound)', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('*(When water tank is empty, system automatically locks water pumps and pushes a critical alert banner with sound)*', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                ]),
                const SizedBox(height: 14),

                InkWell(
                  onTap: () async {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user != null) {
                      try {
                        // 👑 关键修复：点击 Logout 时，只把连接状态设为 false，绝对不碰、不覆写 moisture_level，完美保留最后记录！
                        for (int slot = 1; slot <= 3; slot++) {
                          await Supabase.instance.client.from('hardware_status').update({
                            'sensor_connected': false,
                            'pump_connected': false,
                            'updated_at': DateTime.now().toIso8601String(),
                          }).eq('user_id', user.id).eq('slot_number', slot);
                        }

                        await Supabase.instance.client
                            .from('system_control')
                            .update({
                              'is_running': false,
                              'current_user_id': null,
                            })
                            .eq('id', 1);
                      } catch (e) {
                        debugPrint('Failed to update system_control on logout: $e');
                      }
                    }

                    HardwareStatusManager.stopMonitoring();

                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                    }
                  },
                  child: Container(
                    width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: const Color(0xFFBAC596), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
                    child: const Text('LOG OUT', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 10.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildGroupPanel(List<Widget> children) {
    return Container(
      width: double.infinity, 
      margin: const EdgeInsets.only(bottom: 20), 
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFA), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.black12), 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildModeBtn(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2), padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFBAC596) : Colors.white, 
            border: Border.all(color: Colors.black38, width: 0.8), 
            borderRadius: BorderRadius.circular(8)
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.black87)),
        ),
      ),
    );
  }

  Widget _buildDropdownRow(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), 
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFA), 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.black12, width: 0.8)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87))),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2C4A3E)),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}