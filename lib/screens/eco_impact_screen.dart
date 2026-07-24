import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EcoImpactScreen extends StatefulWidget {
  const EcoImpactScreen({Key? key}) : super(key: key);

  @override
  State<EcoImpactScreen> createState() => _EcoImpactScreenState();
}

class _EcoImpactScreenState extends State<EcoImpactScreen> {
  String _profileName = 'Lee Xin Yi';
  String _profileId = 'FARM0027';

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  void _fetchUserInfo() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _profileName = user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'Lee Xin Yi';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF2C4A3E); 
    const Color containerBg = Color(0xFFF7F5EA);

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SingleChildScrollView(
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
                      Text('Eco Impact', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: containerBg, 
                      borderRadius: BorderRadius.circular(14), 
                      border: Border.all(color: Colors.black12), 
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 26,
                              backgroundColor: primaryDarkGreen,
                              child: Icon(Icons.face_retouching_natural, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Farmer: $_profileName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black), overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text('UserID: $_profileId', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider(color: Colors.black12)),
                        Stack(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start, 
                              children: [
                                CircleAvatar(radius: 20, backgroundColor: primaryDarkGreen.withOpacity(0.3), child: const Text('A', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Eco Friendly Grade', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                                    Text('Top 5% of Farmers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54)),
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {}, 
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black12)),
                                      child: const Icon(Icons.download_rounded, size: 14, color: primaryDarkGreen),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {}, 
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.black12)),
                                      child: const Icon(Icons.share_rounded, size: 14, color: primaryDarkGreen),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0), 
              child: Row(
                children: [
                  _buildMetricBox('Total Carbon\nFootprint saved', '146.0', isImageIcon: true),
                  const SizedBox(width: 8),
                  _buildMetricBox('Red-line\nsuccess', '3 of 3', icon: Icons.gps_fixed),
                  const SizedBox(width: 8),
                  _buildMetricBox('Total Water\nSaved (Liter)', '10.0', icon: Icons.opacity),
                ],
              ),
            ),
            const SizedBox(height: 14),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 20.0), 
              decoration: BoxDecoration(
                color: containerBg, 
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: Colors.black12), 
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text('History Record (Harvested)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(color: const Color(0xFFAEC4B5), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Expanded(child: Text('Date', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Expanded(child: Text('Carbon Footprint\nsaved (mg CO2e)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(child: Text('Grade', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildHistoryRow('2026/03', '146.0', 'A'),
                  _buildHistoryDataRow('10/03', '50.0', 'A'),
                  _buildHistoryDataRow('09/03', '50.0', 'A'),
                  _buildHistoryDataRow('08/03', '46.0', 'A'),
                  _buildHistoryRow('2026/02', '80.0', 'B'),
                  _buildHistoryDataRow('10/02', '20.0', 'B'),
                  _buildHistoryDataRow('09/02', '40.0', 'B'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildActionBtn('Data Comparison')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildActionBtn('Data Export')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, {IconData? icon, bool isImageIcon = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5EA), 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: Colors.black12), 
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isImageIcon 
                    ? Image.asset('assets/my_ic_carbonfootprint.png', width: 18, height: 18, color: const Color(0xFF2C4A3E))
                    : Icon(icon, size: 18, color: const Color(0xFF2C4A3E)),
                const SizedBox(width: 4),
                Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(String month, String value, String grade) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD6E4DA), 
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12), 
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(month, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: Text(grade, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildHistoryDataRow(String date, String value, String grade) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.transparent, 
        borderRadius: BorderRadius.circular(8), 
        border: Border.all(color: Colors.black12), 
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(date, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(child: Text(grade, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFA2B5A9), 
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12), 
      ),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }
}