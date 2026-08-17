// lib/calculator_stability.dart

class StabilityCalculator {
  /// 计算碳稳定性得分 (Carbon Stability Score，满分 100)
  /// 公式：根据当前土壤湿度是否在理想区间（59% ~ 75%）来评定稳定性得分
  static int calculateScore(double currentMoisture) {
    // 如果湿度在理想的自动灌溉区间内，说明植物水分极其稳定，给高分
    if (currentMoisture >= 59.0 && currentMoisture <= 75.0) {
      return 95; 
    } 
    // 如果稍微偏干或偏湿（处于临界状态），给中等偏上分数
    else if ((currentMoisture >= 45.0 && currentMoisture < 59.0) || 
               (currentMoisture > 75.0 && currentMoisture <= 85.0)) {
      return 75; 
    } 
    // 如果过度干燥或过度积水，说明环境很不稳定，扣分
    else {
      return 50; 
    }
  }
}