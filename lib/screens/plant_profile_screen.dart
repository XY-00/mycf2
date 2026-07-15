import 'package:flutter/material.dart';

class PlantProfileScreen extends StatefulWidget {
  const PlantProfileScreen({Key? key}) : super(key: key);

  @override
  State<PlantProfileScreen> createState() => _PlantProfileScreenState();
}

class _PlantProfileScreenState extends State<PlantProfileScreen> {
  bool _hasPlant = false;
  String _customPlantName = '';
  DateTime _selectedDate = DateTime.now();

  int get _daysSincePlanting {
    return DateTime.now().difference(_selectedDate).inDays;
  }

  Future<void> _pickPlantingDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF497E66),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2C3E35),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showAddPlantDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Plant', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF497E66))),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter Plant Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF497E66),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  _customPlantName = nameController.text.trim();
                  _hasPlant = true;
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
    const Color primaryGreen = Color(0xFF497E66);
    const Color textDark = Color(0xFF2C3E35);
    const Color fieldCapacityColor = Color(0xFF5CB85C);
    const Color carbonSafeColor = Color(0xFFF0AD4E);
    const Color wiltingPointColor = Color(0xFFD9534F);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Plant Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        centerTitle: true,
        backgroundColor: primaryGreen,
        elevation: 0,
      ),
      // 👑 1. 修改点：把空白文案换成新指定的，并且中间的 + 号渲染成跟右下角 FAB 一模一样的迷你绿色小圆钮圈
      body: !_hasPlant 
          ? Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Tap the ',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                        ),
                        // 👑 迷你同款 FAB 图标设计
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: primaryGreen, shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: Colors.white, size: 14),
                        ),
                        const Text(
                          ' to add a plant.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryGreen.withOpacity(0.3), width: 1.5),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: const Icon(Icons.eco, size: 55, color: primaryGreen),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                const Text('Plant Name', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54, fontWeight: FontWeight.w600)),
                                Text(_customPlantName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
                                const SizedBox(height: 14),
                                InkWell(
                                  onTap: _pickPlantingDate,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2.0),
                                        child: Icon(Icons.calendar_month_outlined, size: 22, color: textDark),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Age / Days Since Planting', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                                            Text('$_daysSincePlanting Days', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                            Text('Planted: ${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year} (Tap to change)', style: const TextStyle(fontSize: 10, color: primaryGreen, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Physiological Moisture Benchmarks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryGreen)),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildBenchmarkBox('Field Capacity', '75 %', 'moisture level maximum plant health and growth', fieldCapacityColor)),
                              const SizedBox(width: 6),
                              Expanded(child: _buildBenchmarkBox('Carbon Safe Line', '59 %', 'irrigation on before reaching this point', carbonSafeColor)),
                              const SizedBox(width: 6),
                              Expanded(child: _buildBenchmarkBox('Wilting Point', '45 %', 'plant cannot recover moisture', wiltingPointColor)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('45%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textDark)),
                                Text('59%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textDark)),
                                Text('75%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textDark)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: const LinearGradient(colors: [Color(0xFFE29592), Color(0xFFF7DBA6), Color(0xFFAADCA6)]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('View Growth History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryGreen)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 85,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 3,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 110,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(color: const Color(0xFFF0F4F1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
                                  child: const Icon(Icons.image_outlined, color: Colors.grey, size: 28),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(border: Border.all(color: Colors.black87), borderRadius: BorderRadius.circular(12)),
                              child: const Text('View all', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.trending_up, size: 18, color: primaryGreen),
                              SizedBox(width: 6),
                              Text('Predicted Water Requirements', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryGreen)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildPredictionBox('Daily pump', '180 ml')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildPredictionBox('Weekly Total', '1.26 L')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildPredictionBox('Irrigation Rules', '4-5 / week')),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGreen,
        onPressed: _showAddPlantDialog,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildBenchmarkBox(String title, String value, String desc, Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(color: themeColor.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: themeColor.withOpacity(0.3), width: 1.2)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Flexible(child: Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: themeColor), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: themeColor)),
          const SizedBox(height: 4),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, color: Colors.black54, height: 1.1)),
        ],
      ),
    );
  }

  Widget _buildPredictionBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(color: const Color(0xFFEAF2E8), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35))),
        ],
      ),
    );
  }
}