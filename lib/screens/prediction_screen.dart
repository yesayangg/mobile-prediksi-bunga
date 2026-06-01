import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/prediction_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/florashop_logo.dart';

class _NoStretchScrollBehavior extends MaterialScrollBehavior {
  const _NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

enum _PredictionFilter { all, high, medium, low }

class PredictionScreen extends StatefulWidget {
  final ValueChanged<String>? onOpenStockForFlower;

  const PredictionScreen({super.key, this.onOpenStockForFlower});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _numberFmt = NumberFormat.decimalPattern('id_ID');
  DateTime? _lastUpdatedAt;
  _PredictionFilter _activeFilter = _PredictionFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPredictions();
    });
  }

  Future<void> _refreshPredictions() async {
    final provider = context.read<PredictionProvider>();
    await provider.loadPredictions();

    if (!mounted) return;
    if (provider.errorMessage == null) {
      setState(() => _lastUpdatedAt = DateTime.now());
    }
  }

  String _formatTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _updatedLabel(PredictionProvider provider) {
    if (provider.isLoading && _lastUpdatedAt == null) {
      return 'Menunggu analisis';
    }

    final updatedAt = _lastUpdatedAt;
    if (updatedAt == null) return 'Belum diperbarui';
    return 'Diperbarui ${_formatTime(updatedAt)}';
  }

  List<PredictionSummary> _sorted(List<PredictionSummary> predictions) {
    final result = [...predictions];
    result.sort((a, b) => b.predictedDemand.compareTo(a.predictedDemand));
    return result;
  }

  double _maxDemand(List<PredictionSummary> predictions) {
    if (predictions.isEmpty) return 0;
    return predictions
        .map((e) => e.predictedDemand)
        .reduce((a, b) => a > b ? a : b);
  }

  _PredictionFilter _levelFor(
    PredictionSummary prediction,
    List<PredictionSummary> allPredictions,
  ) {
    final maxDemand = _maxDemand(allPredictions);
    if (maxDemand <= 0) return _PredictionFilter.low;

    final ratio = prediction.predictedDemand / maxDemand;
    if (ratio >= 0.67) return _PredictionFilter.high;
    if (ratio >= 0.34) return _PredictionFilter.medium;
    return _PredictionFilter.low;
  }

  int _countByLevel(
    List<PredictionSummary> predictions,
    _PredictionFilter filter,
  ) {
    if (filter == _PredictionFilter.all) return predictions.length;
    return predictions
        .where((prediction) => _levelFor(prediction, predictions) == filter)
        .length;
  }

  List<PredictionSummary> _filtered(List<PredictionSummary> predictions) {
    final sorted = _sorted(predictions);
    if (_activeFilter == _PredictionFilter.all) return sorted;
    return sorted
        .where(
            (prediction) => _levelFor(prediction, predictions) == _activeFilter)
        .toList();
  }

  String _friendlyError(String? message) {
    if (message == null || message.trim().isEmpty) {
      return 'Prediksi belum bisa dimuat. Coba lagi sebentar.';
    }

    final lower = message.toLowerCase();
    if (lower.contains('socket') ||
        lower.contains('timeout') ||
        lower.contains('connection') ||
        lower.contains('failed host') ||
        lower.contains('xmlhttprequest')) {
      return 'Server toko belum bisa dijangkau. Pastikan internet aktif atau hubungi admin.';
    }

    return 'Prediksi belum bisa dimuat. Periksa koneksi lalu coba lagi.';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PredictionProvider>();
    final predictions = provider.predictions;
    final filtered = _filtered(predictions);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: _PredictionHeader(
          isLoading: provider.isLoading,
          updatedLabel: _updatedLabel(provider),
          activeFilter: _activeFilter,
          allCount: predictions.length,
          highCount: _countByLevel(predictions, _PredictionFilter.high),
          mediumCount: _countByLevel(predictions, _PredictionFilter.medium),
          lowCount: _countByLevel(predictions, _PredictionFilter.low),
          onRefresh: _refreshPredictions,
          onSelectFilter: (filter) {
            setState(() => _activeFilter = filter);
          },
        ),
      ),
      body: ScrollConfiguration(
        behavior: const _NoStretchScrollBehavior(),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFF7FB),
                Color(0xFFFFEEF6),
                Color(0xFFFFFFFF),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: RefreshIndicator(
            color: AppTheme.primary,
            backgroundColor: Colors.white,
            onRefresh: _refreshPredictions,
            child: _PredictionContent(
              isLoading: provider.isLoading,
              errorMessage: provider.errorMessage,
              friendlyError: _friendlyError(provider.errorMessage),
              predictions: predictions,
              filteredPredictions: filtered,
              activeFilter: _activeFilter,
              numberFmt: _numberFmt,
              onRetry: _refreshPredictions,
              onOpenStockForFlower: widget.onOpenStockForFlower,
              levelFor: (prediction) => _levelFor(prediction, predictions),
            ),
          ),
        ),
      ),
    );
  }
}

