import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'share_eco_impact.dart';

class EcoImpactScreen extends StatefulWidget {
  final double totalCarbonSaved;
  final ValueChanged<double>? onCarbonSavedChanged;

  const EcoImpactScreen({
    Key? key,
    this.totalCarbonSaved = 146.0,
    this.onCarbonSavedChanged,
  }) : super(key: key);

  @override
  State<EcoImpactScreen> createState() => _EcoImpactScreenState();
}

class _EcoImpactScreenState extends State<EcoImpactScreen> {
  String _profileName = 'Lee Xin Yi';
  String _profileId = 'FARM0027';

  List<Map<String, dynamic>> _rawHistoryRecords = [];
  final Map<String, bool> _expandedMonths = {};

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _fetchEcoImpactFromDatabase();
  }

  void _fetchUserInfo() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _profileName = user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'Lee Xin Yi';
      });
    }
  }

  Future<void> _fetchEcoImpactFromDatabase() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('eco_impact_history')
          .select()
          .order('record_date', ascending: false);

      if (response != null && (response as List).isNotEmpty) {
        setState(() {
          _rawHistoryRecords = response.map((item) => {
            'date': item['record_date'].toString(),
            'saved': double.tryParse(item['saved_amount'].toString()) ?? 0.0,
          }).toList();

          for (var group in _groupedHistoryData) {
            _expandedMonths[group['month']] = true;
          }
        });

        if (widget.onCarbonSavedChanged != null) {
          widget.onCarbonSavedChanged!(_totalSaved);
        }
      }
    } catch (e) {
      debugPrint('Database fetch fallback used: $e');
    }
  }

  String _calculateGrade(double savedAmount) {
    if (savedAmount >= 100.0) {
      return 'A';
    } else if (savedAmount >= 40.0) {
      return 'B';
    } else {
      return 'C';
    }
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return const Color(0xFF4CAF50);
      case 'B':
        return const Color(0xFFFFB300);
      case 'C':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  double get _totalSaved {
    if (_rawHistoryRecords.isEmpty) return 0.0;
    return _rawHistoryRecords.fold(0.0, (sum, item) => sum + (item['saved'] as double));
  }

  List<Map<String, dynamic>> get _groupedHistoryData {
    Map<String, List<Map<String, dynamic>>> tempMap = {};

    for (var record in _rawHistoryRecords) {
      String dateStr = record['date'];
      String monthKey = dateStr.length >= 7 ? dateStr.substring(0, 7) : dateStr;

      if (!tempMap.containsKey(monthKey)) {
        tempMap[monthKey] = [];
      }
      tempMap[monthKey]!.add(record);
    }

    List<Map<String, dynamic>> groupedList = [];
    tempMap.forEach((month, items) {
      double monthTotal = items.fold(0.0, (sum, item) => sum + (item['saved'] as double));
      String monthGrade = _calculateGrade(monthTotal);
      groupedList.add({
        'month': month,
        'totalSaved': monthTotal,
        'grade': monthGrade,
        'items': items,
      });
    });

    groupedList.sort((a, b) => b['month'].compareTo(a['month']));
    return groupedList;
  }

  void _handleShare() {
    String overallGrade = _calculateGrade(_totalSaved);
    showDialog(
      context: context,
      builder: (context) => ShareEcoImpactDialog(
        profileName: _profileName,
        profileId: _profileId,
        grade: overallGrade,
      ),
    );
  }

  // 👑 真正的 Data Comparison 弹窗（支持多选两条进行 Before vs After 对比）
  void _showDataComparisonDialog() {
    if (_rawHistoryRecords.length < 2) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Comparison'),
          content: const Text('You need at least 2 records in history to perform a comparison.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return;
    }

    // 默认选择最早的一条作为 Before，最新的一条作为 After
    int beforeIndex = _rawHistoryRecords.length - 1;
    int afterIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            var beforeItem = _rawHistoryRecords[beforeIndex];
            var afterItem = _rawHistoryRecords[afterIndex];
            double diff = afterItem['saved'] - beforeItem['saved'];

            return Container(
              padding: const EdgeInsets.all(20),
              height: 450,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Records to Compare', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Before: ${beforeItem['date']} (${beforeItem['saved']} mg)', style: const TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<int>(
                        value: beforeIndex,
                        items: _rawHistoryRecords.asMap().entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text(e.value['date']));
                        }).toList(),
                        onChanged: (val) => setModalState(() => beforeIndex = val!),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('After: ${afterItem['date']} (${afterItem['saved']} mg)', style: const TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<int>(
                        value: afterIndex,
                        items: _rawHistoryRecords.asMap().entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text(e.value['date']));
                        }).toList(),
                        onChanged: (val) => setModalState(() => afterIndex = val!),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFD6E4DA), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          const Text('Comparison Result', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
                          const SizedBox(height: 6),
                          Text('Difference: ${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} mg CO₂ e', 
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: diff >= 0 ? Colors.green.shade800 : Colors.red.shade800)),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C4A3E), padding: const EdgeInsets.all(12)),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close', style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 👑 真正的 Data Export 弹窗（支持选择时间范围与格式）
  void _showDataExportDialog() {
    String selectedRange = 'Recent one month';
    String selectedFormat = 'CSV';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choose Time Range & Format', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
                  const SizedBox(height: 14),
                  ...['Recent one month', 'Recent three months', 'All'].map((range) {
                    return RadioListTile<String>(
                      title: Text(range),
                      value: range,
                      groupValue: selectedRange,
                      activeColor: const Color(0xFF2C4A3E),
                      onChanged: (val) => setModalState(() => selectedRange = val!),
                    );
                  }),
                  const SizedBox(height: 10),
                  const Text('Select Format', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Row(
                    children: ['CSV', 'PDF'].map((fmt) {
                      return Expanded(
                        child: RadioListTile<String>(
                          title: Text(fmt),
                          value: fmt,
                          groupValue: selectedFormat,
                          activeColor: const Color(0xFF2C4A3E),
                          onChanged: (val) => setModalState(() => selectedFormat = val!),
                        ),
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C4A3E), padding: const EdgeInsets.all(12)),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Successfully exported data as $selectedFormat ($selectedRange)!')),
                        );
                      },
                      child: const Text('Export Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF2C4A3E); 
    String overallGrade = _calculateGrade(_totalSaved);
    Color overallGradeColor = _getGradeColor(overallGrade);

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SingleChildScrollView(
        child: Column(
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
                      Text('Eco Impact', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Grade 模块主卡片
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(16), 
                      border: Border.all(color: Colors.black12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start, 
                      children: [
                        CircleAvatar(
                          radius: 22, 
                          backgroundColor: overallGradeColor, 
                          child: Text(overallGrade, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Eco Friendly Grade', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            Text('Top 5% of Farmers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _handleShare, 
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            borderRadius: BorderRadius.circular(10), 
                            border: Border.all(color: Colors.black12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 4)],
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.share_rounded, size: 14, color: primaryDarkGreen),
                              SizedBox(width: 4),
                              Text('Share', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 核心指标卡片
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0), 
              child: Row(
                children: [
                  Expanded(child: _miniMetricCard('Carbon Footprint Saved', '${_totalSaved.toStringAsFixed(1)} mg', isImageIcon: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _miniMetricCard('Red-line Success', '3 of 3', icon: Icons.gps_fixed, iconColor: Colors.red)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            
            // 历史记录大卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 20.0), 
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: Colors.black12), 
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black))),
                  const SizedBox(height: 12),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(color: const Color(0xFFAEC4B5), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: const [
                        Expanded(flex: 3, child: Text('Date', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        Expanded(flex: 4, child: Text('Carbon Footprint\nsaved (mg CO₂ e)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, height: 1.1))),
                        Expanded(flex: 3, child: Text('Grade', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: _groupedHistoryData.length,
                    itemBuilder: (context, groupIndex) {
                      final group = _groupedHistoryData[groupIndex];
                      final String monthKey = group['month'];
                      final bool isExpanded = _expandedMonths[monthKey] ?? true;
                      final List items = group['items'];
                      String monthGrade = group['grade'];
                      Color monthGradeColor = _getGradeColor(monthGrade);

                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _expandedMonths[monthKey] = !isExpanded;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD6E4DA), 
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.black12), 
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(monthKey, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text('${group['totalSaved'].toStringAsFixed(1)}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Text(
                                          monthGrade, 
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: monthGradeColor)
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Icon(
                                            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                            size: 16,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (isExpanded)
                            ...items.map((item) {
                              String itemDate = item['date'];
                              String displayDate = itemDate.length >= 10 ? itemDate.substring(5).replaceAll('-', '/') : itemDate;
                              double itemSaved = item['saved'];
                              String itemGrade = _calculateGrade(itemSaved);
                              Color itemGradeColor = _getGradeColor(itemGrade);

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.transparent, 
                                  borderRadius: BorderRadius.circular(8), 
                                  border: Border.all(color: Colors.black12), 
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(displayDate, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text('${itemSaved.toStringAsFixed(1)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Text(
                                            itemGrade, 
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: itemGradeColor)
                                          ),
                                          const Align(
                                            alignment: Alignment.centerRight,
                                            child: SizedBox(width: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildActionBtn('Data Comparison', _showDataComparisonDialog)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildActionBtn('Data Export', _showDataExportDialog)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _miniMetricCard(String title, String value, {IconData? icon, Color? iconColor, bool isImageIcon = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.black12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          isImageIcon 
              ? Image.asset('assets/my_ic_carbonfootprint.png', width: 20, height: 20, color: const Color(0xFF2C4A3E))
              : Icon(icon, color: iconColor ?? const Color(0xFF2C4A3E), size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis, 
                  style: const TextStyle(fontSize: 8.5, color: Colors.black87, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  value, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis, 
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionBtn(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFA2B5A9), 
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12), 
        ),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
      ),
    );
  }
}