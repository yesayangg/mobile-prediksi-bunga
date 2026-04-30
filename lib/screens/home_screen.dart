import 'package:flower_shop/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/stock_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _summary;
  bool _loadingSummary = true;
  final _currencyFmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
                        Text(greeting,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontFamily: 'Poppins')),
                        Text(
                          auth.user?.name ?? 'Pengguna',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              fontFamily: 'Poppins'),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            auth.user?.role.label ?? '',
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: const Icon(Icons.person_outline,
                        color: AppTheme.primary),
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
                        label: 'Transaksi',
                        value: _summary?['today_transactions']?.toString() ?? '0',
                        icon: Icons.receipt_long,
                        color: AppTheme.info,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Pendapatan',
                        value: _currencyFmt.format(_summary?['today_revenue'] ?? 0),
                        icon: Icons.attach_money,
                        color: AppTheme.success,
                        isSmallText: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Jenis Bunga',
                        value: stock.stocks.length.toString(),
                        icon: Icons.inventory_2_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Stok Kritis',
                        value: stock.lowStockCount.toString(),
                        icon: Icons.warning_amber_outlined,
                        color: stock.lowStockCount > 0
                            ? AppTheme.warning
                            : AppTheme.success,
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
                    border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
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
                const SizedBox(height: 16),
                const Text('Stok Kritis',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontFamily: 'Poppins')),
                const SizedBox(height: 8),
                ...stock.lowStockItems.take(3).map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.local_florist,
                                  color: AppTheme.warning, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                          fontFamily: 'Poppins')),
                                  Text(item.category,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                          fontFamily: 'Poppins')),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.isOutOfStock
                                    ? AppTheme.error
                                    : AppTheme.warning,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.isOutOfStock
                                    ? 'Habis'
                                    : '${item.stock} ${item.unit}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isSmallText;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isSmallText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: isSmallText ? 13 : 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Poppins'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}