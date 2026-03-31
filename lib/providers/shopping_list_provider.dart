import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class ShoppingListProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();
  final Uuid _uuid = const Uuid();

  List<ShoppingList> _shoppingLists = [];
  bool _isLoading = false;

  List<ShoppingList> get shoppingLists => _shoppingLists;
  bool get isLoading => _isLoading;

  List<ShoppingList> get activeLists =>
      _shoppingLists.where((l) => l.status == ShoppingListStatus.active).toList();

  List<ShoppingList> get completedLists =>
      _shoppingLists.where((l) => l.status == ShoppingListStatus.completed).toList();

  Future<void> loadShoppingLists() async {
    _isLoading = true;
    notifyListeners();

    _shoppingLists = await _db.getShoppingLists();

    _isLoading = false;
    notifyListeners();
  }

  Future<ShoppingList> createShoppingList({
    required String name,
    double? budgetLimit,
  }) async {
    final list = ShoppingList(
      id: _uuid.v4(),
      name: name,
      budgetLimit: budgetLimit,
    );

    await _db.insertShoppingList(list);
    _shoppingLists.insert(0, list);
    notifyListeners();
    return list;
  }

  Future<ShoppingList> generateFromLowStock(List<Product> lowStockProducts,
      {String? name, double? budgetLimit}) async {
    final list = await createShoppingList(
      name: name ?? 'Compras ${DateTime.now().day}/${DateTime.now().month}',
      budgetLimit: budgetLimit,
    );

    for (final product in lowStockProducts) {
      final item = ShoppingItem(
        id: _uuid.v4(),
        shoppingListId: list.id,
        productId: product.id,
        productName: product.name,
        categoryId: product.categoryId,
        quantity: product.stockNeeded,
        unit: product.unit,
        estimatedPrice: product.estimatedPrice,
      );

      await _db.insertShoppingItem(item);
    }

    await loadShoppingLists();
    return list;
  }

  Future<void> addItemToList({
    required String listId,
    required String productId,
    required String productName,
    required String categoryId,
    double quantity = 1,
    String unit = 'unidad',
    double? estimatedPrice,
    String? notes,
  }) async {
    final item = ShoppingItem(
      id: _uuid.v4(),
      shoppingListId: listId,
      productId: productId,
      productName: productName,
      categoryId: categoryId,
      quantity: quantity,
      unit: unit,
      estimatedPrice: estimatedPrice,
      notes: notes,
    );

    await _db.insertShoppingItem(item);
    await loadShoppingLists();
  }

  Future<void> toggleItemPurchased(String listId, String itemId) async {
    final list = _shoppingLists.firstWhere((l) => l.id == listId);
    final item = list.items.firstWhere((i) => i.id == itemId);
    await _db.toggleShoppingItemPurchased(itemId, !item.isPurchased);
    await loadShoppingLists();
  }

  Future<void> updateItemActualPrice(
      String itemId, double actualPrice) async {
    final db = await _db.database;
    await db.update(
      'shopping_items',
      {'actualPrice': actualPrice},
      where: 'id = ?',
      whereArgs: [itemId],
    );
    await loadShoppingLists();
  }

  Future<void> removeItemFromList(String itemId) async {
    await _db.deleteShoppingItem(itemId);
    await loadShoppingLists();
  }

  Future<void> completeList(String listId) async {
    final list = _shoppingLists.firstWhere((l) => l.id == listId);
    final updated = list.copyWith(
      status: ShoppingListStatus.completed,
      completedAt: DateTime.now(),
    );
    await _db.updateShoppingList(updated);
    await loadShoppingLists();
  }

  Future<void> deleteList(String listId) async {
    await _db.deleteShoppingList(listId);
    _shoppingLists.removeWhere((l) => l.id == listId);
    notifyListeners();
  }

  Future<void> sendShoppingReminder(String listId) async {
    final list = _shoppingLists.firstWhere((l) => l.id == listId);
    final pendingItems = list.items.where((i) => !i.isPurchased).length;
    await _notifications.showShoppingReminder(list.name, pendingItems);
  }
}
