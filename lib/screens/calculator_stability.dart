// lib/calculator_stability.dart

class StabilityCalculator {
  /// 动态计算碳稳定性得分（返回动态的 double 百分比分数）
  static double calculateScore(double currentMoisture) {
    const double idealMoisture = 65.0; // 理想湿度中心值
    double deviation = (currentMoisture - idealMoisture).abs();
    
    // 偏差越大分数越低
    double score = 100.0 - (deviation * 1.2);
    
    if (score < 0.0) return 0.0;
    if (score > 100.0) return 100.0;
    
    return double.parse(score.toStringAsFixed(1)); // 保留一位小数（例如 74.5）
  }
}