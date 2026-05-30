import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/stock_provider.dart';
import '../models/flower_stock.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
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

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(22),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Kasir',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'MANAJEMEN TRANSAKSI',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Colors.white60,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 15),
                              SizedBox(width: 5),
                              Text('Transaksi Baru'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history, size: 15),
                              SizedBox(width: 5),
                              Text('Riwayat'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NewTransactionTab(currencyFmt: _currencyFmt),
          TransactionHistoryTab(currencyFmt: _currencyFmt),
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
  void dispose() {
    _searchCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            onChanged: stockProvider.search,
            decoration: const InputDecoration(
              hintText: 'Cari bunga untuk ditambah...',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: stockProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
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
                      price: widget.currencyFmt.format(flower.price),
                      onAdd: () =>
                          context.read<TransactionProvider>().addToCart(flower),
                      onRemove: () => context
                          .read<TransactionProvider>()
                          .updateQuantity(flower.id, inCart - 1),
                    );
                  },
                ),
        ),
        if (!txProvider.cartIsEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.bgCard,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${txProvider.cartItemCount} item dipilih',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        widget.currencyFmt.format(txProvider.totalAmount),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showCheckout(context),
                    icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                    label: const Text('Bayar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
        ? AppTheme.bgLight
        : inCartQty > 0
            ? AppTheme.primary.withValues(alpha: 0.05)
            : _getFlowerBgColor(flower.name);
    final iconBgColor =
        outOfStock ? AppTheme.border : _getFlowerIconBgColor(flower.name);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: inCartQty > 0
                    ? AppTheme.primary.withValues(alpha: 0.3)
                    : AppTheme.border,
              ),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Text(
              _getFlowerEmoji(flower.name),
              style: TextStyle(
                fontSize: 52,
                color: Colors.black.withValues(alpha: outOfStock ? 0.04 : 0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getFlowerEmoji(flower.name),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (outOfStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Habis',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flower.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: outOfStock
                              ? AppTheme.textHint
                              : AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Stok: ${flower.stock}',
                        style: TextStyle(
                          fontSize: 10,
                          color: outOfStock
                              ? AppTheme.error
                              : AppTheme.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    color: outOfStock ? AppTheme.textHint : AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                if (inCartQty == 0)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: outOfStock ? null : onAdd,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: Size.zero,
                        backgroundColor: outOfStock
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.6),
                        side: BorderSide(
                          color:
                              outOfStock ? AppTheme.border : AppTheme.primary,
                        ),
                      ),
                      child: Text(
                        outOfStock ? 'Habis' : '+ Tambah',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      _QtyBtn(icon: Icons.remove, onTap: onRemove),
                      Expanded(
                        child: Text(
                          '$inCartQty',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      _QtyBtn(
                        icon: Icons.add,
                        onTap: inCartQty < flower.stock ? onAdd : null,
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

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: onTap != null ? AppTheme.primary : AppTheme.border,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: Colors.white),
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
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Checkout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            ...txProvider.cart.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(item.flower.name,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            fontFamily: 'Poppins')),
                    const Spacer(),
                    Text(
                      '${item.quantity}x ${currencyFmt.format(item.flower.price)}',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontFamily: 'Poppins'),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyFmt.format(item.subtotal),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              children: [
                const Text('Total',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        fontFamily: 'Poppins')),
                const Spacer(),
                Text(
                  currencyFmt.format(txProvider.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppTheme.primary,
                    fontFamily: 'Poppins',
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
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppTheme.primary : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        method.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              selected ? Colors.white : AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: txProvider.isPromo
                    ? AppTheme.primary.withValues(alpha: 0.08)
                    : AppTheme.bgLight,
                borderRadius: BorderRadius.circular(12),
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
                      borderRadius: BorderRadius.circular(10),
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
                    activeColor: AppTheme.primary,
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
                decoration: const InputDecoration(
                  labelText: 'Jumlah Dibayar',
                  prefixText: 'Rp ',
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
                            message: 'Pembayaran berhasil disimpan! 🛍️',
                            type: NotificationType.transaction,
                          );

                          NotificationPopup.show(
                            context,
                            title: 'Transaksi Berhasil',
                            message: 'Pembayaran berhasil disimpan! 🛍️',
                            type: NotificationType.transaction,
                          );

                          if (navigator.canPop()) navigator.pop();
                        } else {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                transactionProvider.errorMessage ??
                                    'Pembayaran gagal diproses.',
                              ),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
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
                    : const Text('Proses Pembayaran'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
