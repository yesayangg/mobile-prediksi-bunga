import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/flower_stock.dart';
import '../providers/stock_provider.dart';
import '../theme/app_theme.dart';
import 'add_stock_sheet.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _searchCtrl = TextEditingController();
  final _currencyFmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  DateTime? _lastUpdatedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStocks();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshStocks() async {
    final stockProvider = context.read<StockProvider>();
    await stockProvider.loadStocks(refresh: true);

    if (!mounted) return;
    if (stockProvider.errorMessage == null) {
      setState(() => _lastUpdatedAt = DateTime.now());
    }
  }

  String _formatTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _summaryText(StockProvider provider) {
    final isSearching = provider.searchQuery.trim().isNotEmpty;

    if (isSearching) {
      return '${provider.stocks.length} hasil ditemukan';
    }

    if (provider.isLowStockFilter) {
      return '${provider.stocks.length} stok kritis';
    }

    if (provider.selectedCategory == 'tersedia') {
      return '${provider.stocks.length} bunga tersedia';
    }

    return '${provider.totalCount} jenis bunga';
  }

  String _emptyTitle(StockProvider provider) {
    if (provider.searchQuery.trim().isNotEmpty) return 'Bunga tidak ditemukan';
    if (provider.isLowStockFilter) return 'Tidak ada stok kritis';
    if (provider.selectedCategory == 'tersedia') {
      return 'Belum ada stok tersedia';
    }
    return 'Belum ada stok bunga';
  }

  String _emptySubtitle(StockProvider provider) {
    if (provider.searchQuery.trim().isNotEmpty) {
      return 'Coba kata kunci lain atau kosongkan pencarian.';
    }
    if (provider.isLowStockFilter) {
      return 'Aman, stok terkendali untuk saat ini.';
    }
    return 'Tekan tombol tambah untuk memperbarui stok toko.';
  }

  void _showAddStockSheet(StockProvider stockProvider) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddStockSheet(
        existingStocks: stockProvider.allStocks,
      ),
    );

    if (result == true && mounted) {
      await _refreshStocks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockProvider = context.watch<StockProvider>();

    if (_searchCtrl.text != stockProvider.searchQuery) {
      _searchCtrl.value = TextEditingValue(
        text: stockProvider.searchQuery,
        selection: TextSelection.collapsed(
          offset: stockProvider.searchQuery.length,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(154),
        child: _StockHeader(
          isLoading: stockProvider.isLoading,
          updatedLabel: _lastUpdatedAt == null
              ? 'Menunggu sinkronisasi'
              : 'Diperbarui ${_formatTime(_lastUpdatedAt!)}',
          activeFilter: stockProvider.isLowStockFilter
              ? StockFilter.low
              : stockProvider.selectedCategory == 'tersedia'
                  ? StockFilter.available
                  : StockFilter.all,
          onRefresh: _refreshStocks,
          onSelectAll: () {
            stockProvider.toggleLowStockFilter(false);
            stockProvider.filterByCategory(null);
          },
          onSelectAvailable: stockProvider.filterAvailable,
          onSelectLowStock: () => stockProvider.toggleLowStockFilter(true),
        ),
      ),
      floatingActionButton: Semantics(
        button: true,
        label: 'Tambah atau perbarui stok bunga',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.32),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: FloatingActionButton(
            elevation: 0,
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onPressed: () => _showAddStockSheet(stockProvider),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _SearchBox(
                controller: _searchCtrl,
                onChanged: stockProvider.search,
                onClear: () {
                  _searchCtrl.clear();
                  stockProvider.search('');
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: _StockSummaryStrip(
                summary: _summaryText(stockProvider),
                lowStockCount: stockProvider.lowStockCount,
                outOfStockCount: stockProvider.outOfStockCount,
              ),
            ),
            if (stockProvider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: _StockErrorBanner(onRetry: _refreshStocks),
              ),
            Expanded(
              child: _StockContent(
                provider: stockProvider,
                currencyFmt: _currencyFmt,
                onRefresh: _refreshStocks,
                emptyTitle: _emptyTitle(stockProvider),
                emptySubtitle: _emptySubtitle(stockProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum StockFilter { all, available, low }

class _StockHeader extends StatelessWidget {
  final bool isLoading;
  final String updatedLabel;
  final StockFilter activeFilter;
  final VoidCallback onRefresh;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectAvailable;
  final VoidCallback onSelectLowStock;

  const _StockHeader({
    required this.isLoading,
    required this.updatedLabel,
    required this.activeFilter,
    required this.onRefresh,
    required this.onSelectAll,
    required this.onSelectAvailable,
    required this.onSelectLowStock,
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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stok Bunga',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          updatedLabel,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
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
                    label: 'Perbarui data stok',
                    child: InkWell(
                      onTap: isLoading ? null : onRefresh,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
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
                                size: 21,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF5D1734).withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _HeaderFilterChip(
                      label: 'Semua',
                      icon: Icons.grid_view_rounded,
                      isSelected: activeFilter == StockFilter.all,
                      onTap: onSelectAll,
                    ),
                    _HeaderFilterChip(
                      label: 'Tersedia',
                      icon: Icons.check_circle_outline_rounded,
                      isSelected: activeFilter == StockFilter.available,
                      onTap: onSelectAvailable,
                    ),
                    _HeaderFilterChip(
                      label: 'Stok Kritis',
                      icon: Icons.warning_amber_rounded,
                      isSelected: activeFilter == StockFilter.low,
                      onTap: onSelectLowStock,
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

class _HeaderFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _HeaderFilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'Filter $label',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(13),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: isSelected
                        ? AppTheme.primary
                        : Colors.white.withValues(alpha: 0.72),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.white.withValues(alpha: 0.72),
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

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            letterSpacing: 0,
          ),
          decoration: InputDecoration(
            hintText: 'Cari bunga...',
            hintStyle: const TextStyle(
              color: AppTheme.textHint,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Bersihkan pencarian',
                    onPressed: onClear,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textSecondary,
                      size: 18,
                    ),
                  ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.9),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFF5C6D8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
            ),
          ),
        );
      },
    );
  }
}

class _StockSummaryStrip extends StatelessWidget {
  final String summary;
  final int lowStockCount;
  final int outOfStockCount;

  const _StockSummaryStrip({
    required this.summary,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            summary,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              letterSpacing: 0,
            ),
          ),
        ),
        if (outOfStockCount > 0)
          _SummaryBadge(
            label: '$outOfStockCount habis',
            color: AppTheme.error,
          ),
        if (outOfStockCount > 0 && lowStockCount > 0) const SizedBox(width: 8),
        if (lowStockCount > 0)
          _SummaryBadge(
            label: '$lowStockCount kritis',
            color: const Color(0xFFC68A14),
          ),
      ],
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SummaryBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          fontFamily: 'Poppins',
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _StockContent extends StatelessWidget {
  final StockProvider provider;
  final NumberFormat currencyFmt;
  final Future<void> Function() onRefresh;
  final String emptyTitle;
  final String emptySubtitle;

  const _StockContent({
    required this.provider,
    required this.currencyFmt,
    required this.onRefresh,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.stocks.isEmpty) {
      return const _StockSkeletonList();
    }

    if (provider.errorMessage != null && provider.stocks.isEmpty) {
      return _FullStockError(onRetry: onRefresh);
    }

    if (provider.stocks.isEmpty) {
      return _StockEmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      backgroundColor: Colors.white,
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 96),
        itemCount: provider.stocks.length,
        itemBuilder: (_, i) {
          final item = provider.stocks[i];
          return _StockCard(
            item: item,
            currencyFmt: currencyFmt,
          );
        },
      ),
    );
  }
}

class _StockErrorBanner extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _StockErrorBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppTheme.error,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Data stok belum bisa diperbarui.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: 0,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              minimumSize: const Size(58, 40),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'Coba lagi',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppTheme.error,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullStockError extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _FullStockError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(28, 52, 28, 96),
      children: [
        _StatePanel(
          icon: Icons.cloud_off_rounded,
          color: AppTheme.error,
          title: 'Server toko belum bisa dijangkau',
          subtitle: 'Pastikan internet aktif atau minta admin mengecek server.',
          actionLabel: 'Coba lagi',
          onAction: onRetry,
        ),
      ],
    );
  }
}

