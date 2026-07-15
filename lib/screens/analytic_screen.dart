import 'package:flutter/material.dart';

class AnalyticScreen extends StatelessWidget {
  const AnalyticScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF497E66);
    const Color cardBg = Color(0xFFEAF2E8);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Analysis Report', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        centerTitle: true,
        backgroundColor: primaryGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 👑 2. 修改点：LIVE 实况组件给予坚固的纯白色实色卡片作为底座，彻底告别穿透干扰！
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 170,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFDCEAE4), // 模拟真实的实时图像层底色
                      image: const DecorationImage(
                        image: AssetImage('assets/analytic_plant.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                            child: const Text('• LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            color: Colors.black54,
                            child: const Text('Current Moisture: 65%', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.eco_outlined, color: primaryGreen, size: 18),
                      SizedBox(width: 6),
                      Text('Visual Health Validation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryGreen)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
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
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📈 24-Hour Moisture Trend Analysis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: CustomPaint(painter: MicroTrendChartPainter()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Carbon Protection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryGreen)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: const [
                              Text('3', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryGreen)),
                              Text('Successful Interventions', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
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

class MicroTrendChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5CB85C)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final baseLinePaint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height * 0.65), Offset(size.width, size.height * 0.65), baseLinePaint);

    final path = Path();
    path.moveTo(0, size.height * 0.4);
    path.lineTo(size.width * 0.2, size.height * 0.45);
    path.lineTo(size.width * 0.4, size.height * 0.52);
    path.lineTo(size.width * 0.5, size.height * 0.15);
    path.lineTo(size.width * 0.7, size.height * 0.28);
    path.lineTo(size.width * 0.9, size.height * 0.38);
    path.lineTo(size.width, size.height * 0.42);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}