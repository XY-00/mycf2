// lib/calculator_hydration.dart

class HydrationCalculator {
  /// 计算植物水分 (Plant Hydration %)
  /// 公式：将传感器的读数进行规范化处理，确保安全限制在 0% 到 100% 之间
  static double calculatePercentage(double rawMoisture) {
    if (rawMoisture < 0.0) return 0.0;
    if (rawMoisture > 100.0) return 100.0;
    return double.parse(rawMoisture.toStringAsFixed(1)); // 保留一位小数
  }
}