// lib/screens/moisture_chart_card.dart
import 'package:flutter/material.dart';

class MoistureChartCard extends StatefulWidget {
  final int selectedTab; // 0: All Plants, 1: Plant 1, 2: Plant 2, 3: Plant 3
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

  // 👑 核心：Monthly 和 Yearly 只在当前选中的日期/月份上赋值，其余保持 0，从而实现从 0 向上拉起
  List<int> _processDataForMode(List<int> sourceData) {
    if (sourceData.isEmpty) return [];
    int targetCount = _getXLabels().length;
    
    if (_selectedViewMode == 'daily') {
      if (sourceData.length >= 24) return sourceData;
      List<int> fullDay = List.filled(24, 0);
      for (int i = 0; i < sourceData.length && i < 24; i++) {
        fullDay[i] = sourceData[i];
      }
      return fullDay;
    } else if (_selectedViewMode == 'monthly') {
      List<int> monthlyResult = List.filled(targetCount, 0);
      int latestVal = sourceData.where((v) => v > 0).isNotEmpty ? sourceData.where((v) => v > 0).last : 50;
      int targetDayIndex = (_selectedDate.day - 1).clamp(0, targetCount - 1);
      monthlyResult[targetDayIndex] = latestVal;
      return monthlyResult;
    } else {
      List<int> yearlyResult = List.filled(12, 0);
      int latestVal = sourceData.where((v) => v > 0).isNotEmpty ? sourceData.where((v) => v > 0).last : 50;
      int targetMonthIndex = (_selectedDate.month - 1).clamp(0, 11);
      yearlyResult[targetMonthIndex] = latestVal;
      return yearlyResult;
    }
  }

