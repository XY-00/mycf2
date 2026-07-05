import 'package:flutter/material.dart';

class EcoImpactScreen extends StatelessWidget {
  const EcoImpactScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eco Impact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF497E66), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🌿 Lee Xin Yi 专属荣誉名片
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFFFFDF0), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber.shade300)),
              child: Row(
                children: [
                  const CircleAvatar(radius: 26, backgroundColor: Colors.white, child: Icon(Icons.account_circle, size: 45, color: Color(0xFF497E66))),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Farmer: Lee Xin Yi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('UserID: FARM0027', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const Spacer(),
                  CircleAvatar(radius: 24, backgroundColor: Colors.green.shade50, child: const Text('A', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF497E66))))
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 历史减碳环保评分列表
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('History Carbon Logs', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const Divider(),
                  _buildRow('2026/03', '146.0 mg', 'Grade A'),
                  _buildRow('2026/02', '80.0 mg', 'Grade B'),
                  _buildRow('2026/01', '66.0 mg', 'Grade B'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200), child: const Text('Data Comparison', style: TextStyle(color: Colors.black87)))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF497E66)), child: const Text('Data Export', style: TextStyle(color: Colors.white)))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String date, String data, String grade) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(date, style: const TextStyle(fontWeight: FontWeight.bold)), Text(data), Text(grade, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))],
      ),
    );
  }
}