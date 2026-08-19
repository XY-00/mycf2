// lib/setting_screen.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  bool get wantKeepAlive => true; 
  
  String _selectedFrequency = '30 min';

  final ImagePicker _picker = ImagePicker();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  late final VoidCallback _statusListener;

  @override
  void initState() {
    super.initState();
    _initData();
    _initNotifications();
    _fetchFrequencyFromDB();

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
    super.dispose();
  }

  Future<void> _initData() async {
    await UserProfileCache.load();
    if (mounted) setState(() {});
  }

  Future<void> _fetchFrequencyFromDB() async {
    try {
      final res = await Supabase.instance.client
          .from('system_control')
          .select('capture_frequency_minutes')
          .eq('id', 1)
          .maybeSingle();
      
      if (res != null && res['capture_frequency_minutes'] != null) {
        int mins = res['capture_frequency_minutes'];
        if (mounted) {
          setState(() {
            _selectedFrequency = '$mins min';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching frequency from system_control: $e');
    }
  }

  void _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                  _buildDropdownRow('Capture Frequency', _selectedFrequency, ['15 min', '30 min', '60 min'], (v) async {
                    setState(() => _selectedFrequency = v!);
                    int mins = 30;
                    if (v!.contains('15')) mins = 15;
                    else if (v.contains('30')) mins = 30;
                    else if (v.contains('60')) mins = 60;

                    try {
                      await Supabase.instance.client.from('system_control').update({
                        'capture_frequency_minutes': mins
                      }).eq('id', 1);
                      debugPrint('Successfully updated frequency to $mins mins in system_control.');
                    } catch (e) {
                      debugPrint('Update frequency error: $e');
                    }
                  }),
                ]),

                const SizedBox(height: 14),

                InkWell(
                  onTap: () async {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user != null) {
                      try {
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