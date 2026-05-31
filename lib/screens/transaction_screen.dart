import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/stock_provider.dart';
import '../models/flower_stock.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../widgets/florashop_logo.dart';
import 'transaction_history.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_popup.dart';

String _getFlowerEmoji(String name) {
  final n = name.toLowerCase();
  if (n.contains('mawar')) return '🌹';
  if (n.contains('tulip')) return '🌷';
  if (n.contains('matahari')) return '🌻';
  if (n.contains('krisan')) return '🌼';
  if (n.contains('anggrek')) return '🌸';
  if (n.contains('melati')) return '🤍';
  if (n.contains('lily') || n.contains('lili')) return '💐';
  return '🌺';
}

Color _getFlowerBgColor(String name) {
  final n = name.toLowerCase();
  if (n.contains('mawar')) return const Color(0xFFFFF0F5);
  if (n.contains('tulip')) return const Color(0xFFF5F0FF);
  if (n.contains('matahari')) return const Color(0xFFFFFBF0);
  if (n.contains('krisan')) return const Color(0xFFF0FFF5);
  if (n.contains('anggrek')) return const Color(0xFFFFF0FA);
  if (n.contains('melati')) return const Color(0xFFFFFFF0);
  if (n.contains('lily') || n.contains('lili')) return const Color(0xFFF0F5FF);
  return const Color(0xFFFFF0F8);
}

Color _getFlowerIconBgColor(String name) {
  final n = name.toLowerCase();
  if (n.contains('mawar')) return const Color(0xFFFFD6E7);
  if (n.contains('tulip')) return const Color(0xFFE8D6FF);
  if (n.contains('matahari')) return const Color(0xFFFFF0B3);
  if (n.contains('krisan')) return const Color(0xFFD6FFE8);
  if (n.contains('anggrek')) return const Color(0xFFFFD6F5);
  if (n.contains('melati')) return const Color(0xFFFFFDD6);
  if (n.contains('lily') || n.contains('lili')) return const Color(0xFFD6E8FF);
  return const Color(0xFFFFD6EE);
}

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

String _friendlyTransactionError(String? message) {
  if (message == null || message.trim().isEmpty) {
    return 'Transaksi belum bisa diproses. Coba lagi sebentar.';
  }

  final lower = message.toLowerCase();
  if (lower.contains('socket') ||
      lower.contains('timeout') ||
      lower.contains('connection') ||
      lower.contains('failed host') ||
      lower.contains('xmlhttprequest')) {
    return 'Server toko belum bisa dijangkau. Pastikan internet aktif atau hubungi admin.';
  }

  if (lower.contains('stok') || lower.contains('stock')) {
    return 'Stok bunga berubah. Periksa keranjang lalu coba lagi.';
  }

  return 'Transaksi belum bisa diproses. Periksa data lalu coba lagi.';
}

class TransactionScreen extends StatefulWidget {
  final int initialTab;

  const TransactionScreen({super.key, this.initialTab = 0});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1).toInt(),
    );
  }

  @override
  void didUpdateWidget(covariant TransactionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextIndex = widget.initialTab.clamp(0, 1).toInt();
    if (nextIndex != _tabController.index) {
      _tabController.animateTo(nextIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final stockProvider = context.watch<StockProvider>();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(192),
        child: _CashierHeader(
          tabController: _tabController,
          cartCount: txProvider.cartItemCount,
          historyCount: txProvider.transactions.length,
          availableCount: stockProvider.availableCount,
          totalCount: stockProvider.totalCount,
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
          child: TabBarView(
            controller: _tabController,
            children: [
              _NewTransactionTab(currencyFmt: _currencyFmt),
              TransactionHistoryTab(currencyFmt: _currencyFmt),
            ],
          ),
        ),
      ),
    );
  }
}

class _CashierHeader extends StatelessWidget {
  final TabController tabController;
  final int cartCount;
  final int historyCount;
  final int availableCount;
  final int totalCount;

