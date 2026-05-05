import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/stock_provider.dart';
import '../models/flower_stock.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

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
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🛒 Kasir 🌺'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Transaksi Baru'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NewTransactionTab(currencyFmt: _currencyFmt),
          _HistoryTab(currencyFmt: _currencyFmt),
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
      builder: (_) => ChangeNotifierProvider.value(
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
                    childAspectRatio: 1.5,
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
                        '${txProvider.cartItemCount} item',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        widget.currencyFmt.format(txProvider.totalAmount),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: outOfStock
            ? AppTheme.bgLight
            : inCartQty > 0
                ? AppTheme.primary.withValues(alpha: 0.05)
                : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: inCartQty > 0
              ? AppTheme.primary.withValues(alpha: 0.3)
              : AppTheme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_florist,
                size: 18,
                color: outOfStock ? AppTheme.textHint : AppTheme.primary,
              ),
              const Spacer(),
              if (outOfStock)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              flower.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: outOfStock ? AppTheme.textHint : AppTheme.textPrimary,
                fontFamily: 'Poppins',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              color: AppTheme.primary,
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
                  side: BorderSide(
                    color: outOfStock ? AppTheme.border : AppTheme.primary,
                  ),
                ),
                child: const Text('+ Tambah', style: TextStyle(fontSize: 11)),
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
                        final tx = await context
                            .read<TransactionProvider>()
                            .submitTransaction();
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        if (tx != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Transaksi ${tx.invoiceNumber} berhasil!'),
                              backgroundColor: AppTheme.success,
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

class _HistoryTab extends StatefulWidget {
  final NumberFormat currencyFmt;
  const _HistoryTab({required this.currencyFmt});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();

    if (txProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (txProvider.transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: AppTheme.textHint),
            SizedBox(height: 12),
            Text('Belum ada transaksi',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontFamily: 'Poppins')),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: txProvider.transactions.length,
      itemBuilder: (_, i) {
        final tx = txProvider.transactions[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long,
                    color: AppTheme.success, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.invoiceNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      '${tx.items.length} item • ${tx.cashierName}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.currencyFmt.format(tx.grandTotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.primary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    tx.paymentMethod.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
