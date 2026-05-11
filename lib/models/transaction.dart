import 'package:flower_shop/models/flower_stock.dart';

FlowerStock? test;

class Transaction {
  final int? id;
  final String invoiceNumber;
  final List<TransactionItem> items;
  final double totalAmount;
  final double discount;
  final double tax;
  final double grandTotal;
  final double amountPaid;
  final double change;
  final PaymentMethod paymentMethod;
  final String? note;
  final String cashierId;
  final String cashierName;
  final DateTime createdAt;

  Transaction({
    this.id,
    required this.invoiceNumber,
    required this.items,
    required this.totalAmount,
    this.discount = 0,
    this.tax = 0,
    required this.grandTotal,
    required this.amountPaid,
    required this.change,
    required this.paymentMethod,
    this.note,
    required this.cashierId,
    required this.cashierName,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      invoiceNumber: json['invoice_number'],
      items: (json['items'] as List)
          .map((e) => TransactionItem.fromJson(e))
          .toList(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      grandTotal: (json['grand_total'] as num).toDouble(),
      amountPaid: (json['amount_paid'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['payment_method'],
        orElse: () => PaymentMethod.cash,
      ),
      note: json['note'],
      cashierId: json['cashier_id'].toString(),
      cashierName: json['cashier_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'invoice_number': invoiceNumber,
        'items': items.map((e) => e.toJson()).toList(),
        'total_amount': totalAmount,
        'discount': discount,
        'tax': tax,
        'grand_total': grandTotal,
        'amount_paid': amountPaid,
        'change': change,
        'payment_method': paymentMethod.name,
        'note': note,
        'cashier_id': cashierId,
        'cashier_name': cashierName,
        'created_at': createdAt.toIso8601String(),
      };
}

class TransactionItem {
  final int flowerId;
  final String flowerName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  TransactionItem({
    required this.flowerId,
    required this.flowerName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      flowerId: json['flower_id'],
      flowerName: json['flower_name'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'flower_id': flowerId,
        'flower_name': flowerName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'subtotal': subtotal,
      };
}

enum PaymentMethod { cash, qris, transfer, debit }

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Tunai';
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.transfer:
        return 'Transfer';
      case PaymentMethod.debit:
        return 'Debit';
    }
  }
}
