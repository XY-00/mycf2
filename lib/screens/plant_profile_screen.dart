import 'package:flutter/material.dart';
import 'add_plant_screen.dart'; 
import 'plant_details_screen.dart'; 

class PlantProfileScreen extends StatefulWidget {
  const PlantProfileScreen({Key? key}) : super(key: key);

  @override
  State<PlantProfileScreen> createState() => _PlantProfileScreenState();
}

class _PlantProfileScreenState extends State<PlantProfileScreen> {
  final List<Map<String, dynamic>?> _slotsList = [null, null, null];

  final Map<String, IconData> _avatarMap = {
    'Sunflower 🌻': Icons.wb_sunny_outlined,
    'Cactus 🌵': Icons.grass_rounded, 
    'Rose 🌹': Icons.favorite_border_rounded,
    'Fern 🌿': Icons.eco_outlined,
  };

  void _showAddPlantDialog(int slotIndex) {
    showDialog(
      context: context,
      builder: (context) => AddPlantDialog(
        slotNumber: slotIndex + 1,
        onAdd: (name, date, avatar) {
          setState(() {
            _slotsList[slotIndex] = {
              'name': name,
              'date': date,
              'avatar': avatar,
            };
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
                    Text('Plant Profile', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), 
              itemCount: 3, 
              itemBuilder: (context, index) {
                final plant = _slotsList[index];

                if (plant == null) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(color: softIvoryWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
                    child: InkWell(
                      onTap: () => _showAddPlantDialog(index),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Slot ${index + 1}: Tap ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35))),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: primaryDarkGreen, shape: BoxShape.circle),
                            child: const Icon(Icons.add, color: Colors.white, size: 14),
                          ),
                          const Text(' to plant here', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35))),
                        ],
                      ),
                    ),
                  );
                }

                final int daysOld = DateTime.now().difference(plant['date']).inDays;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: softIvoryWhite, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)]),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlantDetailsScreen(
                            slotIndex: index,
                            initialName: plant['name'],
                            initialDate: plant['date'],
                            initialAvatar: plant['avatar'],
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          if (result['action'] == 'delete' || result['action'] == 'harvest') {
                            _slotsList[index] = null; 
                          } else if (result['action'] == 'update') {
                            _slotsList[index] = {
                              'name': result['name'],
                              'date': result['date'],
                              'avatar': result['avatar'],
                            };
                          }
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFEAF2E8), borderRadius: BorderRadius.circular(12)),
                            child: Icon(_avatarMap[plant['avatar']] ?? Icons.eco, size: 32, color: primaryDarkGreen),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plant['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35))),
                                const SizedBox(height: 4),
                                Text('Slot ${index + 1} • $daysOld Days Old', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
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
    );
  }
}