class _StockEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _StockEmptyState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(28, 52, 28, 96),
      children: [
        _StatePanel(
          icon: Icons.local_florist_outlined,
          color: AppTheme.primary,
          title: title,
          subtitle: subtitle,
        ),
      ],
    );
  }
}

class _StatePanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _StatePanel({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB11E5C).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 28),
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
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _StockSkeletonList extends StatelessWidget {
  const _StockSkeletonList();

  @override
  Widget build(BuildContext context) {
    return const _SkeletonPulse(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 96),
        child: Column(
          children: [
            _StockSkeletonCard(),
            SizedBox(height: 12),
            _StockSkeletonCard(),
            SizedBox(height: 12),
            _StockSkeletonCard(),
            SizedBox(height: 12),
            _StockSkeletonCard(),
          ],
        ),
      ),
    );
  }
}

class _StockSkeletonCard extends StatelessWidget {
  const _StockSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      child: const Row(
        children: [
          _SkeletonBox(width: 52, height: 52, radius: 17),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SkeletonBox(width: 108, height: 14, radius: 8),
                SizedBox(height: 9),
                _SkeletonBox(width: 78, height: 10, radius: 6),
                SizedBox(height: 13),
                _SkeletonBox(width: 168, height: 13, radius: 7),
              ],
            ),
          ),
          SizedBox(width: 12),
          _SkeletonBox(width: 58, height: 25, radius: 13),
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
      duration: const Duration(milliseconds: 1050),
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
            const Color(0xFFFFD9E8).withValues(alpha: 0.74),
            Colors.white.withValues(alpha: 0.9),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(radius),
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
        return const Color(0xFFC68A14);
      case StockStatus.normal:
        return AppTheme.success;
    }
  }

  Color get _statusBgColor {
    switch (item.status) {
      case StockStatus.outOfStock:
        return const Color(0xFFFFEEF0);
      case StockStatus.low:
        return const Color(0xFFFFF6DF);
      case StockStatus.normal:
        return const Color(0xFFEAF7EF);
    }
  }

  String get _statusLabel {
    switch (item.status) {
      case StockStatus.outOfStock:
        return 'Habis';
      case StockStatus.low:
        return 'Kritis';
      case StockStatus.normal:
        return 'Aman';
    }
  }

  String _formatUpdatedAt(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${item.name}, stok ${item.stock} ${item.unit}, status $_statusLabel',
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: item.isLowStock
                ? _statusColor.withValues(alpha: 0.28)
                : const Color(0xFFF5C6D8),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  _statusColor.withValues(alpha: item.isLowStock ? 0.12 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StockThumb(item: item, color: _statusColor),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.5,
                                  color: AppTheme.textPrimary,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.category,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(
                          label: _statusLabel,
                          color: _statusColor,
                          bgColor: _statusBgColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.inventory_2_outlined,
                          label: '${item.stock} ${item.unit}',
                          color: _statusColor,
                        ),
                        _InfoChip(
                          icon: Icons.flag_outlined,
                          label: 'Min ${item.minStock}',
                          color: AppTheme.textSecondary,
                        ),
                        _InfoChip(
                          icon: Icons.sell_outlined,
                          label: currencyFmt.format(item.price),
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          item.isLowStock
                              ? Icons.priority_high_rounded
                              : Icons.check_rounded,
                          size: 14,
                          color: _statusColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.isLowStock
                                ? 'Perlu dicek sebelum transaksi ramai'
                                : 'Stok aman untuk transaksi',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10.8,
                              fontWeight: FontWeight.w600,
                              color: _statusColor,
                              letterSpacing: 0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Update ${_formatUpdatedAt(item.updatedAt)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textHint,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
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

class _StockThumb extends StatelessWidget {
  final FlowerStock item;
  final Color color;

  const _StockThumb({
    required this.item,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: imageUrl == null || imageUrl.isEmpty
            ? Icon(Icons.local_florist_rounded, color: color, size: 26)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.local_florist_rounded, color: color, size: 26),
              ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          fontFamily: 'Poppins',
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.2,
              color: color,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
