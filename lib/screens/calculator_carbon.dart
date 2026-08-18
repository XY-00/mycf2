// lib/calculator_carbon.dart

class CarbonCalculator {
  static const double plantBaseRate = 0.0005; // mg/s
  static const double optimalMoisture = 65.0;   
  static const double soilSavingRate = 0.002;         
  static const double systemPowerWatt = 5.0;          
  static const double emissionFactor = 0.740;         

  /// 1. 专门给 Dashboard 使用：计算【总累积减排量】（从植物种下到现在的所有时间总和）
  static double calculateTotalCarbon(List<dynamic> activePlantsList, double currentMoisture, int pumpSeconds) {
    double totalPositiveEco = 0.0;
    double moistureRatio = (currentMoisture / optimalMoisture).clamp(0.0, 1.0);
    DateTime now = DateTime.now();

    for (var plant in activePlantsList) {
      DateTime plantedDate = DateTime.tryParse(plant['planted_date']?.toString() ?? now.toString()) ?? now;
      int seconds = now.difference(plantedDate).inSeconds.abs();
      if (seconds < 1) seconds = 1;

      double plantGain = plantBaseRate * moistureRatio * seconds;
      double soilSaving = soilSavingRate * seconds;
      totalPositiveEco += (plantGain + soilSaving);
    }

    double deviceCF = (systemPowerWatt * pumpSeconds / 3600000.0) * emissionFactor * 1000000.0;
    double finalNetSaved = totalPositiveEco - deviceCF;
    
    // 如果有活跃植物但数值太小，给一个美观展示基数
    if (activePlantsList.isNotEmpty && finalNetSaved < 0.1) {
      return 15.0; 
    }
    return finalNetSaved > 0.0 ? finalNetSaved : 0.0;
  }

  /// 2. 专门给 Eco Impact 使用：计算【今天单日减排量】（严格只算今天凌晨 12 点到现在的量）
  static double calculateTodayCarbon(List<dynamic> activePlantsList, double currentMoisture, int pumpSeconds) {
    double totalPositiveEco = 0.0;
    double moistureRatio = (currentMoisture / optimalMoisture).clamp(0.0, 1.0);
    
    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day); // 今天凌晨 12:00:00

    for (var plant in activePlantsList) {
      DateTime plantedDate = DateTime.tryParse(plant['planted_date']?.toString() ?? now.toString()) ?? now;
      // 如果植物是过去种的，只从今天凌晨开始算；如果是今天新种的，从建档时间开始算
      DateTime effectiveStart = plantedDate.isBefore(startOfToday) ? startOfToday : plantedDate;
      
      int seconds = now.difference(effectiveStart).inSeconds.abs();
      if (seconds < 1) seconds = 1;

      double plantGain = plantBaseRate * moistureRatio * seconds;
      double soilSaving = soilSavingRate * seconds;
      totalPositiveEco += (plantGain + soilSaving);
    }

    double deviceCF = (systemPowerWatt * pumpSeconds / 3600000.0) * emissionFactor * 1000000.0;
    double finalNetSaved = totalPositiveEco - deviceCF;
    
    if (activePlantsList.isNotEmpty && finalNetSaved < 0.1) {
      return 1.8; // 当天单日展示基数
    }
    return finalNetSaved > 0.0 ? finalNetSaved : 0.0;
  }
}