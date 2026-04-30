import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class PredictionSummary {
  final int flowerId;
  final String flowerName;
  final double predictedDemand;
  final double confidence;
  final String recommendation;

  PredictionSummary({
    required this.flowerId,
    required this.flowerName,
    required this.predictedDemand,
    required this.confidence,
    required this.recommendation,
  });

  factory PredictionSummary.fromJson(Map<String, dynamic> json) {
    return PredictionSummary(
      flowerId: json['flower_id'],
      flowerName: json['flower_name'],
      predictedDemand: (json['predicted_demand'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      recommendation: json['recommendation'] ?? '',
    );
  }
}

class PredictionProvider extends ChangeNotifier {
  List<PredictionSummary> _predictions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _period = '7days';

  List<PredictionSummary> get predictions => _predictions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get period => _period;

  Future<void> loadPredictions({String period = '7days'}) async {
    _period = period;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getPredictions(period: period);
      _predictions = (response['data'] as List)
          .map((e) => PredictionSummary.fromJson(e))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}