import 'package:flutter/material.dart';

class PlantDetailsScreen extends StatefulWidget {
  final String plantName;
  final DateTime initialDate;

  const PlantDetailsScreen({Key? key, required this.plantName, required this.initialDate}) : super(key: key);

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  int get _calcDays {
    return DateTime.now().difference(_selectedDate).inDays;
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF2C4A3E);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: Text('${widget.plantName} Details', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryDarkGreen,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        // 👑 修改点 1：将整体详情内容的横向边距死死锁定在 20.0 像素！
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), 
        child: Column(
          children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF9FBFA), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(width: 90, height: 90, decoration: BoxDecoration(color: const Color(0xFFF4F7F5), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.eco, size: 45, color: primaryDarkGreen)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Plant Name', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54)),
                        Text(widget.plantName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35))),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                            if (picked != null) setState(() => _selectedDate = picked);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$_calcDays Days Old', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                              Text('Planted: ${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year} (Tap to change)', style: const TextStyle(fontSize: 11, color: primaryDarkGreen)),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF9FBFA), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Physiological Moisture Benchmarks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _box('Field Capacity', '75 %', Colors.green)),
                      const SizedBox(width: 6),
                      Expanded(child: _box('Carbon Safe Line', '59 %', Colors.orange)),
                      const SizedBox(width: 6),
                      Expanded(child: _box('Wilting Point', '45 %', Colors.red)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(String t, String v, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.3))),
      child: Column(children: [Text(t, style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(v, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c))]),
    );
  }
}