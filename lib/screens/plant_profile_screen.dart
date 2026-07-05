import 'package:flutter/material.dart';

class PlantProfileScreen extends StatelessWidget {
  const PlantProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plant Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF497E66), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.eco, size: 40, color: Color(0xFF497E66)),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Common Name: Bok Choy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Scientific Name: Brassica rapa', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                      Text('Age: 30 Days (Planted: 11/1/2026)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🌿 59% 精准渐变红线控制刻度尺
            const Text('Physiological Moisture Benchmarks', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(children: [Text('Field Capacity', style: TextStyle(fontSize: 11, color: Colors.grey)), Text('75 %', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))]),
                      Column(children: [Text('Carbon Safe Line', style: TextStyle(fontSize: 11, color: Colors.grey)), Text('59 %', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16))]),
                      Column(children: [Text('Wilting Point', style: TextStyle(fontSize: 11, color: Colors.grey)), Text('45 %', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))]),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(colors: [Colors.red, Colors.orange, Colors.green]),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('View Growth History (Pi Camera V2)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, index) => Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}