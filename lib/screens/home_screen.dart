import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/prediction_provider.dart';
import '../providers/stock_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/florashop_logo.dart';
import 'profile_screen.dart';

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

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPrediksi;
  final VoidCallback? onNavigateToStock;
  final VoidCallback? onNavigateToLowStock;
  final VoidCallback? onNavigateToTransactions;

  const HomeScreen({
    super.key,
    this.onNavigateToPrediksi,
    this.onNavigateToStock,
    this.onNavigateToLowStock,
    this.onNavigateToTransactions,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _summary;
  bool _loadingSummary = true;
  DateTime? _lastUpdatedAt;
  Timer? _clockTimer;
  OverlayEntry? _noticeEntry;

  final NumberFormat _numberFmt = NumberFormat.decimalPattern('id_ID');

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _clockTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _noticeEntry?.remove();
    _noticeEntry = null;
    _clockTimer?.cancel();
    super.dispose();
  }

  int _summaryInt(String key) {
    final value = _summary?[key];
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final normalized = value.replaceAll(RegExp(r'[^0-9-]'), '');
      return int.tryParse(normalized) ?? 0;
    }
    return 0;
  }

  String _formatSummaryNumber(String key) {
    return _numberFmt.format(_summaryInt(key));
  }

  String _getTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color _predictionColor(int index) {
    const colors = [
      Color(0xFFE8185A),
      Color(0xFF7DBE89),
      Color(0xFF8B5CF6),
    ];

    return colors[index % colors.length];
  }

  String _formatPredictionDetail(PredictionSummary prediction) {
    final value = prediction.predictedDemand.round();
    return '$value tangkai';
  }

  bool get _isDataStale {
    final updatedAt = _lastUpdatedAt;
    if (updatedAt == null) return false;
    return DateTime.now().difference(updatedAt).inMinutes >= 5;
  }

  Color _systemStatusColor(int lowStockCount) {
    if (_summary == null && !_loadingSummary) return AppTheme.error;
    if (_loadingSummary) return AppTheme.primary;
    if (lowStockCount > 0 || _isDataStale) return AppTheme.warning;
    return AppTheme.success;
  }

  String _systemStatusLabel(int lowStockCount) {
    if (_summary == null && !_loadingSummary) return 'Server perlu dicek';
    if (_loadingSummary) return 'Memuat data';
    if (lowStockCount > 0) return 'Perlu restok';
    if (_isDataStale) return 'Perlu refresh';
    return 'Aman, stok terkendali';
  }

  void _showCenterNotice({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    _noticeEntry?.remove();
    final entry = OverlayEntry(
      builder: (context) => _CenterNotice(
        title: title,
        message: message,
        icon: icon,
        color: color,
      ),
    );
    _noticeEntry = entry;

    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      if (_noticeEntry == entry) {
        entry.remove();
        _noticeEntry = null;
      }
    });
  }

  Future<bool> _loadSummary({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() {
        _loadingSummary = true;
      });
    }

    var success = false;
    try {
      final resp = await ApiService.getDashboardSummary();
      if (mounted) {
        setState(() {
          _summary = resp['data'];
          _lastUpdatedAt = DateTime.now();
        });
      }
      success = true;
    } catch (_) {
      if (mounted) {
        setState(() {
          _summary = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingSummary = false;
        });
      }
    }

    return success;
  }

  Future<void> _retryDashboard() async {
    await _loadSummary(showLoading: true);
  }

  Widget _buildHeader(
    String greeting,
    String name,
    DateTime? lastUpdatedAt,
    String systemStatus,
    Color systemStatusColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB11E5C).withValues(alpha: 0.16),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            Container(
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
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      FloraShopLogo(size: 34, showShadow: false),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FLORASHOP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Poppins',
                              letterSpacing: 0,
                            ),
                          ),
                          Text(
                            'Beranda',
                            style: TextStyle(
                              color: Color(0xFFFFD9EA),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Semantics(
                    button: true,
                    label: 'Buka profil',
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body - pink muda
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF7FB), Color(0xFFFCE4EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, selamat datang kembali',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFA0506E),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Halo, $name!',
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3D1326),
                            fontFamily: 'Poppins',
                            height: 1.05,
                            letterSpacing: 0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    constraints: const BoxConstraints(minWidth: 74),
                    padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFFFFD2E3).withValues(alpha: 0.9),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _getTime(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            fontFamily: 'Poppins',
                            height: 0.98,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'WIB',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFFA0506E),
                            letterSpacing: 0.7,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              decoration: const BoxDecoration(
                color: Color(0xFFFFEEF6),
                border: Border(
                  top: BorderSide(color: Color(0xFFF5C6D8), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Sistem',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFA0506E),
                          fontFamily: 'Poppins',
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lastUpdatedAt == null
                            ? 'Menunggu data terbaru'
                            : _isDataStale
                                ? 'Diperbarui ${_formatTime(lastUpdatedAt)} - perlu refresh'
                                : 'Diperbarui ${_formatTime(lastUpdatedAt)}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFFC06B8F),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: systemStatusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            systemStatus,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFA0506E),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final stock = context.watch<StockProvider>();
    final predictions = context.watch<PredictionProvider>();

    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Selamat Pagi'
        : now.hour < 17
            ? 'Selamat Siang'
            : 'Selamat Sore';

    final lowStockCount = _summaryInt('low_stock');
    final quickPredictions = predictions.predictions.take(3).toList();
    final systemStatus = _systemStatusLabel(lowStockCount);
    final systemStatusColor = _systemStatusColor(lowStockCount);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: DecoratedBox(
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
        child: SafeArea(
          child: ScrollConfiguration(
            behavior: const _NoStretchScrollBehavior(),
            child: RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: Colors.white,
              displacement: 36,
              edgeOffset: 8,
              onRefresh: () async {
                final summaryOk = await _loadSummary();
                await stock.loadStocks(refresh: true);
                await predictions.loadPredictions();
                if (!mounted) return;

                final allOk = summaryOk &&
                    stock.errorMessage == null &&
                    predictions.errorMessage == null;

                _showCenterNotice(
                  title: allOk
                      ? 'Data beranda diperbarui'
                      : 'Data belum bisa diperbarui',
                  message: allOk
                      ? 'Ringkasan toko sudah memakai data terbaru.'
                      : 'Server toko belum bisa dijangkau. Coba lagi sebentar.',
                  icon: allOk
                      ? Icons.check_circle_rounded
                      : Icons.cloud_off_rounded,
                  color: allOk ? AppTheme.success : AppTheme.error,
                );
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(20),
                children: [
                  // Header Baru
                  _buildHeader(
                    greeting,
                    auth.user?.name ?? 'Pengguna',
                    _lastUpdatedAt,
                    systemStatus,
                    systemStatusColor,
                  ),
                  const SizedBox(height: 24),

                  if (_loadingSummary)
                    const _DashboardSkeleton()
                  else if (_summary == null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.cloud_off_rounded,
                              color: AppTheme.error,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Server toko belum bisa dijangkau. Periksa koneksi atau coba lagi.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: _retryDashboard,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(62, 42),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            child: const Text(
                              'Coba lagi',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.error,
                                fontFamily: 'Poppins',
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Total Transaksi',
                            value: _formatSummaryNumber('transactions'),
                            icon: Icons.receipt_long,
                            color: const Color(0xFF3F51B5),
                            bgColor: const Color(0xFFE8EAF6),
                            semanticsLabel: 'Buka riwayat transaksi',
                            onTap: widget.onNavigateToTransactions,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Jenis Bunga',
                            value: _formatSummaryNumber('flower_types'),
                            icon: Icons.local_florist,
                            color: const Color(0xFF4CAF50),
                            bgColor: const Color(0xFFE8F5E9),
                            semanticsLabel: 'Buka stok bunga',
                            onTap: widget.onNavigateToStock,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Total Prediksi',
                            value: _formatSummaryNumber('total_prediction'),
                            icon: Icons.auto_graph,
                            color: const Color(0xFF9C27B0),
                            bgColor: const Color(0xFFF3E5F5),
                            semanticsLabel: 'Buka prediksi penjualan',
                            onTap: widget.onNavigateToPrediksi,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Low Stock',
                            value: _formatSummaryNumber('low_stock'),
                            icon: Icons.warning_amber_outlined,
                            color: lowStockCount > 0
                                ? const Color(0xFFFF7043)
                                : const Color(0xFF4CAF50),
                            bgColor: lowStockCount > 0
                                ? const Color(0xFFFBE9E7)
                                : const Color(0xFFE8F5E9),
                            semanticsLabel: lowStockCount > 0
                                ? 'Buka stok kritis'
                                : 'Buka stok bunga',
                            onTap: lowStockCount > 0
                                ? widget.onNavigateToLowStock
                                : widget.onNavigateToStock,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Low stock status
                  if (!_loadingSummary && _summary != null) ...[
                    const SizedBox(height: 20),
                    _StockStatusBanner(
                      count: lowStockCount,
                      onTap: lowStockCount > 0
                          ? widget.onNavigateToLowStock
                          : widget.onNavigateToStock,
                    ),
                  ],

                  // Prediksi Singkat
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Prediksi Singkat',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                          letterSpacing: 0,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onNavigateToPrediksi,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(86, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF4BDD3)),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFB11E5C).withValues(alpha: 0.08),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: predictions.isLoading
                          ? const _PredictionSkeleton()
                          : predictions.errorMessage != null
                              ? _PredictionStateRow(
                                  icon: Icons.cloud_off_rounded,
                                  title: 'Prediksi belum bisa dimuat',
                                  subtitle:
                                      'Tarik layar ke bawah untuk mencoba lagi.',
                                  color: AppTheme.error,
                                  actionLabel: 'Buka Prediksi',
                                  onAction: widget.onNavigateToPrediksi,
                                )
                              : quickPredictions.isEmpty
                                  ? const _PredictionStateRow(
                                      icon: Icons.insights_rounded,
                                      title: 'Data prediksi belum tersedia',
                                      subtitle:
                                          'Jalankan prediksi dari web admin agar tampil di sini.',
                                      color: AppTheme.info,
                                    )
                                  : Column(
                                      children: quickPredictions
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final index = entry.key;
                                        final pred = entry.value;
                                        final color = _predictionColor(index);
                                        final isLast = index ==
                                            quickPredictions.length - 1;

                                        return Column(
                                          children: [
                                            _PredictionRow(
                                              name: pred.flowerName,
                                              icon: Icons.local_florist_rounded,
                                              iconColor: color,
                                              subtitle:
                                                  'Perkiraan kebutuhan hari ini',
                                              status: 'Siapkan',
                                              statusColor: AppTheme.success,
                                              detail:
                                                  _formatPredictionDetail(pred),
                                            ),
                                            if (!isLast)
                                              const Divider(
                                                height: 1,
                                                indent: 16,
                                                endIndent: 16,
                                                color: AppTheme.border,
                                              ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterNotice extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const _CenterNotice({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: SafeArea(
          child: Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.96 + (value * 0.04),
                    child: child,
                  ),
                );
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width - 48,
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.28)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5D1734).withValues(alpha: 0.16),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                fontFamily: 'Poppins',
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              message,
                              style: const TextStyle(
                                fontSize: 11.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                                fontFamily: 'Poppins',
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StockStatusBanner extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const _StockStatusBanner({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCriticalStock = count > 0;
    final color = hasCriticalStock ? AppTheme.warning : AppTheme.success;
    final icon = hasCriticalStock
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;
    final text = hasCriticalStock
        ? '$count jenis bunga stok kritis. Cek sekarang.'
        : 'Tidak ada stok kritis saat ini.';

    return Semantics(
      button: true,
      label: hasCriticalStock ? 'Buka daftar stok kritis' : 'Buka stok bunga',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: hasCriticalStock ? 0.13 : 0.11),
                  Colors.white.withValues(alpha: 0.78),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Poppins',
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.82),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const _SkeletonPulse(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _StatSkeletonCard()),
              SizedBox(width: 12),
              Expanded(child: _StatSkeletonCard()),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatSkeletonCard()),
              SizedBox(width: 12),
              Expanded(child: _StatSkeletonCard()),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatSkeletonCard extends StatelessWidget {
  const _StatSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 36, height: 36, radius: 12),
          SizedBox(height: 12),
          _SkeletonBox(width: 76, height: 18, radius: 8),
          SizedBox(height: 8),
          _SkeletonBox(width: 92, height: 11, radius: 6),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.semanticsLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: semanticsLabel ?? '$label, $value',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  bgColor,
                  Colors.white.withValues(alpha: 0.74),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 112),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.62),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Icon(icon, size: 18, color: color),
                        ),
                        if (onTap != null) ...[
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: color.withValues(alpha: 0.42),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: color,
                        fontFamily: 'Poppins',
                        letterSpacing: 0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        fontFamily: 'Poppins',
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PredictionStateRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PredictionStateRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Poppins',
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                    fontFamily: 'Poppins',
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 42),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFamily: 'Poppins',
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PredictionSkeleton extends StatelessWidget {
  const _PredictionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const _SkeletonPulse(
      child: Column(
        children: [
          _PredictionSkeletonRow(),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: AppTheme.border,
          ),
          _PredictionSkeletonRow(),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: AppTheme.border,
          ),
          _PredictionSkeletonRow(),
        ],
      ),
    );
  }
}

class _PredictionSkeletonRow extends StatelessWidget {
  const _PredictionSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          _SkeletonBox(width: 42, height: 42, radius: 21),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: 92, height: 13, radius: 7),
                SizedBox(height: 7),
                _SkeletonBox(width: 132, height: 10, radius: 6),
              ],
            ),
          ),
          SizedBox(width: 10),
          _SkeletonBox(width: 62, height: 24, radius: 12),
        ],
      ),
    );
  }
}

class _SkeletonPulse extends StatefulWidget {
  final Widget child;

  const _SkeletonPulse({required this.child});

  @override
  State<_SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<_SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.58, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD9E8).withValues(alpha: 0.72),
            Colors.white.withValues(alpha: 0.88),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _PredictionRow extends StatelessWidget {
  final String name;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final String status;
  final Color statusColor;
  final String detail;

  const _PredictionRow({
    required this.name,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.status,
    required this.statusColor,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  iconColor.withValues(alpha: 0.18),
                  iconColor.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Poppins',
                    letterSpacing: 0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      letterSpacing: 0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
