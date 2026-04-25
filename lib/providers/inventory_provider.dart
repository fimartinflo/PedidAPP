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
    );

    await _db.insertProduct(product);
    _products.add(product);
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    await _db.updateProduct(product);
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      notifyListeners();
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
      {String source = 'manual', bool updateEstimated = true}) async {
    final record = PriceRecord(
      id: _uuid.v4(),
      productId: productId,
      price: price,
      source: source,
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

  List<Product> searchProducts(String query) {
    final lowerQuery = query.toLowerCase();
    return _products
        .where((p) => p.name.toLowerCase().contains(lowerQuery))
        .toList();
  }
}