  Future<void> _selectHistoricalTarget(BuildContext context) async {
    final DateTime now = DateTime.now();

    if (_selectedViewMode == 'yearly') {
      final List<int> years = List.generate(7, (i) => now.year - i);
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
        int targetMonth = (_selectedDate.year == selectedYear && _selectedDate.month > now.month) ? now.month : _selectedDate.month;
        int targetDay = _selectedDate.day;
        if (selectedYear == now.year && targetMonth == now.month && targetDay > now.day) {
          targetDay = now.day;
        }
        setState(() => _selectedDate = DateTime(selectedYear, targetMonth, targetDay));
      }
    } else if (_selectedViewMode == 'monthly') {
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
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
        firstDate: DateTime(2020, 1, 1),
        lastDate: now,
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
  final int selectedTab; // 0: All Plants, 1: Plant 1, 2: Plant 2, 3: Plant 3
  final List<int> trendPlant1;
  final List<int> trendPlant2;
  final List<int> trendPlant3;
  final List<String> xLabels;
  final Offset? touchPosition;

  MultiPlantTrendPainter({
    required this.selectedTab,
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

    if (selectedTab == 0) {
      double rightEdge = leftPadding + chartWidth;
      List<Map<String, dynamic>> legends = [];
      if (trendPlant1.any((val) => val > 0)) legends.add({'label': 'P1', 'color': const Color(0xFF5CB85C)});
      if (trendPlant2.any((val) => val > 0)) legends.add({'label': 'P2', 'color': Colors.blueAccent});
      if (trendPlant3.any((val) => val > 0)) legends.add({'label': 'P3', 'color': Colors.orangeAccent});

      double totalLegendWidth = legends.length * 26.0;
      double legendX = rightEdge - totalLegendWidth;
      double legendY = -14.0;

      for (var leg in legends) {
        final dotPaint = Paint()..color = leg['color']..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(legendX + 3, legendY + 4), 3, dotPaint);
        
        TextPainter tp = TextPainter(
          text: TextSpan(text: leg['label'], style: const TextStyle(color: Colors.black87, fontSize: 9.5, fontWeight: FontWeight.bold, fontFamily: 'Roboto')),
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

    // 👑 核心：从底部的 0 开始，向上拉起一条竖线连接到有数据的位置
    void drawLineFromZero(List<int> data, Color color) {
      if (data.isEmpty) return;
      List<Offset> pts = getPoints(data);
      final paint = Paint()..color = color..strokeWidth = 1.6..style = PaintingStyle.stroke;
      final path = Path();
      bool hasStarted = false;

      for (int i = 0; i < pts.length; i++) {
        if (data[i] <= 0) continue;
        if (!hasStarted) {
          // 从图表底部的 0 开始直接拉起到该点
          path.moveTo(pts[i].dx, chartHeight);
          path.lineTo(pts[i].dx, pts[i].dy);
          hasStarted = true;
        } else {
          path.lineTo(pts[i].dx, pts[i].dy);
        }
      }
      if (hasStarted) {
        canvas.drawPath(path, paint);
      }
    }

    if (selectedTab == 0) {
      if (trendPlant1.any((v) => v > 0)) drawLineFromZero(trendPlant1, const Color(0xFF5CB85C));
      if (trendPlant2.any((v) => v > 0)) drawLineFromZero(trendPlant2, Colors.blueAccent);
      if (trendPlant3.any((v) => v > 0)) drawLineFromZero(trendPlant3, Colors.orangeAccent);
    } else if (selectedTab == 1 && trendPlant1.any((v) => v > 0)) {
      drawLineFromZero(trendPlant1, const Color(0xFF5CB85C));
    } else if (selectedTab == 2 && trendPlant2.any((v) => v > 0)) {
      drawLineFromZero(trendPlant2, Colors.blueAccent);
    } else if (selectedTab == 3 && trendPlant3.any((v) => v > 0)) {
      drawLineFromZero(trendPlant3, Colors.orangeAccent);
    }

    // 触摸提示联动
    if (touchPosition != null) {
      Offset adjustedTouch = Offset(touchPosition!.dx, touchPosition!.dy - topPadding);

      List<Map<String, dynamic>> activeLinesToTooltip = [];

      if (selectedTab == 1 && trendPlant1.any((v) => v > 0)) {
        activeLinesToTooltip.add({'data': trendPlant1, 'label': 'P1', 'color': const Color(0xFF5CB85C)});
      } else if (selectedTab == 2 && trendPlant2.any((v) => v > 0)) {
        activeLinesToTooltip.add({'data': trendPlant2, 'label': 'P2', 'color': Colors.blueAccent});
      } else if (selectedTab == 3 && trendPlant3.any((v) => v > 0)) {
        activeLinesToTooltip.add({'data': trendPlant3, 'label': 'P3', 'color': Colors.orangeAccent});
      } else if (selectedTab == 0) {
        if (trendPlant1.any((v) => v > 0)) activeLinesToTooltip.add({'data': trendPlant1, 'label': 'P1', 'color': const Color(0xFF5CB85C)});
        if (trendPlant2.any((v) => v > 0)) activeLinesToTooltip.add({'data': trendPlant2, 'label': 'P2', 'color': Colors.blueAccent});
        if (trendPlant3.any((v) => v > 0)) activeLinesToTooltip.add({'data': trendPlant3, 'label': 'P3', 'color': Colors.orangeAccent});
      }

      if (activeLinesToTooltip.isNotEmpty) {
        List<int> sampleData = activeLinesToTooltip[0]['data'];
        List<Offset> samplePts = getPoints(sampleData);
        if (samplePts.isNotEmpty) {
          Offset closestPoint = samplePts.reduce((a, b) => 
            (a.dx - adjustedTouch.dx).abs() < (b.dx - adjustedTouch.dx).abs() ? a : b
          );
          int closestIdx = samplePts.indexOf(closestPoint);
          String labelStr = xLabels[closestIdx.clamp(0, xLabels.length - 1)];

          final linePaint = Paint()..color = Colors.black54..strokeWidth = 1..style = PaintingStyle.stroke;
          canvas.drawLine(Offset(closestPoint.dx, 0), Offset(closestPoint.dx, chartHeight), linePaint);

          List<String> tooltipLines = [];
          for (var lineInfo in activeLinesToTooltip) {
            List<int> data = lineInfo['data'];
            String pLabel = lineInfo['label'];
            Color dColor = lineInfo['color'];

            if (closestIdx < data.length && data[closestIdx] > 0) {
              int val = data[closestIdx];
              tooltipLines.add('$pLabel | $labelStr: $val%');

              double norm = val / 100.0;
              double y = chartHeight * (1.0 - norm);
              Offset pt = Offset(closestPoint.dx, y);

              canvas.drawCircle(pt, 4.5, Paint()..color = dColor..style = PaintingStyle.fill);
              canvas.drawCircle(pt, 4.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.2);
            }
          }

          if (tooltipLines.isNotEmpty) {
            String fullTooltipText = tooltipLines.join('\n');
            TextPainter tooltipTp = TextPainter(
              text: TextSpan(
                text: fullTooltipText, 
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Roboto', height: 1.2)
              ),
              textDirection: TextDirection.ltr,
            )..layout();

            double boxWidth = tooltipTp.width + 12;
            double boxHeight = tooltipTp.height + 8;
            double boxX = (closestPoint.dx - boxWidth / 2).clamp(leftPadding, leftPadding + chartWidth - boxWidth);
            double boxY = (closestPoint.dy - boxHeight - 8).clamp(0.0, chartHeight - boxHeight);

            RRect rrect = RRect.fromRectAndRadius(Rect.fromLTWH(boxX, boxY, boxWidth, boxHeight), const Radius.circular(4));
            canvas.drawRRect(rrect, Paint()..color = Colors.black87);
            tooltipTp.paint(canvas, Offset(boxX + 6, boxY + 4));
          }
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MultiPlantTrendPainter oldDelegate) => true;
}