class _PredictionHeader extends StatelessWidget {
  final bool isLoading;
  final String updatedLabel;
  final _PredictionFilter activeFilter;
  final int allCount;
  final int highCount;
  final int mediumCount;
  final int lowCount;
  final Future<void> Function() onRefresh;
  final ValueChanged<_PredictionFilter> onSelectFilter;

  const _PredictionHeader({
    required this.isLoading,
    required this.updatedLabel,
    required this.activeFilter,
    required this.allCount,
    required this.highCount,
    required this.mediumCount,
    required this.lowCount,
    required this.onRefresh,
    required this.onSelectFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF5D1734),
            Color(0xFFC51661),
            Color(0xFFE8185A),
          ],
          stops: [0, 0.52, 1],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 17),
          child: Column(
            children: [
              Row(
                children: [
                  const FloraShopLogo(size: 36, showShadow: false),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FLORASHOP',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Prediksi',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFFD9EA),
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          updatedLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.72),
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Perbarui data prediksi',
                    child: InkWell(
                      onTap: isLoading ? null : onRefresh,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                        ),
                        child: isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 23,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF5D1734).withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    _PredictionFilterChip(
                      label: 'Semua',
                      icon: Icons.grid_view_rounded,
                      count: allCount,
                      isSelected: activeFilter == _PredictionFilter.all,
                      onTap: () => onSelectFilter(_PredictionFilter.all),
                    ),
                    const SizedBox(width: 5),
                    _PredictionFilterChip(
                      label: 'Tinggi',
                      icon: Icons.trending_up_rounded,
                      count: highCount,
                      isSelected: activeFilter == _PredictionFilter.high,
                      onTap: () => onSelectFilter(_PredictionFilter.high),
                    ),
                    const SizedBox(width: 5),
                    _PredictionFilterChip(
                      label: 'Sedang',
                      icon: Icons.show_chart_rounded,
                      count: mediumCount,
                      isSelected: activeFilter == _PredictionFilter.medium,
                      onTap: () => onSelectFilter(_PredictionFilter.medium),
                    ),
                    const SizedBox(width: 5),
                    _PredictionFilterChip(
                      label: 'Ringan',
                      icon: Icons.trending_flat_rounded,
                      count: lowCount,
                      isSelected: activeFilter == _PredictionFilter.low,
                      onTap: () => onSelectFilter(_PredictionFilter.low),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PredictionFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _PredictionFilterChip({
    required this.label,
    required this.icon,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'Filter prediksi $label',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.08),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFF5D1734).withValues(alpha: 0.16),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: isSelected
                        ? AppTheme.primary
                        : Colors.white.withValues(alpha: 0.82),
                  ),
                  const SizedBox(height: 1),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9.6,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.white.withValues(alpha: 0.82),
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.white.withValues(alpha: 0.82),
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PredictionContent extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final String friendlyError;
  final List<PredictionSummary> predictions;
  final List<PredictionSummary> filteredPredictions;
  final _PredictionFilter activeFilter;
  final NumberFormat numberFmt;
  final Future<void> Function() onRetry;
  final ValueChanged<String>? onOpenStockForFlower;
  final _PredictionFilter Function(PredictionSummary prediction) levelFor;

  const _PredictionContent({
    required this.isLoading,
    required this.errorMessage,
    required this.friendlyError,
    required this.predictions,
    required this.filteredPredictions,
    required this.activeFilter,
    required this.numberFmt,
    required this.onRetry,
    required this.onOpenStockForFlower,
    required this.levelFor,
  });

  String get _emptyTitle {
    if (activeFilter == _PredictionFilter.high) {
      return 'Belum ada prediksi tinggi';
    }
    if (activeFilter == _PredictionFilter.medium) {
      return 'Belum ada prediksi sedang';
    }
    if (activeFilter == _PredictionFilter.low) {
      return 'Belum ada prediksi ringan';
    }
    return 'Belum ada data prediksi';
  }

  String get _emptySubtitle {
    if (predictions.isEmpty) {
      return 'Pastikan data penjualan sudah tersedia dan prediksi sudah dijalankan dari web admin.';
    }

    return 'Coba pilih filter lain untuk melihat hasil prediksi yang tersedia.';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && predictions.isEmpty) {
      return const _PredictionSkeletonList();
    }

    if (errorMessage != null && predictions.isEmpty) {
      return _PredictionStatePanel(
        icon: Icons.cloud_off_rounded,
        color: AppTheme.error,
        title: 'Prediksi belum bisa dimuat',
        subtitle: friendlyError,
        actionLabel: 'Coba Lagi',
        onAction: onRetry,
      );
    }

    if (filteredPredictions.isEmpty) {
      return _PredictionStatePanel(
        icon: Icons.insights_rounded,
        color: AppTheme.primary,
        title: _emptyTitle,
        subtitle: _emptySubtitle,
        actionLabel: predictions.isEmpty ? 'Coba Lagi' : null,
        onAction: predictions.isEmpty ? onRetry : null,
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        _PredictionInfoBanner(
          totalCount: predictions.length,
          highCount: predictions
              .where((prediction) =>
                  levelFor(prediction) == _PredictionFilter.high)
              .length,
          numberFmt: numberFmt,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          _PredictionInlineError(message: friendlyError, onRetry: onRetry),
        ],
        const SizedBox(height: 14),
        ...filteredPredictions.map(
          (prediction) => _PredictionCard(
            prediction: prediction,
            numberFmt: numberFmt,
            level: levelFor(prediction),
            onOpenStock: onOpenStockForFlower == null
                ? null
                : () => onOpenStockForFlower!(prediction.flowerName),
          ),
        ),
      ],
    );
  }
}

