import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  double _redLineTarget = 59.0;
  bool _isManualMode = false;
  String _selectedDuration = '10 sec';
  String _selectedInterval = '10 min';
  String _selectedFrequency = '1 Hours';
  String _selectedQuality = 'Medium';

  String _profileName = 'Lee Xin Yi';
  String _profileId = 'FARM0027';
  bool _isIdLockedOnce = false; 

  void _openProfileEditSheet() {
    final nameCtrl = TextEditingController(text: _profileName);
    final idCtrl = TextEditingController(text: _profileId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update User Profile Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
            const SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Edit Full Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
              controller: idCtrl,
              enabled: !_isIdLockedOnce, 
              decoration: InputDecoration(
                labelText: _isIdLockedOnce ? 'User ID (Locked - Already changed once)' : 'Edit User ID (Can change once ONLY)',
                border: const OutlineInputBorder(),
                filled: _isIdLockedOnce,
                fillColor: Colors.black12,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C4A3E)),
                onPressed: () {
                  setState(() {
                    _profileName = nameCtrl.text.trim();
                    if (!_isIdLockedOnce && idCtrl.text.trim() != _profileId) {
                      _profileId = idCtrl.text.trim();
                      _isIdLockedOnce = true; 
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save Profile Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2C4A3E); 
    const Color panelColor = Color(0xFFF7F5EA);
    const Color softIvoryWhite = Color(0xFFF9FBFA); 

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 👑 Title Bar: 左右 Padding 锁定 20.0
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
                    Text(
                      'Setting',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 21, letterSpacing: -0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              // 👑 修改点 1：将横向内边距从 14 强制锁死为 20.0，卡片完美延展，对齐上下沿！
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: softIvoryWhite, 
                    borderRadius: BorderRadius.circular(16), 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 4)]
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _openProfileEditSheet, 
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 24, 
                            backgroundColor: primaryGreen, 
                            child: Icon(Icons.person, color: Colors.white, size: 22)
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_profileName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(height: 3),
                                Text('User ID: $_profileId (Click to edit name/avatar)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),

                _buildFigmaPanel(
                  panelColor,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.shutter_speed, size: 16, color: primaryGreen),
                          SizedBox(width: 6),
                          Text('Operation Mode Controls', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildModeBtn('Full Auto', true),
                          _buildModeBtn('Semi Auto', false),
                          _buildModeBtn('Power Save', false),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: const [Icon(Icons.waves, size: 14), SizedBox(width: 4), Text('Carbon Red-line Target Controls', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]),
                          Text('${_redLineTarget.toStringAsFixed(1)} %', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: _redLineTarget,
                        min: 0,
                        max: 100,
                        activeColor: primaryGreen,
                        inactiveColor: Colors.black12,
                        onChanged: (val) => setState(() => _redLineTarget = val),
                      ),
                    ],
                  ),
                ),

                _buildFigmaPanel(
                  panelColor,
                  Column(
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.opacity, size: 16, color: Colors.blue),
                          SizedBox(width: 6),
                          Text('Water Controls', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildDropdownRow('Max Watering Duration', _selectedDuration, ['10 sec', '20 sec', '30 sec'], (v) => setState(() => _selectedDuration = v!)),
                      const SizedBox(height: 8),
                      _buildDropdownRow('Watering Interval', _selectedInterval, ['10 min', '30 min', '60 min'], (v) => setState(() => _selectedInterval = v!)),
                    ],
                  ),
                ),

                _buildFigmaPanel(
                  panelColor,
                  Column(
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.camera_alt_outlined, size: 16, color: Colors.black87),
                          SizedBox(width: 6),
                          Text('Live Vision Setting', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildDropdownRow('Capture Frequency', _selectedFrequency, ['1 Hours', '2 Hours', '4 Hours'], (v) => setState(() => _selectedFrequency = v!)),
                      const SizedBox(height: 8),
                      _buildDropdownRow('Image Quality', _selectedQuality, ['Low', 'Medium', 'High'], (v) => setState(() => _selectedQuality = v!)),
                    ],
                  ),
                ),

                _buildFigmaPanel(
                  panelColor,
                  Column(
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.warning_amber_rounded, size: 16, color: Colors.redAccent),
                          SizedBox(width: 6),
                          Text('Manual Override Controls', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Enable Manual Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Switch(value: _isManualMode, activeColor: primaryGreen, onChanged: (v) => setState(() => _isManualMode = v)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Water Pump Control', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC3BADB), 
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12), 
                                side: const BorderSide(color: Colors.black38, width: 0.8)
                              )
                            ),
                            onPressed: _isManualMode ? () {} : null,
                            child: const Text('Activate Pump', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                InkWell(
                  onTap: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBAC596), 
                      borderRadius: BorderRadius.circular(12), 
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
                    ),
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

  Widget _buildFigmaPanel(Color bg, Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3))
        ]
      ),
      child: child,
    );
  }

  Widget _buildModeBtn(String label, bool isActive) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFBAC596) : Colors.transparent, 
          border: Border.all(color: Colors.black38, width: 0.8), 
          borderRadius: BorderRadius.circular(8)
        ),
        child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDropdownRow(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFA), 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.black12, width: 0.8)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
              onChanged: onChanged,
            ),
          )
        ],
      ),
    );
  }
}