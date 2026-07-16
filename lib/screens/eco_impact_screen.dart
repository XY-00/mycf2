import 'package:flutter/material.dart';

class EcoImpactScreen extends StatelessWidget {
  const EcoImpactScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF2C4A3E); 
    const Color containerBg = Color(0xFFF7F5EA);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 👑 1, 2 & 3. 修改点：大标题顶栏去掉左侧 Icon 图像，纯字显现
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: primaryDarkGreen, 
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 18.0, bottom: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Eco Impact',
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: containerBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.black87)),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(radius: 26, backgroundColor: primaryDarkGreen, child: Icon(Icons.face_retouching_natural, color: Colors.white, size: 28)),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Farmer: Lee Xin Yi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                                SizedBox(height: 2),
                                Text('UserID: FARM0027', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                              ],
                            )
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider(color: Colors.black)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]),
                          child: const Row(children: [Icon(Icons.download_rounded, size: 14, color: primaryDarkGreen), SizedBox(width: 4), Text('Download', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryDarkGreen))]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)]),
                          child: const Row(children: [Icon(Icons.share_rounded, size: 14, color: primaryDarkGreen), SizedBox(width: 4), Text('Share', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryDarkGreen))]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Row(
                children: [
                  _buildMetricBox('Total Carbon Footprint\nsaved (mg CO2e)', '146.0', Icons.eco_outlined),
                  const SizedBox(width: 8),
                  _buildMetricBox('Red-line success', '3 of 3\nIntervention', Icons.gps_fixed),
                  const SizedBox(width: 8),
                  _buildMetricBox('Total Water Saved\n(Liter)', '10.0', Icons.opacity),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Container(
                width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: containerBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black87)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black))),
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
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4), height: 110,
        decoration: BoxDecoration(color: const Color(0xFFF7F5EA), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black87)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: const Color(0xFF2C4A3E)), const SizedBox(width: 4),
                Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(String month, String value, String grade) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3), padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(color: const Color(0xFFD6E4DA), borderRadius: BorderRadius.circular(8)),
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
      margin: const EdgeInsets.symmetric(vertical: 2), padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black87)),
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
      decoration: BoxDecoration(color: const Color(0xFFA2B5A9), borderRadius: BorderRadius.circular(10)),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }
}