import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/flower_stock.dart';
import '../services/api_service.dart';

class CartItem {
  final FlowerStock flower;
  int quantity;

  CartItem({required this.flower, this.quantity = 1});

  double get subtotal => flower.price * quantity;
}

class TransactionProvider extends ChangeNotifier {
  final List<CartItem> _cart = [];
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  double _amountPaid = 0;
  bool _isPromo = false;
  String? _note;

  List<CartItem> get cart => _cart;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  PaymentMethod get paymentMethod => _paymentMethod;
  double get amountPaid => _amountPaid;
  bool get isPromo => _isPromo;
  bool get cartIsEmpty => _cart.isEmpty;

  double get totalAmount => _cart.fold(0, (sum, item) => sum + item.subtotal);
  double get change => (_amountPaid - totalAmount).clamp(0, double.infinity);
  int get cartItemCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  void addToCart(FlowerStock flower) {
    final existing = _cart.indexWhere((c) => c.flower.id == flower.id);

    if (existing != -1) {
      if (_cart[existing].quantity < flower.stock) {
        _cart[existing].quantity++;
      }
    } else {
      if (flower.stock > 0) {
        _cart.add(CartItem(flower: flower));
      }
    }

    notifyListeners();
  }

  void removeFromCart(int flowerId) {
    _cart.removeWhere((c) => c.flower.id == flowerId);
    notifyListeners();
  }

  void updateQuantity(int flowerId, int quantity) {
    final index = _cart.indexWhere((c) => c.flower.id == flowerId);

    if (index != -1) {
      if (quantity <= 0) {
        _cart.removeAt(index);
      } else {
        final maxStock = _cart[index].flower.stock;
        _cart[index].quantity = quantity > maxStock ? maxStock : quantity;
      }

      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    _amountPaid = 0;
    _isPromo = false;
    _note = null;
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;

    if (method != PaymentMethod.cash) {
      _amountPaid = totalAmount;
    }

    notifyListeners();
  }

  void setAmountPaid(double amount) {
    _amountPaid = amount;
    notifyListeners();
  }

  void setPromo(bool value) {
    _isPromo = value;
    notifyListeners();
  }

  void setNote(String note) {
    _note = note;
  }

  Future<bool> submitTransaction() async {
    if (_cart.isEmpty) {
      _errorMessage = 'Keranjang masih kosong.';
      notifyListeners();
      return false;
    }

    if (_paymentMethod == PaymentMethod.cash && _amountPaid < totalAmount) {
      _errorMessage = 'Jumlah dibayar kurang dari total transaksi.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = {
        'items': _cart
            .map((c) => {
                  'product_id': c.flower.id,
                  'flower_id': c.flower.id,
                  'flower_name': c.flower.name,
                  'quantity': c.quantity,
                  'unit_price': c.flower.price,
                  'subtotal': c.subtotal,
                })
            .toList(),
        'total_amount': totalAmount,
        'grand_total': totalAmount,
        'amount_paid':
            _paymentMethod == PaymentMethod.cash ? _amountPaid : totalAmount,
        'change': _paymentMethod == PaymentMethod.cash ? change : 0,
        'payment_method': _paymentMethod.name,
        'promo': _isPromo ? 1 : 0,
        'note': _note,
      };

      await ApiService.createTransaction(data);

      // Langsung reload dari backend supaya riwayat pasti up to date
      await loadTransactions();

      clearCart();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> loadTransactions({DateTime? start, DateTime? end}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getTransactions(
        startDate: start,
        endDate: end,
      );

      final items = response['data'] as List;

      // Group by invoice_number karena backend return flat per item
      final Map<String, List> grouped = {};
      for (final item in items) {
        final key =
            item['invoice_number'] ?? item['transaction_number'].toString();
        grouped.putIfAbsent(key, () => []).add(item);
      }

      _transactions = grouped.entries.map((entry) {
        final rows = entry.value;
        final first = rows.first;

        final txItems = rows.map((r) {
          final qty = _numberValue(r['quantity'] ?? r['jumlah'] ?? 1);
          var price = _numberValue(r['unit_price'] ?? r['harga'] ?? 0);
          final rowTotal = _numberValue(r['grand_total'] ?? r['total_amount']);
          if (price > 0 && price < 1000 && rowTotal >= 1000) {
            price *= 1000;
          }

          return TransactionItem(
            flowerId: _intValue(r['flower_id'] ?? r['product_id'] ?? 0),
            flowerName: r['flower_name'] ?? r['nama_bunga'] ?? '',
            quantity: qty.toInt(),
            unitPrice: price,
            subtotal: price * qty,
          );
        }).toList();

        final itemTotal = txItems.fold<double>(
          0,
          (sum, item) => sum + item.subtotal,
        );
        final serverTotal = _numberValue(
          first['grand_total'] ?? first['total_amount'] ?? 0,
        );
        final grandTotal = serverTotal > 0 ? serverTotal : itemTotal;
        final amountPaid = _numberValue(first['amount_paid'] ?? grandTotal);
        final changeVal = _numberValue(first['change'] ?? 0);

        return Transaction(
          id: first['id'],
          invoiceNumber: entry.key,
          items: txItems,
          totalAmount: grandTotal,
          grandTotal: grandTotal,
          amountPaid: amountPaid,
          change: changeVal,
          paymentMethod: PaymentMethod.values.firstWhere(
            (e) => e.name == first['payment_method'],
            orElse: () => PaymentMethod.cash,
          ),
          note: first['note'],
          cashierId: first['cashier_id']?.toString() ?? '-',
          cashierName: first['cashier_name'] ?? '-',
          createdAt: _transactionDate(first),
        );
      }).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double _numberValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0;
    }
    return 0;
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  DateTime _transactionDate(dynamic row) {
    if (row is! Map) return DateTime.now();

    final source = row['source']?.toString().trim().toLowerCase();
    final value = source == 'mobile'
        ? (row['created_at'] ?? row['tanggal'] ?? row['date'])
        : (row['tanggal'] ?? row['date'] ?? row['created_at']);

    if (value is DateTime) return value;
    if (value != null) {
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed;
    }

    return DateTime.now();
  }
}
