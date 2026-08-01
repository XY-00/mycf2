import 'dart:io';
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

    // 1. 按归档时间 (archived_at) 从新到旧排序
    List<Map<String, dynamic>> sortedPlants = List.from(widget.historyPlants);
    sortedPlants.sort((a, b) {
      DateTime timeA = a['archived_at'] ?? DateTime.now();
      DateTime timeB = b['archived_at'] ?? DateTime.now();
      return timeB.compareTo(timeA); 
    });

    // 2. 👑 核心修改：按“具体的归档年月日 (Year -> Month -> Day)”进行多级分组
    // 结构: Map<Year, Map<Month, Map<Day, List<Plant>>>>
    Map<int, Map<int, Map<int, List<Map<String, dynamic>>>>> groupedHistory = {};

    for (var plant in sortedPlants) {
      DateTime archivedDate = plant['archived_at'] ?? DateTime.now();
      int year = archivedDate.year;
      int month = archivedDate.month;
      int day = archivedDate.day;

      groupedHistory.putIfAbsent(year, () => {});
      groupedHistory[year]!.putIfAbsent(month, () => {});
      groupedHistory[year]![month]!.putIfAbsent(day, () => []);
      groupedHistory[year]![month]![day]!.add(plant);
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
            // 年份标题
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '$year',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E)),
              ),
            ),
            ...sortedMonths.map((month) {
              var daysMap = monthsMap[month]!;
              List<int> sortedDays = daysMap.keys.toList()..sort((a, b) => b.compareTo(a));
              String monthName = _monthNames[month];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 遍历该月份下的每一个具体归档日期（例如：3 July、15 July）
                  ...sortedDays.map((day) {
                    List<Map<String, dynamic>> plantsOnDay = daysMap[day]!;
                    String dateHeaderString = '$day $monthName $year';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 日期分界线标题
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          child: Row(
                            children: [
                              Text(
                                dateHeaderString,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF497E66)),
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
                        // 该日期下归档的植物列表
                        ...plantsOnDay.map((plant) {
                          String actionType = plant['action_type'];
                          String statusText = actionType == 'complete' ? 'Complete' : 'Delete';
                          Color statusColor = actionType == 'complete' ? Colors.green.shade700 : Colors.redAccent;
                          
                          String avatarStr = plant['avatar'] ?? '🌱';
                          bool isLocalFile = avatarStr.startsWith('/') || avatarStr.startsWith('file://');
                          bool fileExists = isLocalFile && File(avatarStr).existsSync();

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
                                      archivedDate: plant['archived_at'],
                                    ),
                                  ),
                                );
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
                                      ),
                                      child: Center(
                                        child: Text(
                                          isLocalFile ? '🌱' : avatarStr,
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                      ),
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
          ],
        );
      }).toList(),
    );
  }
}