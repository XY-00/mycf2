import 'package:flutter/material.dart';
import 'add_plant_screen.dart'; 
import 'plant_details_screen.dart'; 

class PlantProfileScreen extends StatefulWidget {
  const PlantProfileScreen({Key? key}) : super(key: key);

  @override
  State<PlantProfileScreen> createState() => _PlantProfileScreenState();
}

class _PlantProfileScreenState extends State<PlantProfileScreen> {
  final List<Map<String, dynamic>> _myPlantsList = [];

  void _showAddPlantDialog() {
    showDialog(
      context: context,
      builder: (context) => AddPlantDialog(
        onAdd: (plantName) {
          setState(() {
            _myPlantsList.add({'name': plantName, 'date': DateTime.now()});
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF2C4A3E); 
    const Color softIvoryWhite = Color(0xFFF9FBFA); 

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👑 Title Bar：左右 Padding 锁定 20.0
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
                      // 👑 修改点 1：将这里的 margin 从 14 修正为 20.0，与顶栏边缘百分之百垂直齐平！
                      margin: const EdgeInsets.symmetric(horizontal: 20.0), 
                      decoration: BoxDecoration(color: softIvoryWhite, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Tap the ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35))),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: primaryDarkGreen, shape: BoxShape.circle),
                            child: const Icon(Icons.add, color: Colors.white, size: 14),
                          ),
                          const Text(' to add a plant', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35))),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    // 👑 修改点 1：这里的横向内补白同步修正为 20.0
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    itemCount: _myPlantsList.length,
                    itemBuilder: (context, index) {
                      final item = _myPlantsList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: softIvoryWhite, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)]),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => PlantDetailsScreen(plantName: item['name'], initialDate: item['date']),
                              ),
                            );
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
        shape: const CircleBorder(), 
        backgroundColor: primaryDarkGreen,
        onPressed: _showAddPlantDialog,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}