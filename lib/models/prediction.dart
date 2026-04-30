class Prediction {
  final int flowerId;
  final String flowerName;
  final double predictedDemand;
  final double confidence;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<DailyPrediction> dailyData;
  final String recommendation;

  Prediction({
    required this.flowerId,
    required this.flowerName,
    required this.predictedDemand,
    required this.confidence,
    required this.periodStart,
    required this.periodEnd,
    required this.dailyData,
    required this.recommendation,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      flowerId: json['flower_id'],
      flowerName: json['flower_name'],
      predictedDemand: (json['predicted_demand'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: DateTime.parse(json['period_end']),
      dailyData: (json['daily_data'] as List? ?? [])
          .map((e) => DailyPrediction.fromJson(e))
          .toList(),
      recommendation: json['recommendation'] ?? '',
    );
  }
}

class DailyPrediction {
  final DateTime date;
  final double predicted;
  final double? actual;

  DailyPrediction({required this.date, required this.predicted, this.actual});

  factory DailyPrediction.fromJson(Map<String, dynamic> json) {
    return DailyPrediction(
      date: DateTime.parse(json['date']),
      predicted: (json['predicted'] as num).toDouble(),
      actual: json['actual'] != null
          ? (json['actual'] as num).toDouble()
          : null,
    );
  }
}
