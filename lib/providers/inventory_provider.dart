import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/consumption_log.dart';
import '../models/price_record.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class InventoryProvider extends ChangeNotifier {
  final DatabaseService _db;
  final NotificationService _notifications;
  final Uuid _uuid = const Uuid();

  InventoryProvider({
    DatabaseService? db,
    NotificationService? notifications,
  })  : _db = db ?? DatabaseService(),
        _notifications = notifications ?? NotificationService();

  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();

  List<Product> get outOfStockProducts =>
      _products.where((p) => p.isOutOfStock).toList();

  int get totalProducts => _products.length;
  int get lowStockCount => lowStockProducts.length;

  List<Product> getProductsByCategory(String categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _db.getCategories();
      _products = await _db.getProducts();
    } catch (e) {
      _error = 'Error al cargar datos: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct({
    required String name,
    required String categoryId,
    String unit = 'unidad',
    double currentStock = 0,
    double minimumStock = 1,
    double? estimatedPrice,
    String? notes,
    String? barcode,
    DateTime? expiryDate,
  }) async {
    final product = Product(
      id: _uuid.v4(),
      name: name,
      categoryId: categoryId,
      unit: unit,
      currentStock: currentStock,
      minimumStock: minimumStock,
      estimatedPrice: estimatedPrice,
      notes: notes,
      barcode: barcode,
      expiryDate: expiryDate,
    );

    await _db.insertProduct(product);
    _products.add(product);
    notifyListeners();

    if (expiryDate != null) {
      await _notifications.scheduleExpiryNotification(product);
    }
  }

  Future<void> updateProduct(Product product) async {
    await _db.updateProduct(product);
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      notifyListeners();
    }

    if (product.expiryDate != null) {
      await _notifications.scheduleExpiryNotification(product);
    } else {
      await _notifications.cancelExpiryNotification(product.id);
    }
  }

  Future<void> updateStock(String productId, double newStock) async {
    await _db.updateProductStock(productId, newStock);
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _products[index] = _products[index].copyWith(
        currentStock: newStock,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      await _checkLowStockAlerts();
    }
  }

  Future<void> incrementStock(String productId, double amount) async {
    final product = _products.firstWhere((p) => p.id == productId);
    await updateStock(productId, product.currentStock + amount);
  }

  Future<void> decrementStock(String productId, double amount) async {
    final product = _products.firstWhere((p) => p.id == productId);
    final newStock = (product.currentStock - amount).clamp(0.0, double.infinity);
    await updateStock(productId, newStock);

    // Log consumption for prediction
    final log = ConsumptionLog(
      id: _uuid.v4(),
      productId: productId,
      quantity: amount,
    );
    await _db.insertConsumptionLog(log);
  }

  Future<double?> getEstimatedDaysUntilEmpty(String productId) async {
    final product = _products.firstWhere((p) => p.id == productId);
    return _db.estimateDaysUntilEmpty(productId, product.currentStock);
  }

  Future<double> getAverageDailyConsumption(String productId) async {
    return _db.getAverageDailyConsumption(productId);
  }

  Future<void> deleteProduct(String productId) async {
    await _db.deleteProduct(productId);
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  // Categories
  Future<void> addCategory({
    required String name,
    String icon = 'category',
    String color = '#4CAF50',
  }) async {
    final category = Category(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      color: color,
      sortOrder: _categories.length,
    );

    await _db.insertCategory(category);
    _categories.add(category);
    notifyListeners();
  }

  Future<void> updateCategory(Category category) async {
    await _db.updateCategory(category);
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    await _db.deleteCategory(categoryId);
    _categories.removeWhere((c) => c.id == categoryId);
    notifyListeners();
  }

  Future<void> _checkLowStockAlerts() async {
    final lowStock = lowStockProducts;
    if (lowStock.isNotEmpty) {
      await _notifications.showLowStockNotification(lowStock);
    }
  }

  /// Records a price and optionally auto-updates the product's estimatedPrice.
  Future<void> recordPrice(String productId, double price,
      {String source = 'manual',
      String? store,
      bool updateEstimated = true}) async {
    final record = PriceRecord(
      id: _uuid.v4(),
      productId: productId,
      price: price,
      source: source,
      store: store,
    );
    await _db.insertPriceRecord(record);

    if (updateEstimated) {
      final idx = _products.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        final updated = _products[idx].copyWith(estimatedPrice: price);
        await _db.updateProduct(updated);
        _products[idx] = updated;
        notifyListeners();
      }
    }
  }

  Future<List<PriceRecord>> getPriceHistory(String productId) async {
    return _db.getPriceHistory(productId);
  }

  /// Returns price comparison by store: { storeName -> latest price }
  /// for a specific product.
  Future<Map<String, double>> getPriceComparisonByStore(
      String productId) async {
    final records = await _db.getPriceHistory(productId, limit: 100);
    final byStore = <String, PriceRecord>{};
    for (final r in records) {
      final store = r.store?.trim();
      if (store == null || store.isEmpty) continue;
      final existing = byStore[store];
      if (existing == null || r.date.isAfter(existing.date)) {
        byStore[store] = r;
      }
    }
    return byStore.map((k, v) => MapEntry(k, v.price));
  }

  /// Products that are expiring within the given days, ordered by closeness.
  List<Product> get expiringSoonProducts {
    final list = _products.where((p) {
      final days = p.daysUntilExpiry;
      return days != null && days >= 0 && days <= 7;
    }).toList();
    list.sort((a, b) =>
        (a.daysUntilExpiry ?? 999).compareTo(b.daysUntilExpiry ?? 999));
    return list;
  }

  List<Product> get expiredProducts =>
      _products.where((p) => p.isExpired).toList();

  /// Generates smart shopping list suggestions based on consumption patterns.
  /// Suggests products that are running out and have history of consumption.
  Future<List<SmartSuggestion>> getSmartSuggestions() async {
    final suggestions = <SmartSuggestion>[];

    for (final product in _products) {
      if (product.isOutOfStock) {
        suggestions.add(SmartSuggestion(
          product: product,
          reason: 'Sin stock',
          priority: 3,
        ));
        continue;
      }

      final daysUntilEmpty =
          await _db.estimateDaysUntilEmpty(product.id, product.currentStock);

      if (daysUntilEmpty != null && daysUntilEmpty <= 5) {
        suggestions.add(SmartSuggestion(
          product: product,
          reason: daysUntilEmpty < 1
              ? 'Se agota hoy'
              : 'Se agota en ${daysUntilEmpty.toStringAsFixed(0)} día'
                  '${daysUntilEmpty < 2 ? '' : 's'}',
          priority: daysUntilEmpty < 2 ? 2 : 1,
        ));
      } else if (product.isLowStock && daysUntilEmpty == null) {
        suggestions.add(SmartSuggestion(
          product: product,
          reason: 'Stock bajo',
          priority: 1,
        ));
      }
    }

    suggestions.sort((a, b) => b.priority.compareTo(a.priority));
    return suggestions;
  }

  List<Product> searchProducts(String query) {
    final lowerQuery = query.toLowerCase();
    return _products
        .where((p) => p.name.toLowerCase().contains(lowerQuery))
        .toList();
  }
}

class SmartSuggestion {
  final Product product;
  final String reason;
  final int priority;

  const SmartSuggestion({
    required this.product,
    required this.reason,
    required this.priority,
  });
}
