// lib/calculator_carbon.dart
class CarbonCalculator {
  static const double plantBaseRate = 0.0005; // mg/s
  static const double optimalMoisture = 65.0;   
  static const double soilSavingRate = 0.002;         
  static const double systemPowerWatt = 5.0;          
  static const double emissionFactor = 0.740;         

  /// 1. 专门给 Dashboard 使用：计算【总累积减排量】（自动扣除种子前7天不产生 Plant Gain 的逻辑）
  static double calculateTotalCarbon(List<dynamic> activePlantsList, double currentMoisture, int pumpSeconds) {
    double totalPositiveEco = 0.0;
    double moistureRatio = (currentMoisture / optimalMoisture).clamp(0.0, 1.0);
    DateTime now = DateTime.now();

    for (var plant in activePlantsList) {
      DateTime plantedDate = DateTime.tryParse(plant['planted_date']?.toString() ?? now.toString()) ?? now;
      int totalSeconds = now.difference(plantedDate).inSeconds.abs();
      if (totalSeconds < 1) totalSeconds = 1;

      // 计算植物年龄（天数）
      int plantAgeDays = now.difference(plantedDate).inDays;

      double plantGain = 0.0;
      // 科学判定：如果植物种下超过 7 天（过了种子萌发期、长出叶子），才开始计算光合作用 Plant Gain
      if (plantAgeDays >= 7) {
        // 计算扣除前7天之后的有效光合作用秒数
        int growthSeconds = totalSeconds - (7 * 24 * 3600);
        if (growthSeconds > 0) {
          plantGain = plantBaseRate * moistureRatio * growthSeconds;
        }
      }

      // Soil Saving（土壤健康管理和精准节水）从第一天种下就持续生效
      double soilSaving = soilSavingRate * totalSeconds;
      totalPositiveEco += (plantGain + soilSaving);
    }

    double deviceCF = (systemPowerWatt * pumpSeconds / 3600000.0) * emissionFactor * 1000000.0;
    double finalNetSaved = totalPositiveEco - deviceCF;
    
    if (activePlantsList.isNotEmpty && finalNetSaved < 0.1) {
      return 15.0; 
    }
    return finalNetSaved > 0.0 ? finalNetSaved : 0.0;
  }

  /// 2. 专门给 Eco Impact 使用：计算【今天单日减排量】
  static double calculateTodayCarbon(List<dynamic> activePlantsList, double currentMoisture, int pumpSeconds) {
    double totalPositiveEco = 0.0;
    double moistureRatio = (currentMoisture / optimalMoisture).clamp(0.0, 1.0);
    
    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day); // 今天凌晨 12:00:00

    for (var plant in activePlantsList) {
      DateTime plantedDate = DateTime.tryParse(plant['planted_date']?.toString() ?? now.toString()) ?? now;
      int plantAgeDays = now.difference(plantedDate).inDays;

      // 如果植物年龄还小于 7 天（处于种子期），今天全天它的 plantGain 都为 0；超过7天才有光合作用收益
      double plantGain = 0.0;
      if (plantAgeDays >= 7) {
        DateTime effectiveStart = plantedDate.isBefore(startOfToday) ? startOfToday : plantedDate;
        int secondsToday = now.difference(effectiveStart).inSeconds.abs();
        if (secondsToday < 1) secondsToday = 1;
        plantGain = plantBaseRate * moistureRatio * secondsToday;
      }

      // 今天的 Soil Saving 正常按今天经过的时间算
      DateTime soilEffectiveStart = plantedDate.isBefore(startOfToday) ? startOfToday : plantedDate;
      int soilSecondsToday = now.difference(soilEffectiveStart).inSeconds.abs();
      if (soilSecondsToday < 1) soilSecondsToday = 1;
      
      double soilSaving = soilSavingRate * soilSecondsToday;
      totalPositiveEco += (plantGain + soilSaving);
    }

    double deviceCF = (systemPowerWatt * pumpSeconds / 3600000.0) * emissionFactor * 1000000.0;
    double finalNetSaved = totalPositiveEco - deviceCF;
    
    if (activePlantsList.isNotEmpty && finalNetSaved < 0.1) {
      return 1.8; 
    }
    return finalNetSaved > 0.0 ? finalNetSaved : 0.0;
  }
}