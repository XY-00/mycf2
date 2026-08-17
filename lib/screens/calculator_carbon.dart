// lib/calculator_carbon.dart

class CarbonCalculator {
  /// 计算总碳足迹 (Total Carbon Footprint Saved)
  /// 公式：遍历 eco_impact_history 数据库里的 saved_amount 列表，把它们全部累加起来
  static double calculateTotal(List<dynamic> historyList) {
    double total = 0.0;
    for (var item in historyList) {
      total += double.tryParse(item['saved_amount'].toString()) ?? 0.0;
    }
    return total;
  }
}