class _PredictionInfoBanner extends StatelessWidget {
  final int totalCount;
  final int highCount;
  final NumberFormat numberFmt;

  const _PredictionInfoBanner({
    required this.totalCount,
    required this.highCount,
    required this.numberFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5C6D8)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              color: AppTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${numberFmt.format(totalCount)} prediksi siap dibaca',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  highCount > 0
                      ? '$highCount bunga perlu perhatian stok lebih awal.'
                      : 'Prediksi membantu perkiraan stok, bukan angka pasti.',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.2,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionInlineError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _PredictionInlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba'),
          ),
        ],
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final PredictionSummary prediction;
  final NumberFormat numberFmt;
  final _PredictionFilter level;
  final VoidCallback? onOpenStock;

  const _PredictionCard({
    required this.prediction,
    required this.numberFmt,
    required this.level,
    required this.onOpenStock,
  });

  Color get _levelColor {
    switch (level) {
      case _PredictionFilter.high:
        return AppTheme.primary;
      case _PredictionFilter.medium:
        return AppTheme.success;
      case _PredictionFilter.low:
      case _PredictionFilter.all:
        return AppTheme.info;
    }
  }

  IconData get _levelIcon {
    switch (level) {
      case _PredictionFilter.high:
        return Icons.trending_up_rounded;
      case _PredictionFilter.medium:
        return Icons.show_chart_rounded;
      case _PredictionFilter.low:
      case _PredictionFilter.all:
        return Icons.trending_flat_rounded;
    }
  }

  String get _levelLabel {
    switch (level) {
      case _PredictionFilter.high:
        return 'Kebutuhan tinggi';
      case _PredictionFilter.medium:
        return 'Kebutuhan sedang';
      case _PredictionFilter.low:
      case _PredictionFilter.all:
        return 'Kebutuhan ringan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _levelColor;
    final demand = prediction.predictedDemand.round();
    final confidence = (prediction.confidence.clamp(0, 1) * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF5C6D8)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child:
                    Icon(Icons.local_florist_rounded, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.flowerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Bunga Potong',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              _PredictionBadge(
                icon: _levelIcon,
                label: _levelLabel,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PredictionMetric(
                  label: 'Prediksi',
                  value: '${numberFmt.format(demand)} tangkai',
                  icon: Icons.inventory_2_rounded,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PredictionMetric(
                  label: 'Keyakinan',
                  value: '$confidence%',
                  icon: Icons.verified_rounded,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: prediction.confidence.clamp(0, 1),
              backgroundColor: const Color(0xFFFFE1ED),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 7,
            ),
          ),
          if (prediction.recommendation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF5C6D8)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_rounded,
                    size: 17,
                    color: AppTheme.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      prediction.recommendation,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Cek stok sebelum keputusan restok.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onOpenStock,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Cek Stok'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  minimumSize: const Size(44, 38),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PredictionBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PredictionBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 142, minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PredictionMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionStatePanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _PredictionStatePanel({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(28, 56, 28, 96),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(132, 44),
                    elevation: 0,
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PredictionSkeletonList extends StatelessWidget {
  const _PredictionSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const _PredictionSkeletonCard(),
    );
  }
}

class _PredictionSkeletonCard extends StatelessWidget {
  const _PredictionSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF5C6D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD9E8).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonLine(width: 130, height: 14),
                    SizedBox(height: 8),
                    _SkeletonLine(width: 86, height: 10, alpha: 0.42),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                  child: _SkeletonLine(width: double.infinity, height: 36)),
              SizedBox(width: 8),
              Expanded(
                  child: _SkeletonLine(width: double.infinity, height: 36)),
            ],
          ),
          const SizedBox(height: 14),
          const _SkeletonLine(width: double.infinity, height: 7, alpha: 0.42),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  final double alpha;

  const _SkeletonLine({
    required this.width,
    required this.height,
    this.alpha = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD9E8).withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