  const _CashierHeader({
    required this.tabController,
    required this.cartCount,
    required this.historyCount,
    required this.availableCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final stockLabel = totalCount == 0
        ? 'Menunggu data stok'
        : '$availableCount tersedia dari $totalCount bunga';

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
                          'Kasir',
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
                          stockLabel,
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
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const Icon(
                      Icons.point_of_sale_rounded,
                      color: Colors.white,
                      size: 22,
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
                child: TabBar(
                  controller: tabController,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5D1734).withValues(alpha: 0.16),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.82),
                  labelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                  tabs: [
                    _CashierTab(
                      icon: Icons.shopping_cart_checkout_rounded,
                      label: 'Transaksi Baru',
                      count: cartCount,
                    ),
                    _CashierTab(
                      icon: Icons.history_rounded,
                      label: 'Riwayat',
                      count: historyCount,
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

class _CashierTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _CashierTab({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 58,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
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

class _NewTransactionTab extends StatefulWidget {
  final NumberFormat currencyFmt;
  const _NewTransactionTab({required this.currencyFmt});

  @override
  State<_NewTransactionTab> createState() => _NewTransactionTabState();
}

class _NewTransactionTabState extends State<_NewTransactionTab> {
  final _searchCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stockProvider = context.read<StockProvider>();
      if (stockProvider.allStocks.isEmpty) {
        stockProvider.loadStocks(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshStocks() {
    return context.read<StockProvider>().loadStocks(refresh: true);
  }

  void _showCheckout(BuildContext context) {
    final txProvider = context.read<TransactionProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeNotifierProvider.value(
        value: txProvider,
        child: _CheckoutSheet(
          currencyFmt: widget.currencyFmt,
          amountCtrl: _amountCtrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final stockProvider = context.watch<StockProvider>();

    if (_searchCtrl.text != stockProvider.searchQuery) {
      _searchCtrl.value = TextEditingValue(
        text: stockProvider.searchQuery,
        selection: TextSelection.collapsed(
          offset: stockProvider.searchQuery.length,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: _CashierSearchBox(
            controller: _searchCtrl,
            onChanged: stockProvider.search,
          ),
        ),
        Expanded(
          flex: 3,
          child: _ProductGrid(
            stockProvider: stockProvider,
            txProvider: txProvider,
            currencyFmt: widget.currencyFmt,
            onRefresh: _refreshStocks,
          ),
        ),
        if (!txProvider.cartIsEmpty)
          _CartSummaryBar(
            itemCount: txProvider.cartItemCount,
            total: widget.currencyFmt.format(txProvider.totalAmount),
            onCheckout: () => _showCheckout(context),
          ),
      ],
    );
  }
}

class _CashierSearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _CashierSearchBox({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5C6D8)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari bunga untuk transaksi...',
          hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textHint,
            letterSpacing: 0,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppTheme.textSecondary,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Bersihkan pencarian',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
        ),
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final StockProvider stockProvider;
  final TransactionProvider txProvider;
  final NumberFormat currencyFmt;
  final Future<void> Function() onRefresh;

  const _ProductGrid({
    required this.stockProvider,
    required this.txProvider,
    required this.currencyFmt,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (stockProvider.isLoading && stockProvider.allStocks.isEmpty) {
      return const _CashierSkeletonGrid();
    }

    if (stockProvider.errorMessage != null && stockProvider.allStocks.isEmpty) {
      return _CashierStatePanel(
        icon: Icons.cloud_off_rounded,
        color: AppTheme.error,
        title: 'Server stok belum bisa dijangkau',
        subtitle: 'Pastikan internet aktif atau minta admin mengecek server.',
        actionLabel: 'Coba lagi',
        onAction: onRefresh,
      );
    }

    if (stockProvider.stocks.isEmpty) {
      final isSearching = stockProvider.searchQuery.trim().isNotEmpty;
      return _CashierStatePanel(
        icon: isSearching
            ? Icons.search_off_rounded
            : Icons.shopping_cart_outlined,
        color: AppTheme.primary,
        title: isSearching ? 'Bunga tidak ditemukan' : 'Belum ada bunga',
        subtitle: isSearching
            ? 'Coba kata kunci lain atau kosongkan pencarian.'
            : 'Data bunga belum tersedia untuk transaksi kasir.',
        actionLabel: 'Perbarui',
        onAction: onRefresh,
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      backgroundColor: Colors.white,
      displacement: 24,
      onRefresh: onRefresh,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 96),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.78,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: stockProvider.stocks.length,
        itemBuilder: (_, i) {
          final flower = stockProvider.stocks[i];
          final inCart = txProvider.cart
              .firstWhere(
                (c) => c.flower.id == flower.id,
                orElse: () => CartItem(flower: flower, quantity: 0),
              )
              .quantity;
          return _ProductCard(
            flower: flower,
            inCartQty: inCart,
            price: currencyFmt.format(flower.price),
            onAdd: () => txProvider.addToCart(flower),
            onRemove: () => txProvider.updateQuantity(flower.id, inCart - 1),
          );
        },
      ),
    );
  }
}

class _CartSummaryBar extends StatelessWidget {
  final int itemCount;
  final String total;
  final VoidCallback onCheckout;

  const _CartSummaryBar({
    required this.itemCount,
    required this.total,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF5C6D8)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB11E5C).withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$itemCount item dipilih',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Poppins',
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: onCheckout,
              icon: const Icon(Icons.payments_rounded, size: 18),
              label: const Text('Bayar'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(96, 46),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashierStatePanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _CashierStatePanel({
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
      padding: const EdgeInsets.fromLTRB(28, 52, 28, 96),
      children: [
        Container(
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

class _CashierSkeletonGrid extends StatelessWidget {
  const _CashierSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const _CashierSkeletonCard(),
    );
  }
}

class _CashierSkeletonCard extends StatelessWidget {
  const _CashierSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD9E8).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: 86,
            height: 13,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD9E8).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 54,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD9E8).withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD9E8).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final FlowerStock flower;
  final int inCartQty;
  final String price;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ProductCard({
    required this.flower,
    required this.inCartQty,
    required this.price,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = flower.isOutOfStock;
    final bgColor = outOfStock
        ? Colors.white.withValues(alpha: 0.88)
        : inCartQty > 0
            ? AppTheme.primary.withValues(alpha: 0.08)
            : _getFlowerBgColor(flower.name).withValues(alpha: 0.72);
    final iconBgColor =
        outOfStock ? AppTheme.border : _getFlowerIconBgColor(flower.name);

    return Semantics(
      button: true,
      label:
          '${flower.name}, stok ${flower.stock}, harga $price${outOfStock ? ', habis' : ''}',
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: inCartQty > 0
                ? AppTheme.primary.withValues(alpha: 0.34)
                : const Color(0xFFF5C6D8),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary
                  .withValues(alpha: inCartQty > 0 ? 0.12 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -14,
              right: -12,
              child: Text(
                _getFlowerEmoji(flower.name),
                style: TextStyle(
                  fontSize: 60,
                  color:
                      Colors.black.withValues(alpha: outOfStock ? 0.025 : 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: iconBgColor.withValues(
                              alpha: outOfStock ? 0.7 : 1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            _getFlowerEmoji(flower.name),
                            style: TextStyle(
                              fontSize: 19,
                              color: Colors.black
                                  .withValues(alpha: outOfStock ? 0.45 : 1),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: outOfStock
                              ? const Color(0xFFFFF1F3)
                              : AppTheme.success.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: outOfStock
                                ? const Color(0xFFE85D6A)
                                    .withValues(alpha: 0.14)
                                : AppTheme.success.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Text(
                          outOfStock ? 'Habis' : 'Ada',
                          style: TextStyle(
                            color: outOfStock
                                ? const Color(0xFFE85D6A)
                                : AppTheme.success,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    flower.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      height: 1.12,
                      color: outOfStock
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                      fontFamily: 'Poppins',
                      letterSpacing: 0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Stok ${flower.stock} ${flower.unit}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: outOfStock
                          ? const Color(0xFFE85D6A)
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    price,
                    style: TextStyle(
                      color: outOfStock ? AppTheme.textHint : AppTheme.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Poppins',
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (inCartQty == 0)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: outOfStock ? null : onAdd,
                        icon: Icon(
                          outOfStock ? Icons.block_rounded : Icons.add_rounded,
                          size: 15,
                        ),
                        label: Text(outOfStock ? 'Habis' : 'Tambah'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(36),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          backgroundColor: outOfStock
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.82),
                          foregroundColor:
                              outOfStock ? AppTheme.textHint : AppTheme.primary,
                          side: BorderSide(
                            color: outOfStock
                                ? const Color(0xFFF5C6D8)
                                : AppTheme.primary.withValues(alpha: 0.28),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  if (inCartQty > 0)
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          _QtyBtn(icon: Icons.remove_rounded, onTap: onRemove),
                          Expanded(
                            child: Text(
                              '$inCartQty',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          _QtyBtn(
                            icon: Icons.add_rounded,
                            onTap: inCartQty < flower.stock ? onAdd : null,
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
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.border.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? AppTheme.primary : AppTheme.textHint,
        ),
      ),
    );
  }
}

class _CheckoutSheet extends StatelessWidget {
  final NumberFormat currencyFmt;
  final TextEditingController amountCtrl;

  const _CheckoutSheet({required this.currencyFmt, required this.amountCtrl});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: ScrollConfiguration(
        behavior: const _NoStretchScrollBehavior(),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0B5CC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan Transaksi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                            fontFamily: 'Poppins',
                            letterSpacing: 0,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Periksa item sebelum pembayaran disimpan.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
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
              const SizedBox(height: 16),
              ...txProvider.cart.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF5C6D8)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_florist_rounded,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.flower.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.quantity} x ${currencyFmt.format(item.flower.price)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  fontFamily: 'Poppins',
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFmt.format(item.subtotal),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                            fontFamily: 'Poppins',
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Total',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins')),
                  const Spacer(),
                  Text(
                    currencyFmt.format(txProvider.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppTheme.primary,
                      fontFamily: 'Poppins',
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Metode Pembayaran',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 8),
              Row(
                children: PaymentMethod.values.map((method) {
                  final selected = txProvider.paymentMethod == method;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => context
                          .read<TransactionProvider>()
                          .setPaymentMethod(method),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.primary : AppTheme.bgLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                selected ? AppTheme.primary : AppTheme.border,
                          ),
                        ),
                        child: Text(
                          method.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: txProvider.isPromo
                      ? AppTheme.primary.withValues(alpha: 0.08)
                      : AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color:
                        txProvider.isPromo ? AppTheme.primary : AppTheme.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: txProvider.isPromo
                            ? AppTheme.primary.withValues(alpha: 0.14)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.local_offer_outlined,
                        size: 18,
                        color: txProvider.isPromo
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaksi Promo',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Aktifkan jika penjualan ini memakai promo.',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppTheme.textSecondary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: txProvider.isPromo,
                      activeThumbColor: AppTheme.primary,
                      activeTrackColor: AppTheme.primary.withValues(alpha: 0.3),
                      onChanged: (value) {
                        context.read<TransactionProvider>().setPromo(value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (txProvider.paymentMethod == PaymentMethod.cash) ...[
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Jumlah Dibayar',
                    prefixText: 'Rp ',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFF5C6D8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFF5C6D8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
                  onChanged: (v) {
                    final amount = double.tryParse(
                            v.replaceAll('.', '').replaceAll(',', '')) ??
                        0;
                    context.read<TransactionProvider>().setAmountPaid(amount);
                  },
                ),
                if (txProvider.amountPaid >= txProvider.totalAmount)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Text('Kembalian: ',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontFamily: 'Poppins')),
                        Text(
                          currencyFmt.format(txProvider.change),
                          style: const TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: txProvider.isSubmitting
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          final transactionProvider =
                              context.read<TransactionProvider>();
                          final stockProvider = context.read<StockProvider>();
                          final notifProvider =
                              context.read<NotificationProvider>();

                          if (transactionProvider.paymentMethod ==
                                  PaymentMethod.cash &&
                              transactionProvider.amountPaid <
                                  transactionProvider.totalAmount) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Jumlah dibayar masih kurang dari total transaksi.'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                            return;
                          }

                          final success =
                              await transactionProvider.submitTransaction();

                          if (!context.mounted) return;

                          if (success) {
                            await stockProvider.loadStocks(refresh: true);

                            await notifProvider.addNotification(
                              title: 'Transaksi Berhasil',
                              message: 'Transaksi berhasil disimpan.',
                              type: NotificationType.transaction,
                            );

                            if (!context.mounted) return;

                            NotificationPopup.show(
                              context,
                              title: 'Transaksi Berhasil',
                              message: 'Transaksi berhasil disimpan.',
                              type: NotificationType.transaction,
                            );

                            if (navigator.canPop()) navigator.pop();
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  _friendlyTransactionError(
                                    transactionProvider.errorMessage,
                                  ),
                                ),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: txProvider.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Simpan Transaksi'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
