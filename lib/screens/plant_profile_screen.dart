import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_plant_screen.dart'; 
import 'active_plant_details_screen.dart';
import 'plant_history_screen.dart';

class PlantProfileScreen extends StatefulWidget {
  const PlantProfileScreen({Key? key}) : super(key: key);

  @override
  State<PlantProfileScreen> createState() => _PlantProfileScreenState();
}

class _PlantProfileScreenState extends State<PlantProfileScreen> with AutomaticKeepAliveClientMixin {
  int _selectedSegment = 0; 

  List<Map<String, dynamic>> _activePlants = [];
  List<Map<String, dynamic>> _historyPlants = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchPlantsFromSupabase();
  }

  Future<void> _fetchPlantsFromSupabase() async {
    try {
      final activeResponse = await Supabase.instance.client
          .from('plants')
          .select()
          .eq('status', 'active')
          .order('slot_number', ascending: true);

      final historyResponse = await Supabase.instance.client
          .from('plants')
          .select()
          .eq('status', 'history')
          .order('archived_at', ascending: false);

      final List<Map<String, dynamic>> active = [];
      for (var item in activeResponse) {
        active.add({
          'id': item['id'],
          'slot_number': item['slot_number'] ?? 1,
          'name': item['name'],
          'date': DateTime.parse(item['planted_date']),
          'avatar': item['avatar'],
        });
      }

      final List<Map<String, dynamic>> history = [];
      for (var item in historyResponse) {
        history.insert(0, {
          'id': item['id'],
          'slot_number': item['slot_number'] ?? 1,
          'name': item['name'],
          'date': DateTime.parse(item['planted_date']),
          'avatar': item['avatar'],
          'action_type': item['action_type'] ?? 'complete',
          'archived_at': item['archived_at'] != null ? DateTime.parse(item['archived_at']) : DateTime.now(),
        });
      }

      history.sort((a, b) {
        DateTime timeA = a['archived_at'];
        DateTime timeB = b['archived_at'];
        return timeB.compareTo(timeA);
      });

      setState(() {
        _activePlants = active;
        _historyPlants = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching plants: $e');
    }
  }

  int _getNextAvailableSlot() {
    List<int> occupiedSlots = _activePlants.map((p) => p['slot_number'] as int).toList();
    for (int i = 1; i <= 3; i++) {
      if (!occupiedSlots.contains(i)) {
        return i; 
      }
    }
    return 1;
  }

  void _navigateToAddPlant() {
    if (_activePlants.length >= 3) return;
    
    int availableSlot = _getNextAvailableSlot();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPlantScreen(
          slotNumber: availableSlot, 
          onAdd: (name, date, avatar) async {
            try {
              await Supabase.instance.client.from('plants').insert({
                'slot_number': availableSlot,
                'name': name,
                'planted_date': date.toIso8601String(),
                'avatar': avatar,
                'status': 'active',
              });
              _fetchPlantsFromSupabase();
            } catch (e) {
              print('Error adding plant: $e');
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    const Color primaryDarkGreen = Color(0xFF2C4A3E); 
    const Color softIvoryWhite = Color(0xFFF9FBFA); 

    return Scaffold(
      backgroundColor: Colors.transparent,
      // 👑 关键：设置为 false，防止键盘弹起时挤压或移动整个 Scaffold 背景
      resizeToAvoidBottomInset: false,
      floatingActionButton: (_selectedSegment == 0 && _activePlants.length < 3)
          ? FloatingActionButton(
              backgroundColor: primaryDarkGreen,
              shape: const CircleBorder(),
              onPressed: _navigateToAddPlant,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      body: Stack(
        children: [
          // 👑 背景图固定在底层，不随键盘移动
          Positioned.fill(
            child: Image.asset(
              'assets/app_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.78)),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryDarkGreen))
              : Column(
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
                    const SizedBox(height: 14),
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
                    Expanded(
                      child: _selectedSegment == 0
                          ? (_activePlants.isEmpty ? _buildEmptyPlaceholder() : _buildActivePlantList(softIvoryWhite, primaryDarkGreen))
                          : PlantHistoryScreen(
                              historyPlants: _historyPlants,
                              onRefreshNeeded: _fetchPlantsFromSupabase,
                            ),
                    ),
                  ],
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

  Widget _buildActivePlantList(Color softIvoryWhite, Color primaryDarkGreen) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0), 
      itemCount: _activePlants.length,
      itemBuilder: (context, index) {
        final plant = _activePlants[index];
        final int daysOld = DateTime.now().difference(plant['date']).inDays;
        int slotNum = plant['slot_number'] ?? 1;
        String formattedTitle = 'Plant $slotNum: ${plant['name']}';
        String avatarStr = plant['avatar'] ?? '';
        bool isLocalFile = avatarStr.startsWith('/') || avatarStr.startsWith('file://');

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
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActivePlantDetailsScreen(
                    slotIndex: slotNum - 1, 
                    initialName: plant['name'],
                    initialDate: plant['date'],
                    initialAvatar: plant['avatar'],
                  ),
                ),
              );
              
              if (result != null) {
                String action = result['action'];
                if (action == 'harvest') {
                  action = 'complete';
                }

                if (action == 'delete' || action == 'complete') {
                  await Supabase.instance.client
                      .from('plants')
                      .update({
                        'status': 'history',
                        'action_type': action, 
                        'archived_at': DateTime.now().toIso8601String(),
                      })
                      .eq('id', plant['id']);
                  _fetchPlantsFromSupabase();
                } else if (action == 'update') {
                  await Supabase.instance.client
                      .from('plants')
                      .update({
                        'name': result['name'],
                        'planted_date': result['date'].toIso8601String(),
                        'avatar': result['avatar'],
                      })
                      .eq('id', plant['id']);
                  _fetchPlantsFromSupabase();
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2E8), 
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12),
                      image: isLocalFile
                          ? DecorationImage(image: FileImage(File(avatarStr)), fit: BoxFit.cover)
                          : null,
                    ),
                    child: !isLocalFile
                        ? Center(child: Text(avatarStr.contains('🌻') ? '🌻' : '🌿', style: const TextStyle(fontSize: 22)))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formattedTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35))),
                        const SizedBox(height: 4),
                        Text('$daysOld Days Old', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
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
    );
  }
}