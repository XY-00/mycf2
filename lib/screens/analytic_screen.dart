import 'package:flutter/material.dart';

class AnalyticScreen extends StatefulWidget {
  const AnalyticScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticScreen> createState() => _AnalyticScreenState();
}

class _AnalyticScreenState extends State<AnalyticScreen> {
  int _selectedPlantTab = 0; 

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF2C4A3E); 
    const Color cardBg = Color(0xFFEAF2E8);
    const Color softIvoryWhite = Color(0xFFF9FBFA); 

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
                      Text('Analysis Report', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildTabButton('All Plants', 0),
                  _buildTabButton('Plant 1', 1),
                  _buildTabButton('Plant 2', 2),
                  _buildTabButton('Plant 3', 3),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            // Live Camera Container
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 20.0), 
              decoration: BoxDecoration(
                color: softIvoryWhite, 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12), // 增加边框
              ),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double totalWidth = constraints.maxWidth;
                      double boxWidth = (totalWidth - 32) / 3; 

                      return Container(
                        width: double.infinity, height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12), color: const Color(0xFFDCEAE4),
                          image: const DecorationImage(image: AssetImage('assets/analytic_plant.jpg'), fit: BoxFit.cover),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 12, left: 12, 
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                                decoration: BoxDecoration(color: const Color(0xFF5CB85C), borderRadius: BorderRadius.circular(12)), 
                                child: const Text('LIVE CAMERA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            if (_selectedPlantTab == 0 || _selectedPlantTab == 1)
                              Positioned(top: 45, left: 8, child: _cvBox('plant 1', boxWidth, 110)),
                            if (_selectedPlantTab == 0 || _selectedPlantTab == 2)
                              Positioned(top: 45, left: 8 + boxWidth + 8, child: _cvBox('plant 2', boxWidth, 110)),
                            if (_selectedPlantTab == 0 || _selectedPlantTab == 3)
                              Positioned(top: 45, left: 8 + (boxWidth * 2) + 16, child: _cvBox('plant 3', boxWidth, 110)),
                            Positioned(
                              bottom: 8, left: 12, 
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), color: Colors.black54,
                                child: const Text('Next refresh in: 14 mins (Resolution: Medium)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Visual Health Validation Panel
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 20.0), 
              decoration: BoxDecoration(
                color: cardBg, 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12), // 增加边框
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.spa_outlined, color: primaryDarkGreen, size: 18),
                      SizedBox(width: 6),
                      Text('Visual Health Validation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2, childAspectRatio: 2.3, mainAxisSpacing: 8, crossAxisSpacing: 8,
                    children: [
                      _buildGridItem('Leaf Color Analysis', _selectedPlantTab == 0 ? 'All channels normal' : 'Plant $_selectedPlantTab: Lush Green', Icons.spa_outlined),
                      _buildGridItem('Growth Rate', _selectedPlantTab == 0 ? 'Avg: +2.1 cm / week' : 'Plant $_selectedPlantTab: +2.3 cm', Icons.stacked_line_chart),
                      _buildGridItem('Moisture Status', _selectedPlantTab == 0 ? 'All sensors online' : 'Plant $_selectedPlantTab: Stable (65%)', Icons.opacity_outlined),
                      _buildGridItem('System Performance', _selectedPlantTab == 0 ? 'Relays triggered: 3' : 'Pump $_selectedPlantTab active yesterday', Icons.notifications_active_outlined),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Moisture Trend Panel
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 20.0), 
              decoration: BoxDecoration(
                color: softIvoryWhite, 
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: Colors.black12), // 增加边框
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('  24-Hour Moisture Trend (${_selectedPlantTab == 0 ? "Overview" : "Plant $_selectedPlantTab"})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 150, width: double.infinity,
                    child: CustomPaint(painter: CompleteAxisTrendPainter(selectedTab: _selectedPlantTab)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Carbon Protection Panel
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 20.0), 
              decoration: BoxDecoration(
                color: cardBg, 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12), // 增加边框
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Carbon Protection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: softIvoryWhite, 
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12), // 添加小卡片内部微型细边框
                          ),
                          child: Column(
                            children: const [
                              Text('3', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                              Text('Successful Interventions', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: softIvoryWhite, 
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12), // 添加小卡片内部微型细边框
                          ),
                          child: Column(
                            children: const [
                              Text('100 %', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                              Text('Protection Rate', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _cvBox(String label, double width, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
      children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), color: Colors.redAccent, child: Text('$label 98%', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
        Container(
          width: width, 
          height: height, 
          decoration: BoxDecoration(
            border: Border.all(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    bool isSelected = _selectedPlantTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlantTab = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2), padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: isSelected ? const Color(0xFF2C4A3E) : Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? const Color(0xFF2C4A3E) : Colors.black12)),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
        ),
      ),
    );
  }

  Widget _buildGridItem(String title, String desc, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12), // 为指标小卡片增加精细浅色边框
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF497E66)),
              const SizedBox(width: 4),
              Flexible(child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF497E66)), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 10, color: Colors.black54, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// CustomPainter 保留原逻辑不变
