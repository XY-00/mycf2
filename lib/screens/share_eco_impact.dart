import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ShareEcoImpactDialog extends StatefulWidget {
  final String profileName;
  final String profileId;
  final String grade;

  const ShareEcoImpactDialog({
    Key? key,
    required this.profileName,
    required this.profileId,
    this.grade = 'A',
  }) : super(key: key);

  @override
  State<ShareEcoImpactDialog> createState() => _ShareEcoImpactDialogState();
}

class _ShareEcoImpactDialogState extends State<ShareEcoImpactDialog> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSaving = false;
  bool _isSharing = false;

  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  void _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showSystemNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'mycf_eco_channel_id',
      'myCF Eco Impact',
      channelDescription: 'Notifications for successful eco impact downloads',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'myCF download success',
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      'myCF',
      'Successfully saved to your gallery!',
      platformChannelSpecifics,
    );
  }

  Future<File?> _captureImageFile() async {
    try {
      RenderRepaintBoundary? boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      Uint8List pngBytes = byteData.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/myCF_eco_impact_${DateTime.now().millisecondsSinceEpoch}.png';
      File imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);
      return imageFile;
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleSaveAsImage(BuildContext context) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      File? imageFile = await _captureImageFile();
      if (imageFile == null) throw 'Failed to capture image';

      await Gal.putImage(imageFile.path);

      if (mounted) {
        await _showSystemNotification();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      File? imageFile = await _captureImageFile();
      if (imageFile == null) throw 'Failed to capture image';

      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: 'Check out my Eco Impact Grade ${widget.grade} on myCF! Total Carbon Footprint Saved: 146.0 mg CO2e 🌱',
        subject: 'My myCF Eco Impact',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF2C4A3E);

    Color gradeColor;
    if (widget.grade.toUpperCase() == 'A') {
      gradeColor = const Color(0xFF4CAF50);
    } else if (widget.grade.toUpperCase() == 'B') {
      gradeColor = const Color(0xFFFFB300);
    } else {
      gradeColor = const Color(0xFFE53935);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFFF7F5EA),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.90,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24),
                const Text(
                  'Share Your Impact',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryDarkGreen),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: primaryDarkGreen),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: RepaintBoundary(
                key: _globalKey,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E3C32),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/app_background.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.50),
                            const Color(0xFF1E3C32).withOpacity(0.70),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.asset(
                                    'assets/app_logo.png',
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'myCF',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Column(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(colors: [gradeColor, gradeColor.withOpacity(0.7)]),
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: [BoxShadow(color: gradeColor.withOpacity(0.6), blurRadius: 12)],
                                    ),
                                    child: Center(
                                      child: Text(widget.grade.toUpperCase(), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Eco-Friendly Grade ${widget.grade.toUpperCase()}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('IMPACT SNAPSHOT', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white60)),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: const [
                                            Expanded(
                                              child: Text(
                                                'Carbon Footprint Saved', 
                                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '146.0 mg', 
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        LinearProgressIndicator(
                                          value: 0.95,
                                          backgroundColor: Colors.white24,
                                          color: gradeColor,
                                          minHeight: 5,
                                        ),
                                        const SizedBox(height: 6),
                                        const Text('🌱 Leveling up the planet with myCF.', style: TextStyle(fontSize: 8.5, fontStyle: FontStyle.italic, color: Colors.white70)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ClipPath(
                            clipper: HonorOfKingsWaveClipper(),
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // 👑 换成和 Homepage 一致的普通标准人像头像（CircleAvatar + person 图标）
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF2C4A3E), width: 1.5),
                                      color: const Color(0xFF2C4A3E),
                                    ),
                                    child: const Icon(Icons.person, color: Colors.white, size: 15),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${widget.profileName.toUpperCase()}  •',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1B382B)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryDarkGreen,
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : () => _handleSaveAsImage(context),
              icon: _isSaving 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.download_rounded, color: Colors.white, size: 18),
              label: Text(_isSaving ? 'Saving to Gallery...' : 'Save as Image', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 14),

            const Text('INSTANT SHARE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 10),

            Center(
              child: _buildStyledShareIcon(Icons.more_horiz, 'More', Colors.blue.shade700, () => _handleShare(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledShareIcon(IconData icon, String label, Color iconBgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isSharing ? null : onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [iconBgColor, iconBgColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
        ],
      ),
    );
  }
}

class HonorOfKingsWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, 15);
    path.quadraticBezierTo(size.width * 0.35, 0, size.width * 0.65, 12);
    path.quadraticBezierTo(size.width * 0.85, 20, size.width, 5);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}