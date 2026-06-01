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
    final roundedDemand = predictedDemand.round();

    return PredictionSummary(
      flowerId: json['product_id'] ?? 0,
      flowerName: json['nama_bunga'] ?? '-',
      predictedDemand: predictedDemand,
      confidence: 0.85,
      recommendation:
          'Perkiraan butuh sekitar $roundedDemand tangkai. Cek stok dulu sebelum restok.',
    );
  }
}

class PredictionProvider extends ChangeNotifier {
  List<PredictionSummary> _predictions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _predictionDate;

  List<PredictionSummary> get predictions => _predictions;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String? get predictionDate => _predictionDate;

  Future<void> loadPredictions() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final response = await ApiService.getPredictions();

      final List<dynamic> data =
          response is List ? response : (response['data'] as List? ?? []);

      _predictions = data
          .map(
            (e) => PredictionSummary.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();

      // AMBIL TANGGAL DARI BACKEND
      if (data.isNotEmpty) {
        final firstItem = data.first as Map<String, dynamic>;

        final rawDate = firstItem['tanggal']?.toString();

        if (rawDate != null && rawDate.isNotEmpty) {
          final date = DateTime.parse(rawDate);

          final months = [
            '',
            'Januari',
            'Februari',
            'Maret',
            'April',
            'Mei',
            'Juni',
            'Juli',
            'Agustus',
            'September',
            'Oktober',
            'November',
            'Desember',
          ];

          _predictionDate = '${months[date.month]} ${date.year}';
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }
}
