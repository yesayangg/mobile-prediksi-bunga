import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prediction_provider.dart';
import '../theme/app_theme.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PredictionProvider>().loadPredictions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PredictionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📊 Prediksi 🌷'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => pp.loadPredictions(),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Text('Periode:',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontFamily: 'Poppins')),
            const SizedBox(width: 12),
            ...[
              ('7 Hari', '7days'),
              ('30 Hari', '30days'),
              ('3 Bulan', '3months'),
            ].map((p) {
              final sel = pp.period == p.$2;
              return GestureDetector(
                onTap: () => pp.loadPredictions(period: p.$2),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppTheme.primary
                        : AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(p.$1,
                      style: TextStyle(
                          color: sel ? Colors.white : AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins')),
                ),
              );
            }),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.info.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.info.withOpacity(0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: AppTheme.info, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Prediksi berbasis data penjualan historis menggunakan ML.',
                  style: TextStyle(
                      color: AppTheme.info,
                      fontSize: 12,
                      fontFamily: 'Poppins'),
                ),
              ),
            ]),
          ),
        ),
        Expanded(
          child: pp.isLoading
              ? const Center(child: CircularProgressIndicator())
              : pp.predictions.isEmpty
                  ? const Center(
                      child: Text('Data prediksi tidak tersedia',
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontFamily: 'Poppins')))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: pp.predictions.length,
                      itemBuilder: (_, i) {
                        final pred = pp.predictions[i];
                        final pct = (pred.confidence * 100).toInt();
                        final cc = pred.confidence >= 0.8
                            ? AppTheme.success
                            : pred.confidence >= 0.6
                                ? AppTheme.warning
                                : AppTheme.error;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(pred.flowerName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: AppTheme.textPrimary,
                                            fontFamily: 'Poppins')),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: cc.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    child: Text('$pct% akurasi',
                                        style: TextStyle(
                                            color: cc,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Poppins')),
                                  ),
                                ]),
                                const SizedBox(height: 10),
                                Row(children: [
                                  const Icon(Icons.trending_up,
                                      color: AppTheme.primary, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Prediksi: ${pred.predictedDemand.toStringAsFixed(0)} tangkai',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                        fontFamily: 'Poppins'),
                                  ),
                                ]),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pred.confidence,
                                    backgroundColor: AppTheme.border,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(cc),
                                    minHeight: 6,
                                  ),
                                ),
                                if (pred.recommendation.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: AppTheme.bgLight,
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                              Icons.lightbulb_outline,
                                              size: 16,
                                              color: AppTheme.warning),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                                pred.recommendation,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme
                                                        .textSecondary,
                                                    fontFamily: 'Poppins')),
                                          ),
                                        ]),
                                  ),
                                ],
                              ]),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}