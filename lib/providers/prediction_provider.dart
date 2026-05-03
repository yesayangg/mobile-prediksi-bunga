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
    final predictedDemand = (json['prediction'] as num).toDouble();

    return PredictionSummary(
      flowerId: json['product_id'] ?? 0,
      flowerName: json['nama_bunga'] ?? '-',
      predictedDemand: predictedDemand,
      confidence: 0.85,
      recommendation:
          'Siapkan stok sekitar ${predictedDemand.toStringAsFixed(0)} tangkai untuk periode berikutnya.',
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

      final List<dynamic> data = response is List
          ? response
          : (response['data'] as List? ?? []);

      _predictions = data
          .map((e) => PredictionSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}