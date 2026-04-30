import 'package:flutter/foundation.dart';
import '../models/flower_stock.dart';
import '../services/api_service.dart';

class StockProvider extends ChangeNotifier {
  List<FlowerStock> _stocks = [];
  List<FlowerStock> _filteredStocks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showLowStockOnly = false;

  List<FlowerStock> get stocks => _filteredStocks;
  List<FlowerStock> get lowStockItems =>
      _stocks.where((s) => s.isLowStock).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get lowStockCount => lowStockItems.length;

  List<String> get categories {
    final cats = _stocks.map((s) => s.category).toSet().toList();
    cats.sort();
    return cats;
  }

  Future<void> loadStocks({bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getStocks(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory,
        lowStockOnly: _showLowStockOnly ? true : null,
      );
      _stocks = (response['data'] as List)
          .map((e) => FlowerStock.fromJson(e))
          .toList();
      _applyFilters();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void toggleLowStockFilter(bool value) {
    _showLowStockOnly = value;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredStocks = _stocks.where((stock) {
      final matchSearch = _searchQuery.isEmpty ||
          stock.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCategory =
          _selectedCategory == null || stock.category == _selectedCategory;
      final matchLowStock = !_showLowStockOnly || stock.isLowStock;
      return matchSearch && matchCategory && matchLowStock;
    }).toList();
  }

  void updateStockLocally(int id, int newStock) {
    final index = _stocks.indexWhere((s) => s.id == id);
    if (index != -1) {
      final old = _stocks[index];
      _stocks[index] = FlowerStock(
        id: old.id,
        name: old.name,
        category: old.category,
        stock: newStock,
        minStock: old.minStock,
        price: old.price,
        costPrice: old.costPrice,
        unit: old.unit,
        imageUrl: old.imageUrl,
        updatedAt: DateTime.now(),
      );
      _applyFilters();
      notifyListeners();
    }
  }
}