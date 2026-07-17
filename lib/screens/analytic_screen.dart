import 'package:flutter/material.dart';

class AnalyticScreen extends StatelessWidget {
  const AnalyticScreen({Key? key}) : super(key: key);

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
            // 👑 修改点 2：Title Bar 高度、大小、Padding 与 Home 页面完全一模一样，纯字完美居中
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
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 14.0, bottom: 16.0), // 👑 精准对齐 Home 页
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: const [
                      Text(
                        'Analysis Report',
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: softIvoryWhite, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Container(
                    width: double.infinity, height: 170,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12), color: const Color(0xFFDCEAE4),
                      image: const DecorationImage(image: AssetImage('assets/analytic_plant.jpg'), fit: BoxFit.cover),
                    ),
                    child: Stack(
                      children: [
                        Positioned(top: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)), child: const Text('• LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))),
                        Positioned(bottom: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), color: Colors.black54, child: const Text('Current Moisture: 65%', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.eco_outlined, color: primaryDarkGreen, size: 18),
                      SizedBox(width: 6),
                      Text('Visual Health Validation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2, childAspectRatio: 2.3, mainAxisSpacing: 8, crossAxisSpacing: 8,
                    children: [
                      _buildGridItem('Leaf Color Analysis', 'Lush green color, no yellowing', Icons.spa_outlined),
                      _buildGridItem('Growth Rate', '2.3 cm growth in 7 days', Icons.stacked_line_chart),
                      _buildGridItem('Moisture Status', 'Leaves stand upright, no wilting', Icons.opacity_outlined),
                      _buildGridItem('System Performance', 'Successfully issued 3 alerts', Icons.notifications_active_outlined),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: softIvoryWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📈 24-Hour Moisture Trend Analysis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 150, width: double.infinity,
                    child: CustomPaint(painter: CompleteAxisTrendPainter()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
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
                          decoration: BoxDecoration(color: softIvoryWhite, borderRadius: BorderRadius.circular(12)),
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
                          decoration: BoxDecoration(color: softIvoryWhite, borderRadius: BorderRadius.circular(12)),
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

  Widget _buildGridItem(String title, String desc, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
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

class CompleteAxisTrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()..color = Colors.black87..strokeWidth = 1.2..style = PaintingStyle.stroke;
    final gridPaint = Paint()..color = Colors.black12..strokeWidth = 0.5..style = PaintingStyle.stroke;
    final linePaint = Paint()..color = const Color(0xFF5CB85C)..strokeWidth = 2.5..style = PaintingStyle.stroke;
    final dashPaint = Paint()..color = Colors.redAccent..strokeWidth = 1.2..style = PaintingStyle.stroke;

    double leftPadding = 42.0;
    double bottomPadding = 25.0;
    double chartWidth = size.width - leftPadding;
    double chartHeight = size.height - bottomPadding;

    canvas.drawLine(Offset(leftPadding, 0), Offset(leftPadding, chartHeight), axisPaint);
    canvas.drawLine(Offset(leftPadding, chartHeight), Offset(size.width, chartHeight), axisPaint);

    List<String> yLabels = ['100%', '75%', '50%', '25%', '0%'];
    for (int i = 0; i < yLabels.length; i++) {
      double yPos = (chartHeight / (yLabels.length - 1)) * i;
      canvas.drawLine(Offset(leftPadding, yPos), Offset(size.width, yPos), gridPaint);
      TextPainter(text: TextSpan(text: yLabels[i], style: const TextStyle(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout()..paint(canvas, Offset(5, yPos - 6));
    }

    double y59Pos = chartHeight * (1.0 - 0.59);
    double stepWidth = 5; double stepSpace = 4;
    double currentX = leftPadding;
    while (currentX < size.width) {
      canvas.drawLine(Offset(currentX, y59Pos), Offset(currentX + stepWidth, y59Pos), dashPaint);
      currentX += stepWidth + stepSpace;
    }
    TextPainter(text: const TextSpan(text: '59% Safe Line', style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout()..paint(canvas, Offset(size.width - 65, y59Pos - 11));

    List<String> xLabels = ['1100', '1200', '1300', '1400', '1500'];
    for (int i = 0; i < xLabels.length; i++) {
      double xPos = leftPadding + (chartWidth / (xLabels.length - 1)) * i;
      canvas.drawLine(Offset(xPos, 0), Offset(xPos, chartHeight), gridPaint);
      TextPainter(text: TextSpan(text: xLabels[i], style: const TextStyle(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr)..layout()..paint(canvas, Offset(xPos - 12, chartHeight + 6));
    }

    final path = Path();
    path.moveTo(leftPadding, chartHeight * 0.38); path.lineTo(leftPadding + chartWidth * 0.25, chartHeight * 0.5);
    path.lineTo(leftPadding + chartWidth * 0.5, chartHeight * 0.18); path.lineTo(leftPadding + chartWidth * 0.75, chartHeight * 0.33);
    path.lineTo(size.width, chartHeight * 0.42);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}