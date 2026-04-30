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
  String? _note;

  List<CartItem> get cart => _cart;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  PaymentMethod get paymentMethod => _paymentMethod;
  double get amountPaid => _amountPaid;
  bool get cartIsEmpty => _cart.isEmpty;

  double get totalAmount =>
      _cart.fold(0, (sum, item) => sum + item.subtotal);
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
        _cart[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    _amountPaid = 0;
    _note = null;
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setAmountPaid(double amount) {
    _amountPaid = amount;
    notifyListeners();
  }

  void setNote(String note) {
    _note = note;
  }

  Future<Transaction?> submitTransaction() async {
    if (_cart.isEmpty) return null;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = {
        'items': _cart
            .map((c) => {
                  'flower_id': c.flower.id,
                  'flower_name': c.flower.name,
                  'quantity': c.quantity,
                  'unit_price': c.flower.price,
                  'subtotal': c.subtotal,
                })
            .toList(),
        'total_amount': totalAmount,
        'grand_total': totalAmount,
        'amount_paid': _amountPaid,
        'change': change,
        'payment_method': _paymentMethod.name,
        'note': _note,
      };

      final response = await ApiService.createTransaction(data);
      final transaction = Transaction.fromJson(response['data']);
      _transactions.insert(0, transaction);
      clearCart();
      return transaction;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> loadTransactions({DateTime? start, DateTime? end}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.getTransactions(
        startDate: start,
        endDate: end,
      );
      _transactions = (response['data'] as List)
          .map((e) => Transaction.fromJson(e))
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}