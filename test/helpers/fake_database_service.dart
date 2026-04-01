import 'package:pedidapp/models/budget.dart';
import 'package:pedidapp/models/category.dart';
import 'package:pedidapp/models/consumption_log.dart';
import 'package:pedidapp/models/product.dart';
import 'package:pedidapp/models/shopping_item.dart';
import 'package:pedidapp/models/shopping_list.dart';
import 'package:pedidapp/services/database_service.dart';

/// In-memory fake of DatabaseService for testing providers.
class FakeDatabaseService extends DatabaseService {
  FakeDatabaseService() : super.forTesting();

  final List<Category> _categories = List.from(Category.defaultCategories());
  final List<Product> _products = [];
  final List<ShoppingList> _shoppingLists = [];
  final List<ShoppingItem> _shoppingItems = [];
  final List<MonthlyBudget> _budgets = [];
  final List<ConsumptionLog> _consumptionLogs = [];

  // ==================== CATEGORIES ====================

  @override
  Future<List<Category>> getCategories() async =>
      List.from(_categories)..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  Future<Category?> getCategoryById(String id) async {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> insertCategory(Category category) async {
    _categories.removeWhere((c) => c.id == category.id);
    _categories.add(category);
  }

  @override
  Future<void> updateCategory(Category category) async {
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx != -1) _categories[idx] = category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
  }

  // ==================== PRODUCTS ====================

  @override
  Future<List<Product>> getProducts() async =>
      List.from(_products)..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<List<Product>> getProductsByCategory(String categoryId) async =>
      _products.where((p) => p.categoryId == categoryId).toList();

  @override
  Future<List<Product>> getLowStockProducts() async =>
      _products.where((p) => p.isLowStock).toList();

  @override
  Future<Product?> getProductById(String id) async {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> insertProduct(Product product) async {
    _products.removeWhere((p) => p.id == product.id);
    _products.add(product);
  }

  @override
  Future<void> updateProduct(Product product) async {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) _products[idx] = product;
  }

  @override
  Future<void> updateProductStock(String productId, double newStock) async {
    final idx = _products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      _products[idx] = _products[idx].copyWith(
        currentStock: newStock,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
  }

  // ==================== SHOPPING LISTS ====================

  @override
  Future<List<ShoppingList>> getShoppingLists() async {
    return _shoppingLists.map((list) {
      final items =
          _shoppingItems.where((i) => i.shoppingListId == list.id).toList();
      return ShoppingList(
        id: list.id,
        name: list.name,
        createdAt: list.createdAt,
        completedAt: list.completedAt,
        status: list.status,
        budgetLimit: list.budgetLimit,
        items: items,
      );
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> insertShoppingList(ShoppingList list) async {
    _shoppingLists.removeWhere((l) => l.id == list.id);
    _shoppingLists.add(list);
  }

  @override
  Future<void> updateShoppingList(ShoppingList list) async {
    final idx = _shoppingLists.indexWhere((l) => l.id == list.id);
    if (idx != -1) _shoppingLists[idx] = list;
  }

  @override
  Future<void> deleteShoppingList(String id) async {
    _shoppingItems.removeWhere((i) => i.shoppingListId == id);
    _shoppingLists.removeWhere((l) => l.id == id);
  }

  // ==================== SHOPPING ITEMS ====================

  @override
  Future<void> insertShoppingItem(ShoppingItem item) async {
    _shoppingItems.removeWhere((i) => i.id == item.id);
    _shoppingItems.add(item);
  }

  @override
  Future<void> updateShoppingItem(ShoppingItem item) async {
    final idx = _shoppingItems.indexWhere((i) => i.id == item.id);
    if (idx != -1) _shoppingItems[idx] = item;
  }

  @override
  Future<void> deleteShoppingItem(String id) async {
    _shoppingItems.removeWhere((i) => i.id == id);
  }

  @override
  Future<void> toggleShoppingItemPurchased(String id, bool isPurchased) async {
    final idx = _shoppingItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final item = _shoppingItems[idx];
      _shoppingItems[idx] = ShoppingItem(
        id: item.id,
        shoppingListId: item.shoppingListId,
        productId: item.productId,
        productName: item.productName,
        categoryId: item.categoryId,
        quantity: item.quantity,
        unit: item.unit,
        estimatedPrice: item.estimatedPrice,
        isPurchased: isPurchased,
        actualPrice: item.actualPrice,
        notes: item.notes,
      );
    }
  }

  // ==================== BUDGETS ====================

  @override
  Future<List<MonthlyBudget>> getBudgets() async =>
      List.from(_budgets)
        ..sort((a, b) {
          final cmp = b.year.compareTo(a.year);
          return cmp != 0 ? cmp : b.month.compareTo(a.month);
        });

  @override
  Future<MonthlyBudget?> getBudgetForMonth(int year, int month) async {
    try {
      return _budgets.firstWhere((b) => b.year == year && b.month == month);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> insertOrUpdateBudget(MonthlyBudget budget) async {
    _budgets.removeWhere((b) => b.id == budget.id);
    _budgets.add(budget);
  }

  @override
  Future<void> updateBudgetSpent(String id, double spentAmount) async {
    final idx = _budgets.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _budgets[idx] = _budgets[idx].copyWith(spentAmount: spentAmount);
    }
  }

  // ==================== CONSUMPTION LOGS ====================

  @override
  Future<void> insertConsumptionLog(ConsumptionLog log) async {
    _consumptionLogs.add(log);
  }

  @override
  Future<List<ConsumptionLog>> getConsumptionLogs(String productId,
      {int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    return _consumptionLogs
        .where((l) =>
            l.productId == productId && l.timestamp.isAfter(since))
        .toList();
  }

  @override
  Future<double> getAverageDailyConsumption(String productId,
      {int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final total = _consumptionLogs
        .where((l) =>
            l.productId == productId && l.timestamp.isAfter(since))
        .fold<double>(0, (sum, l) => sum + l.quantity);
    return total / days;
  }

  @override
  Future<double?> estimateDaysUntilEmpty(
      String productId, double currentStock) async {
    final avgDaily = await getAverageDailyConsumption(productId);
    if (avgDaily <= 0) return null;
    return currentStock / avgDaily;
  }

  @override
  Future<Map<String, double>> getSpendingByCategory(
      int year, int month) async {
    return {};
  }
}
