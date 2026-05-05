class FlowerStock {
  final int id;
  final String name;
  final String category;
  final int stock;
  final int minStock;
  final double price;
  final double costPrice;
  final String unit;
  final String? imageUrl;
  final DateTime updatedAt;

  FlowerStock({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.minStock,
    required this.price,
    required this.costPrice,
    required this.unit,
    this.imageUrl,
    required this.updatedAt,
  });

  bool get isLowStock => stock <= minStock;
  bool get isOutOfStock => stock == 0;

  StockStatus get status {
    if (isOutOfStock) return StockStatus.outOfStock;
    if (isLowStock) return StockStatus.low;
    return StockStatus.normal;
  }

  factory FlowerStock.fromJson(Map<String, dynamic> json) {
    return FlowerStock(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      stock: json['stock'],
      minStock: json['min_stock'] ?? 5,
      price: (json['price'] as num).toDouble(),
      costPrice: (json['cost_price'] as num).toDouble(),
      unit: json['unit'] ?? 'tangkai',
      imageUrl: json['image_url'],
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'stock': stock,
        'min_stock': minStock,
        'price': price,
        'cost_price': costPrice,
        'unit': unit,
        'image_url': imageUrl,
        'updated_at': updatedAt.toIso8601String(),
      };
}

enum StockStatus { normal, low, outOfStock }
