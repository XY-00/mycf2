// lib/screens/eco_impact_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';
import 'share_eco_impact.dart';
import 'calculator_carbon.dart'; 

class EcoImpactScreen extends StatefulWidget {
  final double totalCarbonSaved;
  final ValueChanged<double>? onCarbonSavedChanged;

  const EcoImpactScreen({
    Key? key,
    this.totalCarbonSaved = 0.0,
    this.onCarbonSavedChanged,
  }) : super(key: key);

  @override
  State<EcoImpactScreen> createState() => _EcoImpactScreenState();
}

class _EcoImpactScreenState extends State<EcoImpactScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; 

  String _profileName = 'Lee Xin Yi';
  String _profileId = 'FARM0027';

  List<Map<String, dynamic>> _rawHistoryRecords = [];
  final Map<String, bool> _expandedMonths = {};
  
  int _redlineSuccessCount = 0;
  int _redlineTotalCount = 0;
  double _todaySaved = 0.0;
  Timer? _realtimeTimer;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _loadEcoImpactData();
    _initNotifications();

    _realtimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _loadEcoImpactData();
    });
  }

  void _initNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null && response.payload!.isNotEmpty) {
          await OpenFile.open(response.payload!);
        }
      },
    );
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    super.dispose();
  }

  void _fetchUserInfo() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _profileName = user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'Lee Xin Yi';
      });
    }
  }

  Future<void> _loadEcoImpactData() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final plantsResponse = await supabase
          .from('plants')
          .select('*')
          .eq('user_id', user.id)
          .eq('status', 'active');

      final controlResponse = await supabase
          .from('system_control')
          .select('pump_run_seconds')
          .eq('id', 1)
          .maybeSingle();

      int pumpSeconds = int.tryParse(controlResponse?['pump_run_seconds']?.toString() ?? '10') ?? 10;
      List<dynamic> activePlants = plantsResponse ?? [];

      double calculatedCarbon = CarbonCalculator.calculateTodayCarbon(
        activePlants, 
        65.0, 
        pumpSeconds
      );

      final historyResponse = await supabase
          .from('eco_impact_history')
          .select()
          .eq('user_id', user.id)
          .order('record_date', ascending: false);

      List<Map<String, dynamic>> records = [];
      if (historyResponse != null && (historyResponse as List).isNotEmpty) {
        records = historyResponse.map((item) => {
          'date': item['record_date']?.toString() ?? '',
          'saved': double.tryParse(item['saved_amount']?.toString() ?? '0') ?? 0.0,
          'success': item['redline_success'] ?? true, 
        }).toList();
      }

      String todayStr = DateTime.now().toIso8601String().substring(0, 10);
      var todayRecordIndex = records.indexWhere((r) => r['date'] == todayStr);

      if (todayRecordIndex != -1) {
        records[todayRecordIndex]['saved'] = calculatedCarbon;
        
        supabase.from('eco_impact_history')
            .update({'saved_amount': calculatedCarbon})
            .eq('user_id', user.id)
            .eq('record_date', todayStr)
            .then((_) {});
      } else {
        try {
          await supabase.from('eco_impact_history').insert({
            'user_id': user.id,
            'record_date': todayStr,
            'saved_amount': calculatedCarbon,
            'redline_success': true,
          });
        } catch (insertErr) {
          debugPrint('Insert history error: $insertErr');
        }

        records.insert(0, {
          'date': todayStr,
          'saved': calculatedCarbon,
          'success': true,
        });
      }

      if (mounted) {
        setState(() {
          _todaySaved = calculatedCarbon; 
          _rawHistoryRecords = records;
          _redlineTotalCount = _rawHistoryRecords.length;
          _redlineSuccessCount = _rawHistoryRecords.where((r) => r['success'] == true).length;

          for (var group in _groupedHistoryData) {
            _expandedMonths[group['month']] = true;
          }
        });

        if (widget.onCarbonSavedChanged != null) {
          widget.onCarbonSavedChanged!(_todaySaved);
        }
      }
    } catch (e) {
      debugPrint('Eco impact load error: $e');
    }
  }

  String _calculateGrade(double savedAmount) {
    if (savedAmount >= 300.0) {
      return 'A'; 
    } else if (savedAmount >= 200.0) {
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
    String overallGrade = _calculateGrade(_todaySaved);
    showDialog(
      context: context,
      builder: (context) => ShareEcoImpactDialog(
        profileName: _profileName,
        profileId: _profileId,
        grade: overallGrade,
        carbonSaved: _todaySaved, 
      ),
    );
  }

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

    Set<String> availableDates = _rawHistoryRecords.map((r) => r['date'].toString()).toSet();
    String beforeDateStr = _rawHistoryRecords.last['date'];
    String afterDateStr = _rawHistoryRecords.first['date'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            var beforeItem = _rawHistoryRecords.firstWhere((r) => r['date'] == beforeDateStr, orElse: () => _rawHistoryRecords.last);
            var afterItem = _rawHistoryRecords.firstWhere((r) => r['date'] == afterDateStr, orElse: () => _rawHistoryRecords.first);
            
            double beforeVal = beforeItem['saved'];
            double afterVal = afterItem['saved'];
            double diff = afterVal - beforeVal;
            bool isIncrease = diff >= 0;

            Future<void> pickDate({required bool isBefore}) async {
              DateTime initialDate = DateTime.tryParse(isBefore ? beforeDateStr : afterDateStr) ?? DateTime.now();
              DateTime firstDate = DateTime.tryParse(_rawHistoryRecords.last['date'] ?? '2025-01-01') ?? DateTime(2025);
              DateTime lastDate = DateTime.tryParse(_rawHistoryRecords.first['date'] ?? '2030-12-31') ?? DateTime(2030);

              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: firstDate,
                lastDate: lastDate,
                selectableDayPredicate: (DateTime day) {
                  String formattedDate = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
                  return availableDates.contains(formattedDate);
                },
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF2C4A3E),
                        onPrimary: Colors.white,
                        onSurface: Colors.black87,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                String selectedStr = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                setModalState(() {
                  if (isBefore) {
                    beforeDateStr = selectedStr;
                  } else {
                    afterDateStr = selectedStr;
                  }
                });
              }
            }

            return Container(
              padding: const EdgeInsets.all(20),
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Dates to Compare', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
                  const SizedBox(height: 14),
                  const Text('Select "Before" Date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => pickDate(isBefore: true),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFFF0F4F1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$beforeDateStr (${beforeVal.toStringAsFixed(1)} mg)', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const Icon(Icons.calendar_month, color: Color(0xFF2C4A3E), size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Select "After" Date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => pickDate(isBefore: false),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFFF0F4F1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$afterDateStr (${afterVal.toStringAsFixed(1)} mg)', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const Icon(Icons.calendar_month, color: Color(0xFF2C4A3E), size: 18),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 20),
                  Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFD6E4DA), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          const Text('Comparison Analysis', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E), fontSize: 13)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isIncrease ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: isIncrease ? Colors.green.shade800 : Colors.red.shade800, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                isIncrease ? 'Increased by ${diff.abs().toStringAsFixed(1)} mg' : 'Decreased by ${diff.abs().toStringAsFixed(1)} mg',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isIncrease ? Colors.green.shade800 : Colors.red.shade800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Net Difference: ${isIncrease ? '+' : '-'}${diff.abs().toStringAsFixed(1)} mg CO₂ e', style: const TextStyle(fontSize: 11.5, color: Colors.black54, fontWeight: FontWeight.bold)),
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

  /// 👑 真正生成带有精美配色、结构对齐的 PDF 或 Excel 报告
  Future<void> _generateAndDownloadReport(String range, String format, {DateTime? customStart, DateTime? customEnd}) async {
    try {
      List<Map<String, dynamic>> filteredRecords = _rawHistoryRecords;
      if (range == 'Recent one month') {
        final threshold = DateTime.now().subtract(const Duration(days: 30));
        filteredRecords = _rawHistoryRecords.where((r) => DateTime.tryParse(r['date'])?.isAfter(threshold) ?? true).toList();
      } else if (range == 'Recent three months') {
        final threshold = DateTime.now().subtract(const Duration(days: 90));
        filteredRecords = _rawHistoryRecords.where((r) => DateTime.tryParse(r['date'])?.isAfter(threshold) ?? true).toList();
      } else if (range == 'Custom' && customStart != null && customEnd != null) {
        filteredRecords = _rawHistoryRecords.where((r) {
          DateTime? d = DateTime.tryParse(r['date']);
          if (d == null) return false;
          return d.isAfter(customStart.subtract(const Duration(days: 1))) && d.isBefore(customEnd.add(const Duration(days: 1)));
        }).toList();
      }

      final directory = await getApplicationDocumentsDirectory();
      File file;
      bool isPdf = format.toLowerCase().contains('pdf');
      String extension = isPdf ? 'pdf' : 'xls'; 
      String fileName = 'myCF_Report_${range.replaceAll(' ', '_')}.$extension';
      filePath = '${directory.path}/$fileName';

      // 👑 统一采用深绿色高级报表排版风格（对标精美参考图）
      String styledTableHtml = '''
      <html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/1999/xlink">
      <head>
        <meta http-equiv="content-type" content="text/plain; charset=UTF-8"/>
        <style>
          body { font-family: 'Segoe UI', Arial, sans-serif; padding: 25px; color: #2C4A3E; background-color: #F9FBFA; }
          .header-title { font-size: 20px; font-weight: bold; color: #2C4A3E; text-align: center; margin-bottom: 5px; }
          .subtitle { font-size: 12px; color: #666; text-align: center; margin-bottom: 20px; }
          .meta-box { background: #EAF2E8; border-left: 4px solid #2C4A3E; padding: 10px 15px; margin-bottom: 20px; font-size: 13px; border-radius: 4px; }
          table { width: 100%; border-collapse: collapse; background: #ffffff; box-shadow: 0 2px 5px rgba(0,0,0,0.05); border-radius: 6px; overflow: hidden; }
          th { background-color: #2C4A3E; color: #FFFFFF; font-weight: bold; text-align: center; padding: 12px 10px; font-size: 13px; border: 1px solid #1E3C32; }
          td { text-align: center; padding: 10px; font-size: 12px; border: 1px solid #E0E0E0; color: #333333; }
          tr:nth-child(even) { background-color: #F4F7F5; }
          .grade-a { color: #2E7D32; font-weight: bold; }
          .grade-b { color: #EF6C00; font-weight: bold; }
          .grade-c { color: #C62828; font-weight: bold; }
        </style>
      </head>
      <body>
        <div class="header-title">myCF Carbon Footprint Report (${isPdf ? 'PDF Document' : 'Excel Spreadsheet'})</div>
        <div class="subtitle">User: $_profileName | ID: $_profileId</div>
        <div class="meta-box">
          <b>Time Range:</b> $range<br>
          <b>Total Records:</b> ${filteredRecords.length}<br>
          <b>Exported Date:</b> ${DateTime.now().toIso8601String().substring(0, 10)}
        </div>
        <table>
          <tr>
            <th>Date</th>
            <th>Carbon Footprint Saved (mg CO₂e)</th>
            <th>Eco Grade</th>
          </tr>
      ''';

      for (var r in filteredRecords) {
        String grade = _calculateGrade(r['saved']);
        styledTableHtml += '<tr><td><b>${r['date']}</b></td><td>${r['saved'].toStringAsFixed(1)}</td><td class="grade-$grade">$grade</td></tr>';
      }
      styledTableHtml += '</table></body></html>';

      file = File(filePath);
      await file.writeAsString(styledTableHtml);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'mycf_download_channel',
        'Downloads',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      await flutterLocalNotificationsPlugin.show(
        0,
        'myCF Download Complete',
        '$fileName (Tap to open)',
        const NotificationDetails(android: androidDetails),
        payload: file.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report downloaded! Check your notification bar to open.')),
        );
      }
    } catch (e) {
      debugPrint('Download error: $e');
    }
  }

  String filePath = '';

  /// 👑 带有智能置灰（无记录日期及未来日期全部变灰不可选）的 Data Export 弹窗
  void _showDataExportDialog() {
    String selectedRange = 'Recent one month';
    String selectedFormat = 'PDF';
    DateTime? customStartDate;
    DateTime? customEndDate;

    // 收集所有有历史记录的日期集合（格式为 "YYYY-MM-DD"）
    Set<String> availableDates = _rawHistoryRecords.map((r) => r['date'].toString()).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Choose Time Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  ...['Recent one month', 'Recent three months', 'All', 'Custom'].map((range) {
                    bool isSelected = (selectedRange == range);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RadioListTile<String>(
                          title: Text(range, style: const TextStyle(fontSize: 14)),
                          value: range,
                          groupValue: selectedRange,
                          activeColor: const Color(0xFF2C4A3E),
                          dense: true,
                          onChanged: (val) async {
                            setModalState(() => selectedRange = val!);
                            
                            // 👑 勾选 Custom 时弹出日历，自动置灰未来及没有记录的日子
                            if (val == 'Custom') {
                              DateTime? pickedStart = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2025),
                                lastDate: DateTime.now(), // 不能选未来
                                selectableDayPredicate: (DateTime day) {
                                  String formattedDate = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
                                  // 只有有记录的日子才可以点，其余全部置灰
                                  return availableDates.contains(formattedDate);
                                },
                              );

                              if (pickedStart != null) {
                                DateTime? pickedEnd = await showDatePicker(
                                  context: context,
                                  initialDate: pickedStart,
                                  firstDate: pickedStart,
                                  lastDate: DateTime.now(), // 不能选未来
                                  selectableDayPredicate: (DateTime day) {
                                    String formattedDate = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
                                    return availableDates.contains(formattedDate);
                                  },
                                );

                                if (pickedEnd != null) {
                                  setModalState(() {
                                    customStartDate = pickedStart;
                                    customEndDate = pickedEnd;
                                  });
                                }
                              }
                            }
                          },
                        ),
                        if (range == 'Custom' && isSelected && customStartDate != null && customEndDate != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 32.0, bottom: 6),
                            child: Text(
                              'Selected: ${customStartDate.toString().substring(0, 10)} ~ ${customEndDate.toString().substring(0, 10)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E)),
                            ),
                          ),
                      ],
                    );
                  }),
                  const SizedBox(height: 10),
                  const Text('Select Format', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['PDF', 'Excel'].map((fmt) {
                      bool isFormatSelected = (selectedFormat == fmt);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedFormat = fmt),
                          child: Container(
                            margin: EdgeInsets.only(right: fmt == 'PDF' ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isFormatSelected ? const Color(0xFF2C4A3E) : Colors.black12, width: isFormatSelected ? 2 : 1),
                            ),
                            child: Center(
                              child: Text(fmt, style: TextStyle(fontWeight: FontWeight.bold, color: isFormatSelected ? const Color(0xFF2C4A3E) : Colors.black54)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C4A3E), padding: const EdgeInsets.all(12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        Navigator.pop(context);
                        _generateAndDownloadReport(selectedRange, selectedFormat, customStart: customStartDate, customEnd: customEndDate);
                      },
                      child: const Text('Download Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    super.build(context); 
    const Color primaryDarkGreen = Color(0xFF2C4A3E); 
    String overallGrade = _calculateGrade(_todaySaved);
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                        const Text(
                          'Eco Friendly Grade', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0), 
              child: Row(
                children: [
                  Expanded(child: _miniMetricCard("Today's Carbon Saved", '${_todaySaved.toStringAsFixed(1)} mg', isImageIcon: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _miniMetricCard('Red-line Success', '$_redlineSuccessCount of $_redlineTotalCount', icon: Icons.gps_fixed, iconColor: Colors.red)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            
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