class CompleteAxisTrendPainter extends CustomPainter {
  final int selectedTab;
  CompleteAxisTrendPainter({required this.selectedTab});
  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()..color = Colors.black87..strokeWidth = 1.2..style = PaintingStyle.stroke;
    final gridPaint = Paint()..color = Colors.black12..strokeWidth = 0.5..style = PaintingStyle.stroke;
    final dashPaint = Paint()..color = Colors.redAccent..strokeWidth = 1.2..style = PaintingStyle.stroke;
    double leftPadding = 42.0; double bottomPadding = 25.0;
    double chartWidth = size.width - leftPadding; double chartHeight = size.height - bottomPadding;
    canvas.drawLine(Offset(leftPadding, 0), Offset(leftPadding, chartHeight), axisPaint);
    canvas.drawLine(Offset(leftPadding, chartHeight), Offset(size.width, chartHeight), axisPaint);
    List<String> yLabels = ['100%', '75%', '50%', '25%', '0%'];
    for (int i = 0; i < yLabels.length; i++) {
      double yPos = (chartHeight / (yLabels.length - 1)) * i;
      canvas.drawLine(Offset(leftPadding, yPos), Offset(size.width, yPos), gridPaint);
      TextPainter(text: TextSpan(text: yLabels[i], style: const TextStyle(color: Colors.black54, fontSize: 9)), textDirection: TextDirection.ltr)..layout()..paint(canvas, Offset(5, yPos - 6));
    }
    double y59Pos = chartHeight * (1.0 - 0.59);
    double stepWidth = 5; double stepSpace = 4; double currentX = leftPadding;
    while (currentX < size.width) {
      canvas.drawLine(Offset(currentX, y59Pos), Offset(currentX + stepWidth, y59Pos), dashPaint);
      currentX += stepWidth + stepSpace;
    }
    List<String> xLabels = ['1100', '1200', '1300', '1400', '1500'];
    for (int i = 0; i < xLabels.length; i++) {
      double xPos = leftPadding + (chartWidth / (xLabels.length - 1)) * i;
      canvas.drawLine(Offset(xPos, 0), Offset(xPos, chartHeight), gridPaint);
      TextPainter(text: TextSpan(text: xLabels[i], style: const TextStyle(color: Colors.black54, fontSize: 9)), textDirection: TextDirection.ltr)..layout()..paint(canvas, Offset(xPos - 12, chartHeight + 6));
    }
    if (selectedTab == 0 || selectedTab == 1) {
      final p1 = Paint()..color = const Color(0xFF5CB85C)..strokeWidth = 2.5..style = PaintingStyle.stroke;
      final path1 = Path()..moveTo(leftPadding, chartHeight * 0.38)..lineTo(leftPadding + chartWidth * 0.25, chartHeight * 0.5)..lineTo(leftPadding + chartWidth * 0.5, chartHeight * 0.18)..lineTo(leftPadding + chartWidth * 0.75, chartHeight * 0.33)..lineTo(size.width, chartHeight * 0.42);
      canvas.drawPath(path1, p1);
    }
    if (selectedTab == 0 || selectedTab == 2) {
      final p2 = Paint()..color = Colors.blueAccent..strokeWidth = 2.0..style = PaintingStyle.stroke;
      final path2 = Path()..moveTo(leftPadding, chartHeight * 0.5)..lineTo(leftPadding + chartWidth * 0.25, chartHeight * 0.3)..lineTo(leftPadding + chartWidth * 0.5, chartHeight * 0.45)..lineTo(leftPadding + chartWidth * 0.75, chartHeight * 0.2)..lineTo(size.width, chartHeight * 0.35);
      canvas.drawPath(path2, p2);
    }
    if (selectedTab == 0 || selectedTab == 3) {
      final p3 = Paint()..color = Colors.orangeAccent..strokeWidth = 2.0..style = PaintingStyle.stroke;
      final path3 = Path()..moveTo(leftPadding, chartHeight * 0.25)..lineTo(leftPadding + chartWidth * 0.25, chartHeight * 0.4)..lineTo(leftPadding + chartWidth * 0.5, chartHeight * 0.55)..lineTo(leftPadding + chartWidth * 0.75, chartHeight * 0.38)..lineTo(size.width, chartHeight * 0.15);
      canvas.drawPath(path3, p3);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}