import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MoistureChartCard extends StatefulWidget {
  final int selectedTab;
  final List<int> activeSlots;
  final List<int> trendPlant1;
  final List<int> trendPlant2;
  final List<int> trendPlant3;

  const MoistureChartCard({
    Key? key,
    required this.selectedTab,
    required this.activeSlots,
    required this.trendPlant1,
    required this.trendPlant2,
    required this.trendPlant3,
  }) : super(key: key);

  @override
  State<MoistureChartCard> createState() => _MoistureChartCardState();
}

class _MoistureChartCardState extends State<MoistureChartCard> {
  String _selectedViewMode = 'daily'; // 'daily', 'monthly', 'yearly'
  DateTime _selectedDate = DateTime.now();

  Offset? _touchPosition;

  List<String> _getXLabels() {
    if (_selectedViewMode == 'daily') {
      return List.generate(24, (i) => i.toString().padLeft(2, '0'));
    } else if (_selectedViewMode == 'monthly') {
      int daysInMonth = DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);
      return List.generate(daysInMonth, (i) => '${i + 1}');
    } else {
      return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    }
  }

  List<int> _processDataForMode(List<int> sourceData) {
    if (sourceData.isEmpty) return List.filled(10, 60);
    int targetCount = _getXLabels().length;
    
    if (_selectedViewMode == 'daily') {
      if (sourceData.length >= 24) return sourceData;
      List<int> fullDay = [];
      for (int i = 0; i < 24; i++) {
        double idx = (i / 23.0) * (sourceData.length - 1);
        fullDay.add(sourceData[idx.round().clamp(0, sourceData.length - 1)]);
      }
      return fullDay;
    } else {
      List<int> result = [];
      for (int i = 0; i < targetCount; i++) {
        double idx = (i / (targetCount - 1)) * (sourceData.length - 1);
        result.add(sourceData[idx.round().clamp(0, sourceData.length - 1)]);
      }
      return result;
    }
  }

  Future<void> _selectHistoricalTarget(BuildContext context) async {
    final DateTime now = DateTime.now();

    if (_selectedViewMode == 'yearly') {
      // 👑 只允许选择到今年为止的年份（不出现未来年份）
      final List<int> years = List.generate(7, (i) => now.year - i); // 例如 2026, 2025, 2024, 2023...
      int? selectedYear = await showDialog<int>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Select Year', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
          children: years.map((y) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, y),
            child: Text('$y', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          )).toList(),
        ),
      );
      if (selectedYear != null) {
        // 如果选了今年，确保月份不大於当前月份
        int targetMonth = (_selectedDate.year == selectedYear && _selectedDate.month > now.month) ? now.month : _selectedDate.month;
        int targetDay = _selectedDate.day;
        if (selectedYear == now.year && targetMonth == now.month && targetDay > now.day) {
          targetDay = now.day;
        }
        setState(() => _selectedDate = DateTime(selectedYear, targetMonth, targetDay));
      }
    } else if (_selectedViewMode == 'monthly') {
      // 👑 如果选的是今年，只能选到当前月份及以前；如果是往年，可以选全部 12 个月
      final List<Map<String, dynamic>> allMonths = [
        {'name': 'January', 'val': 1}, {'name': 'February', 'val': 2}, {'name': 'March', 'val': 3},
        {'name': 'April', 'val': 4}, {'name': 'May', 'val': 5}, {'name': 'June', 'val': 6},
        {'name': 'July', 'val': 7}, {'name': 'August', 'val': 8}, {'name': 'September', 'val': 9},
        {'name': 'October', 'val': 10}, {'name': 'November', 'val': 11}, {'name': 'December', 'val': 12},
      ];

      final availableMonths = allMonths.where((m) {
        if (_selectedDate.year == now.year) {
          return (m['val'] as int) <= now.month;
        }
        return true;
      }).toList();

      int? selectedMonth = await showDialog<int>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Select Month', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C4A3E))),
          children: availableMonths.map((m) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, m['val']),
            child: Text(m['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          )).toList(),
        ),
      );
      if (selectedMonth != null) {
        int targetDay = _selectedDate.day;
        int maxDays = DateUtils.getDaysInMonth(_selectedDate.year, selectedMonth);
        if (targetDay > maxDays) targetDay = maxDays;
        if (_selectedDate.year == now.year && selectedMonth == now.month && targetDay > now.day) {
          targetDay = now.day;
        }
        setState(() => _selectedDate = DateTime(_selectedDate.year, selectedMonth, targetDay));
      }
    } else {
      // 👑 Daily 模式：严格限制 lastDate 为今天（DateTime.now()），未来的日期会自动变成灰色无法点击！
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
        firstDate: DateTime(2020, 1, 1),
        lastDate: now, // 绝对不能选未来
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF2C4A3E),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null && picked != _selectedDate) {
        setState(() => _selectedDate = picked);
      }
    }
  }

  String _getTargetDisplayString() {
    if (_selectedViewMode == 'yearly') {
      return '${_selectedDate.year}';
    } else if (_selectedViewMode == 'monthly') {
      List<String> monthNames = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      return '${monthNames[_selectedDate.month]} ${_selectedDate.year}';
    } else {
      return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    }
  }

  Widget _buildModeTab(String label, String modeKey) {
    bool isSelected = _selectedViewMode == modeKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedViewMode = modeKey;
          _touchPosition = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C4A3E) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2C4A3E), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF2C4A3E)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color softIvoryWhite = Color(0xFFF9FBFA);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softIvoryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildModeTab('Daily', 'daily'),
              const SizedBox(width: 6),
              _buildModeTab('Monthly', 'monthly'),
              const SizedBox(width: 6),
              _buildModeTab('Yearly', 'yearly'),
              const Spacer(),
              GestureDetector(
                onTap: () => _selectHistoricalTarget(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month, size: 13, color: Color(0xFF497E66)),
                    const SizedBox(width: 3),
                    Text(
                      _getTargetDisplayString(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF497E66)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Row(
              children: [
                const RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'moisture (%)',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54, fontFamily: 'Roboto'),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return InteractiveViewer(
                              panEnabled: false,
                              scaleEnabled: true,
                              minScale: 1.0,
                              maxScale: 3.5,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  setState(() => _touchPosition = details.localPosition);
                                },
                                onTapDown: (details) {
                                  setState(() => _touchPosition = details.localPosition);
                                },
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                  child: CustomPaint(
                                    painter: MultiPlantTrendPainter(
                                      selectedTab: widget.selectedTab,
                                      activeSlots: widget.activeSlots,
                                      trendPlant1: _processDataForMode(widget.trendPlant1),
                                      trendPlant2: _processDataForMode(widget.trendPlant2),
                                      trendPlant3: _processDataForMode(widget.trendPlant3),
                                      xLabels: _getXLabels(),
                                      touchPosition: _touchPosition,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          _selectedViewMode == 'daily' ? 'time' : (_selectedViewMode == 'monthly' ? 'date' : 'month'),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54, fontFamily: 'Roboto'),
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
    );
  }
}

class MultiPlantTrendPainter extends CustomPainter {
  final int selectedTab;
  final List<int> activeSlots;
  final List<int> trendPlant1;
  final List<int> trendPlant2;
  final List<int> trendPlant3;
  final List<String> xLabels;
  final Offset? touchPosition;

  MultiPlantTrendPainter({
    required this.selectedTab,
    required this.activeSlots,
    required this.trendPlant1,
    required this.trendPlant2,
    required this.trendPlant3,
    required this.xLabels,
    this.touchPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()..color = Colors.black87..strokeWidth = 1.2..style = PaintingStyle.stroke;
    final gridPaint = Paint()..color = Colors.black12..strokeWidth = 0.5..style = PaintingStyle.stroke;
    final dashPaint = Paint()..color = Colors.redAccent..strokeWidth = 1.2..style = PaintingStyle.stroke;
    
    double topPadding = 18.0;
    double leftPadding = 32.0; 
    double rightPadding = 16.0; 
    double bottomPadding = 20.0;
    double chartWidth = size.width - leftPadding - rightPadding; 
    double chartHeight = size.height - bottomPadding - topPadding;
    
    if (chartWidth <= 0 || chartHeight <= 0) return;

    canvas.save();
    canvas.translate(0, topPadding);

    if (selectedTab == 0 && activeSlots.isNotEmpty) {
      double rightEdge = leftPadding + chartWidth;
      int count = activeSlots.length;
      double totalLegendWidth = count * 26.0;
      double legendX = rightEdge - totalLegendWidth;
      double legendY = -14.0;

      for (var slot in activeSlots) {
        Color dotColor = slot == 1 ? const Color(0xFF5CB85C) : (slot == 2 ? Colors.blueAccent : Colors.orangeAccent);
        String label = slot == 1 ? 'P1' : (slot == 2 ? 'P2' : 'P3');

        final dotPaint = Paint()..color = dotColor..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(legendX + 3, legendY + 4), 3, dotPaint);
        
        TextPainter tp = TextPainter(
          text: TextSpan(text: label, style: const TextStyle(color: Colors.black87, fontSize: 9.5, fontWeight: FontWeight.bold, fontFamily: 'Roboto')),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(legendX + 8, legendY - 1));
        
        legendX += 26.0;
      }
    }

    canvas.drawLine(Offset(leftPadding, 0), Offset(leftPadding, chartHeight), axisPaint);
    canvas.drawLine(Offset(leftPadding, chartHeight), Offset(leftPadding + chartWidth, chartHeight), axisPaint);
    
    List<String> yLabels = ['100', '75', '50', '25', '0'];
    for (int i = 0; i < yLabels.length; i++) {
      double yPos = (chartHeight / (yLabels.length - 1)) * i;
      canvas.drawLine(Offset(leftPadding, yPos), Offset(leftPadding + chartWidth, yPos), gridPaint);
      TextPainter(
        text: TextSpan(text: yLabels[i], style: const TextStyle(color: Colors.black54, fontSize: 8, fontFamily: 'Roboto')), 
        textDirection: TextDirection.ltr,
      )..layout()..paint(canvas, Offset(2, yPos - 5));
    }
    
    double y59Pos = chartHeight * (1.0 - 0.59);
    double stepWidth = 5; double stepSpace = 4; double currentX = leftPadding;
    while (currentX < leftPadding + chartWidth) {
      canvas.drawLine(Offset(currentX, y59Pos), Offset(currentX + stepWidth, y59Pos), dashPaint);
      currentX += stepWidth + stepSpace;
    }

    for (int i = 0; i < xLabels.length; i++) {
      double xPos = leftPadding + (chartWidth / (xLabels.length - 1)) * i;
      canvas.drawLine(Offset(xPos, 0), Offset(xPos, chartHeight), gridPaint);
      
      double fontSize = xLabels.length > 20 ? 5.5 : 7.0;
      TextPainter tp = TextPainter(
        text: TextSpan(text: xLabels[i], style: TextStyle(color: Colors.black54, fontSize: fontSize, fontFamily: 'Roboto')), 
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(xPos - (tp.width / 2), chartHeight + 4));
    }

    List<Offset> getPoints(List<int> data) {
      List<Offset> pts = [];
      for (int i = 0; i < data.length; i++) {
        double x = leftPadding + (chartWidth / (data.length - 1)) * i;
        double norm = data[i] / 100.0;
        double y = chartHeight * (1.0 - norm);
        pts.add(Offset(x, y));
      }
      return pts;
    }

    void drawLineWithPoints(List<int> data, Color color) {
      if (data.isEmpty) return;
      List<Offset> pts = getPoints(data);
      final paint = Paint()..color = color..strokeWidth = 1.6..style = PaintingStyle.stroke;
      final path = Path();
      for (int i = 0; i < pts.length; i++) {
        if (i == 0) {
          path.moveTo(pts[i].dx, pts[i].dy);
        } else {
          path.lineTo(pts[i].dx, pts[i].dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    if (selectedTab == 0) {
      if (activeSlots.contains(1)) drawLineWithPoints(trendPlant1, const Color(0xFF5CB85C));
      if (activeSlots.contains(2)) drawLineWithPoints(trendPlant2, Colors.blueAccent);
      if (activeSlots.contains(3)) drawLineWithPoints(trendPlant3, Colors.orangeAccent);
    } else {
      List<int> activeData = selectedTab == 1 ? trendPlant1 : (selectedTab == 2 ? trendPlant2 : trendPlant3);
      Color activeColor = selectedTab == 1 ? const Color(0xFF5CB85C) : (selectedTab == 2 ? Colors.blueAccent : Colors.orangeAccent);
      drawLineWithPoints(activeData, activeColor);
    }

    if (touchPosition != null) {
      Offset adjustedTouch = Offset(touchPosition!.dx, touchPosition!.dy - topPadding);

      List<int> targetData = trendPlant1;
      String plantLabel = 'P1';
      Color dotColor = const Color(0xFF5CB85C);

      if (selectedTab == 1) {
        targetData = trendPlant1;
        plantLabel = 'P1';
        dotColor = const Color(0xFF5CB85C);
      } else if (selectedTab == 2) {
        targetData = trendPlant2;
        plantLabel = 'P2';
        dotColor = Colors.blueAccent;
      } else if (selectedTab == 3) {
        targetData = trendPlant3;
        plantLabel = 'P3';
        dotColor = Colors.orangeAccent;
      } else {
        targetData = trendPlant1;
        plantLabel = 'P1';
        dotColor = const Color(0xFF5CB85C);
      }

      List<Offset> pts = getPoints(targetData);

      if (pts.isNotEmpty) {
        Offset closestPoint = pts.reduce((a, b) => 
          (a.dx - adjustedTouch.dx).abs() < (b.dx - adjustedTouch.dx).abs() ? a : b
        );

        int closestIdx = pts.indexOf(closestPoint);
        int moistureVal = targetData[closestIdx];
        String labelStr = xLabels[closestIdx.clamp(0, xLabels.length - 1)];

        final linePaint = Paint()..color = Colors.black54..strokeWidth = 1..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(closestPoint.dx, 0), Offset(closestPoint.dx, chartHeight), linePaint);

        final dotPaint = Paint()..color = dotColor..style = PaintingStyle.fill;
        canvas.drawCircle(closestPoint, 5.0, dotPaint);
        canvas.drawCircle(closestPoint, 5.0, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);

        String tooltipStr = '$plantLabel | $labelStr: $moistureVal%';
        TextPainter tooltipTp = TextPainter(
          text: TextSpan(text: tooltipStr, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Roboto')),
          textDirection: TextDirection.ltr,
        )..layout();

        double boxWidth = tooltipTp.width + 10;
        double boxHeight = tooltipTp.height + 6;
        double boxX = (closestPoint.dx - boxWidth / 2).clamp(leftPadding, leftPadding + chartWidth - boxWidth);
        double boxY = (closestPoint.dy - boxHeight - 8).clamp(0.0, chartHeight - boxHeight);

        RRect rrect = RRect.fromRectAndRadius(Rect.fromLTWH(boxX, boxY, boxWidth, boxHeight), const Radius.circular(4));
        canvas.drawRRect(rrect, Paint()..color = Colors.black87);
        tooltipTp.paint(canvas, Offset(boxX + 5, boxY + 3));
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MultiPlantTrendPainter oldDelegate) => true;
}