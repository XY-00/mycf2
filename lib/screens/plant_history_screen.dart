import 'package:flutter/material.dart';
import 'history_plant_details_screen.dart';

class PlantHistoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> historyPlants;
  final VoidCallback onRefreshNeeded;

  const PlantHistoryScreen({
    Key? key,
    required this.historyPlants,
    required this.onRefreshNeeded,
  }) : super(key: key);

  @override
  State<PlantHistoryScreen> createState() => _PlantHistoryScreenState();
}

class _PlantHistoryScreenState extends State<PlantHistoryScreen> {
  final Map<String, IconData> _avatarMap = {
    'Sunflower 🌻': Icons.wb_sunny_outlined,
    'Cactus 🌵': Icons.grass_rounded, 
    'Rose 🌹': Icons.favorite_border_rounded,
    'Fern 🌿': Icons.eco_outlined,
  };

  final List<String> _monthNames = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  Widget build(BuildContext context) {
    const Color softIvoryWhite = Color(0xFFF9FBFA);

    if (widget.historyPlants.isEmpty) {
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

    List<Map<String, dynamic>> sortedPlants = List.from(widget.historyPlants);
    sortedPlants.sort((a, b) {
      DateTime timeA = a['archived_at'] ?? DateTime.now();
      DateTime timeB = b['archived_at'] ?? DateTime.now();
      return timeB.compareTo(timeA); 
    });

    Map<int, Map<int, List<Map<String, dynamic>>>> groupedHistory = {};

    for (var plant in sortedPlants) {
      DateTime archivedDate = plant['archived_at'];
      int year = archivedDate.year;
      int month = archivedDate.month;

      groupedHistory.putIfAbsent(year, () => {});
      groupedHistory[year]!.putIfAbsent(month, () => []);
      groupedHistory[year]![month]!.add(plant);
    }

    List<int> sortedYears = groupedHistory.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      children: sortedYears.map((year) {
        var monthsMap = groupedHistory[year]!;
        List<int> sortedMonths = monthsMap.keys.toList()..sort((a, b) => b.compareTo(a));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '$year',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E)),
              ),
            ),
            ...sortedMonths.map((month) {
              List<Map<String, dynamic>> plantsInMonth = monthsMap[month]!;
              String monthName = _monthNames[month];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0, bottom: 8.0),
                    child: Row(
                      children: [
                        Text(
                          monthName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Divider(
                            color: Colors.black12,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...plantsInMonth.map((plant) {
                    String actionType = plant['action_type'];
                    String statusText = actionType == 'complete' ? 'Complete' : 'Delete';
                    Color statusColor = actionType == 'complete' ? Colors.green.shade700 : Colors.redAccent;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: softIvoryWhite, 
                        borderRadius: BorderRadius.circular(16), 
                        border: Border.all(color: Colors.black12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HistoryPlantDetailsScreen(
                                slotIndex: (plant['slot_number'] ?? 1) - 1, 
                                initialName: plant['name'],
                                initialDate: plant['date'],
                                initialAvatar: plant['avatar'],
                                archivedDate: plant['archived_at'], // 传入归档日期以冻结年龄
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.15), 
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: Icon(_avatarMap[plant['avatar']] ?? Icons.eco, size: 32, color: Colors.black54),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plant['name'], 
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E35)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      statusText, 
                                      style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
          ],
        );
      }).toList(),
    );
  }
}