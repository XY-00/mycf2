import 'package:flutter/material.dart';

class PlantProfileScreen extends StatefulWidget {
  const PlantProfileScreen({Key? key}) : super(key: key);

  @override
  State<PlantProfileScreen> createState() => _PlantProfileScreenState();
}

class _PlantProfileScreenState extends State<PlantProfileScreen> {
  final List<Map<String, dynamic>> _myPlantsList = [];

  void _showAddPlantDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Plant', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter Plant Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C4A3E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  _myPlantsList.add({
                    'name': nameController.text.trim(),
                    'date': DateTime.now(),
                  });
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF2C4A3E); 

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👑 1, 2 & 3. 修改点：去掉左边图像图标，纯显示字
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
                      'Plant Profile',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: _myPlantsList.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Tap the ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35))),
                          // 👑 修改点 2：将小加号背景强制修正为跟右下角一模一样的完美圆形（Circle）
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: primaryDarkGreen, shape: BoxShape.circle),
                            child: const Icon(Icons.add, color: Colors.white, size: 14),
                          ),
                          const Text(' to add a plant.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35))),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _myPlantsList.length,
                    itemBuilder: (context, index) {
                      final item = _myPlantsList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)]),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => PlantDetailsPageWithoutFAB(plantName: item['name'], initialDate: item['date'])));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFFEAF2E8), borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.eco, size: 32, color: primaryDarkGreen),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35))),
                                      const SizedBox(height: 4),
                                      const Text('Tap to view profile benchmarks', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryDarkGreen,
        onPressed: _showAddPlantDialog,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class PlantDetailsPageWithoutFAB extends StatefulWidget {
  final String plantName;
  final DateTime initialDate;

  const PlantDetailsPageWithoutFAB({Key? key, required this.plantName, required this.initialDate}) : super(key: key);

  @override
  State<PlantDetailsPageWithoutFAB> createState() => _PlantDetailsPageWithoutFABState();
}

class _PlantDetailsPageWithoutFABState extends State<PlantDetailsPageWithoutFAB> {
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
    const Color textDark = Color(0xFF2C3E35);

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(width: 90, height: 90, decoration: BoxDecoration(color: const Color(0xFFF4F7F5), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.eco, size: 45, color: primaryDarkGreen)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Plant Name', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54)),
                        Text(widget.plantName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
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
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
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