import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stock_provider.dart';
import '../models/flower_stock.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'add_stock_sheet.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _searchCtrl = TextEditingController();
  final _currencyFmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = context.watch<StockProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📦 Stok Bunga 🌹'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => stockProvider.loadStocks(refresh: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () async {
          final result = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddStockSheet(
              existingStocks: stockProvider.stocks,
            ),
          );
          if (result == true) {
            stockProvider.loadStocks(refresh: true);
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: stockProvider.search,
                  decoration: const InputDecoration(
                    hintText: 'Cari bunga...',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: 'Semua',
                        isSelected: true,
                        onTap: () => stockProvider.filterByCategory(null),
                      ),
                      _FilterChip(
                        label: 'Stok Kritis',
                        isSelected: false,
                        onTap: () => stockProvider.toggleLowStockFilter(true),
                        isWarning: true,
                      ),
                      ...stockProvider.categories.map(
                        (cat) => _FilterChip(
                          label: cat,
                          isSelected: false,
                          onTap: () => stockProvider.filterByCategory(cat),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${stockProvider.stocks.length} jenis bunga',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
                const Spacer(),
                if (stockProvider.lowStockCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${stockProvider.lowStockCount} kritis',
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: stockProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : stockProvider.stocks.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_florist_outlined,
                                size: 48, color: AppTheme.textHint),
                            SizedBox(height: 12),
                            Text(
                              'Tidak ada stok ditemukan',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            stockProvider.loadStocks(refresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: stockProvider.stocks.length,
                          itemBuilder: (_, i) {
                            final item = stockProvider.stocks[i];
                            return _StockCard(
                              item: item,
                              currencyFmt: _currencyFmt,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final FlowerStock item;
  final NumberFormat currencyFmt;

  const _StockCard({required this.item, required this.currencyFmt});

  Color get _statusColor {
    switch (item.status) {
      case StockStatus.outOfStock:
        return AppTheme.error;
      case StockStatus.low:
        return AppTheme.warning;
      case StockStatus.normal:
        return AppTheme.success;
    }
  }

  String get _statusLabel {
    switch (item.status) {
      case StockStatus.outOfStock:
        return 'Habis';
      case StockStatus.low:
        return 'Kritis';
      case StockStatus.normal:
        return 'Normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              item.isLowStock ? _statusColor.withOpacity(0.3) : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_florist, color: _statusColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.inventory_2_outlined,
                      label: '${item.stock} ${item.unit}',
                      color: _statusColor,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.sell_outlined,
                      label: currencyFmt.format(item.price),
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isWarning;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? AppTheme.warning : AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
