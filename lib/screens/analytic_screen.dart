import 'package:flutter/material.dart';

class AnalyticScreen extends StatelessWidget {
  const AnalyticScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF497E66), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('24-Hour Moisture Trend Analysis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),

            // 🌿 趋势大盒：完美引用你的专属图标 my_ic_analytic
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/my_ic_analytic.png', width: 55, height: 55, color: const Color(0xFF497E66)),
                  const SizedBox(height: 12),
                  const Text('Real-time Safe Line Standard Chart Rendering', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Visual Health Validation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _buildCell('Leaf Color Analysis', 'Lush green, no wilting', Icons.spa),
                _buildCell('Growth Rate', '2.3 cm per week', Icons.trending_up),
                _buildCell('Moisture Status', 'Optimal soil layer', Icons.water_drop),
                _buildCell('System Alerts', '0 Critical Alerts', Icons.check_circle),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String title, String status, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 14, color: const Color(0xFF497E66)), const SizedBox(width: 4), Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 8),
          Text(status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}