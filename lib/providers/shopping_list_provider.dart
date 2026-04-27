import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_list.dart';
import '../models/shopping_item.dart';
import '../models/product.dart';
import '../models/list_template.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class ShoppingListProvider extends ChangeNotifier {
  final DatabaseService _db;
  final NotificationService _notifications;
  final Uuid _uuid = const Uuid();

  ShoppingListProvider({
    DatabaseService? db,
    NotificationService? notifications,
  })  : _db = db ?? DatabaseService(),
        _notifications = notifications ?? NotificationService();

  List<ShoppingList> _shoppingLists = [];
  List<ListTemplate> _templates = [];
  bool _isLoading = false;

  List<ShoppingList> get shoppingLists => _shoppingLists;
  List<ListTemplate> get templates => _templates;
  bool get isLoading => _isLoading;

  List<ShoppingList> get activeLists =>
      _shoppingLists.where((l) => l.status == ShoppingListStatus.active).toList();

  List<ShoppingList> get completedLists =>
      _shoppingLists.where((l) => l.status == ShoppingListStatus.completed).toList();

  Future<void> loadShoppingLists() async {
    _isLoading = true;
    notifyListeners();

    _shoppingLists = await _db.getShoppingLists();
    _templates = await _db.getTemplates();

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
    await _db.updateShoppingItemActualPrice(itemId, actualPrice);
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

  // ==================== TEMPLATES ====================

  Future<void> loadTemplates() async {
    _templates = await _db.getTemplates();
    notifyListeners();
  }

  Future<ListTemplate> saveAsTemplate(String listId, {String? name}) async {
    final list = _shoppingLists.firstWhere((l) => l.id == listId);
    final template = ListTemplate(
      id: _uuid.v4(),
      name: name ?? 'Plantilla: ${list.name}',
      items: list.items.map((item) => TemplateItem(
        id: _uuid.v4(),
        templateId: '',
        productId: item.productId,
        productName: item.productName,
        categoryId: item.categoryId,
        quantity: item.quantity,
        unit: item.unit,
        estimatedPrice: item.estimatedPrice,
      )).toList(),
    );

    final withId = template.copyWith(
      items: template.items
          .map((i) => TemplateItem(
                id: i.id,
                templateId: template.id,
                productId: i.productId,
                productName: i.productName,
                categoryId: i.categoryId,
                quantity: i.quantity,
                unit: i.unit,
                estimatedPrice: i.estimatedPrice,
              ))
          .toList(),
    );

    await _db.insertTemplate(withId);
    _templates.insert(0, withId);
    notifyListeners();
    return withId;
  }

  Future<ShoppingList> createFromTemplate(ListTemplate template,
      {String? name, double? budgetLimit}) async {
    final list = await createShoppingList(
      name: name ?? template.name,
      budgetLimit: budgetLimit,
    );

    for (final tItem in template.items) {
      final item = ShoppingItem(
        id: _uuid.v4(),
        shoppingListId: list.id,
        productId: tItem.productId,
        productName: tItem.productName,
        categoryId: tItem.categoryId,
        quantity: tItem.quantity,
        unit: tItem.unit,
        estimatedPrice: tItem.estimatedPrice,
      );
      await _db.insertShoppingItem(item);
    }

    await loadShoppingLists();
    return _shoppingLists.firstWhere((l) => l.id == list.id);
  }

  Future<void> deleteTemplate(String templateId) async {
    await _db.deleteTemplate(templateId);
    _templates.removeWhere((t) => t.id == templateId);
    notifyListeners();
  }

  Future<void> sendShoppingReminder(String listId) async {
    final list = _shoppingLists.firstWhere((l) => l.id == listId);
    final pendingItems = list.items.where((i) => !i.isPurchased).length;
    await _notifications.showShoppingReminder(list.name, pendingItems);
  }
}
