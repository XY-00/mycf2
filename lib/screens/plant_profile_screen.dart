import 'package:flutter/material.dart';
import 'add_plant_screen.dart'; 
import 'plant_details_screen.dart'; 

class PlantProfileScreen extends StatefulWidget {
  const PlantProfileScreen({Key? key}) : super(key: key);

  @override
  State<PlantProfileScreen> createState() => _PlantProfileScreenState();
}

class _PlantProfileScreenState extends State<PlantProfileScreen> {
  // 0 代表 Active Plants，1 代表 History
  int _selectedSegment = 0; 

  final List<Map<String, dynamic>> _activePlants = [];
  final List<Map<String, dynamic>> _historyPlants = [];

  final Map<String, IconData> _avatarMap = {
    'Sunflower 🌻': Icons.wb_sunny_outlined,
    'Cactus 🌵': Icons.grass_rounded, 
    'Rose 🌹': Icons.favorite_border_rounded,
    'Fern 🌿': Icons.eco_outlined,
  };

  void _showAddPlantDialog() {
    if (_activePlants.length >= 3) return;
    int nextPlantNumber = _activePlants.length + 1;

    showDialog(
      context: context,
      builder: (context) => AddPlantDialog(
        slotNumber: nextPlantNumber, 
        onAdd: (name, date, avatar) {
          setState(() {
            _activePlants.add({
              'name': name,
              'date': date,
              'avatar': avatar,
            });
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
      floatingActionButton: (_selectedSegment == 0 && _activePlants.length < 3)
          ? FloatingActionButton(
              backgroundColor: primaryDarkGreen,
              shape: const CircleBorder(),
              onPressed: _showAddPlantDialog,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Panel
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
          const SizedBox(height: 14),

          // 胶囊切换卡片（Active vs History）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSegment = 0),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedSegment == 0 ? const Color(0xFF497E66) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Active Plants',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _selectedSegment == 0 ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSegment = 1),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedSegment == 1 ? const Color(0xFF497E66) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'History',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _selectedSegment == 1 ? Colors.white : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 动态展示对应内容
          Expanded(
            child: _selectedSegment == 0
                ? (_activePlants.isEmpty ? _buildEmptyPlaceholder() : _buildPlantList(_activePlants, softIvoryWhite, primaryDarkGreen, false))
                : (_historyPlants.isEmpty ? _buildEmptyHistoryPlaceholder() : _buildPlantList(_historyPlants, softIvoryWhite, primaryDarkGreen, true)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Tap the ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35))),
                  Icon(Icons.add_circle, color: Color(0xFF2C4A3E), size: 26),
                  Text(' to add a plant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35))),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '(Maximum 3 active plants can be added)',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'No plant history yet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35)),
              ),
              SizedBox(height: 6),
              Text(
                '(Completed or deleted plants will appear here)',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlantList(List<Map<String, dynamic>> list, Color softIvoryWhite, Color primaryDarkGreen, bool isHistory) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0), 
      itemCount: list.length,
      itemBuilder: (context, index) {
        final plant = list[index];
        final int daysOld = DateTime.now().difference(plant['date']).inDays;
        String formattedTitle = 'Plant: ${plant['name']}';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: softIvoryWhite, 
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(color: Colors.black12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isHistory ? null : () async {
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
                  // 不管是 harvest 还是 delete，都统一安全存入历史列表中
                  if (result['action'] == 'delete' || result['action'] == 'harvest') {
                    final item = list.removeAt(index);
                    _historyPlants.add(item);
                  } else if (result['action'] == 'update') {
                    list[index] = {
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
                    decoration: BoxDecoration(
                      color: isHistory ? Colors.grey.withOpacity(0.15) : const Color(0xFFEAF2E8), 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Icon(_avatarMap[plant['avatar']] ?? Icons.eco, size: 32, color: isHistory ? Colors.black54 : primaryDarkGreen),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formattedTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35))),
                        const SizedBox(height: 4),
                        Text(isHistory ? 'Archived / History' : '$daysOld Days Old', style: TextStyle(fontSize: 12, color: isHistory ? Colors.black54 : Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  if (isHistory)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          _historyPlants.removeAt(index);
                        });
                      },
                    )
                  else
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}