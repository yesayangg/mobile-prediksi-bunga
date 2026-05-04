import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPrediksi;

  const HomeScreen({super.key, this.onNavigateToPrediksi});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _summary;
  bool _loadingSummary = true;
  final _currencyFmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final List<Map<String, dynamic>> _predictions = [
    {
      'name': 'Mawar',
      'icon': Icons.local_florist,
      'color': Color(0xFFE53935),
      'status': 'Naik',
      'statusColor': Color(0xFF4CAF50),
      'detail': 'Besok',
    },
    {
      'name': 'Melati',
      'icon': Icons.spa,
      'color': Color(0xFFFFA726),
      'status': 'Stabil',
      'statusColor': Color(0xFF42A5F5),
      'detail': '0 tlk',
    },
    {
      'name': 'Anggrek',
      'icon': Icons.emoji_nature,
      'color': Color(0xFFAB47BC),
      'status': 'Turun',
      'statusColor': Color(0xFFEF5350),
      'detail': '-Besok',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final resp = await ApiService.getDashboardSummary();
      if (mounted) setState(() => _summary = resp['data']);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final stock = context.watch<StockProvider>();
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Selamat Pagi'
        : now.hour < 17
            ? 'Selamat Siang'
            : 'Selamat Sore';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏠 Beranda 🌸'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadSummary();
            await stock.loadStocks(refresh: true);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Greeting Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${auth.user?.name ?? 'Pengguna'}!',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              fontFamily: 'Poppins'),
                        ),
                        Row(
                          children: [
                            Text(
                              '$greeting, selamat datang kembali ',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontFamily: 'Poppins'),
                            ),
                            const Text('👋', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: const Icon(Icons.person_outline,
                          color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats
              const Text('Ringkasan Hari Ini',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 12),

              if (_loadingSummary)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Penjualan Hari Ini',
                        value: _currencyFmt
                            .format(_summary?['today_revenue'] ?? 0),
                        icon: Icons.trending_up,
                        color: const Color(0xFF4CAF50),
                        bgColor: const Color(0xFFE8F5E9),
                        isSmallText: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Transaksi',
                        value:
                            _summary?['today_transactions']?.toString() ?? '0',
                        icon: Icons.receipt_long,
                        color: const Color(0xFF3F51B5),
                        bgColor: const Color(0xFFE8EAF6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Stok Hampir Habis',
                        value: stock.lowStockCount.toString(),
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFFFF7043),
                        bgColor: const Color(0xFFFBE9E7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Akurasi Prediksi',
                        value: '${_summary?['prediction_accuracy'] ?? 85}%',
                        icon: Icons.auto_graph,
                        color: const Color(0xFF9C27B0),
                        bgColor: const Color(0xFFF3E5F5),
                      ),
                    ),
                  ],
                ),
              ],

              // Low stock alert
              if (stock.lowStockCount > 0) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppTheme.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          color: AppTheme.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${stock.lowStockCount} bunga hampir habis. Segera restok!',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              fontFamily: 'Poppins'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Prediksi Singkat ──
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Prediksi Singkat',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins')),
                  TextButton(
                    onPressed: widget.onNavigateToPrediksi,
                    child: const Text('Lihat Semua',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontFamily: 'Poppins')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: _predictions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final pred = entry.value;
                    final isLast = index == _predictions.length - 1;
                    return Column(
                      children: [
                        _PredictionRow(
                          name: pred['name'],
                          icon: pred['icon'],
                          iconColor: pred['color'],
                          status: pred['status'],
                          statusColor: pred['statusColor'],
                          detail: pred['detail'],
                        ),
                        if (!isLast)
                          Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: AppTheme.border),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isSmallText;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.isSmallText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
                fontSize: isSmallText ? 13 : 20,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'Poppins'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }
}

// ── Prediction Row ─────────────────────────────────────────────────────────

class _PredictionRow extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color iconColor;
  final String status;
  final Color statusColor;
  final String detail;

  const _PredictionRow({
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.status,
    required this.statusColor,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Poppins'),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins'),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            detail,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }
}