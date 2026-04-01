import 'package:flutter_test/flutter_test.dart';
import 'package:pedidapp/models/product.dart';
import 'package:pedidapp/providers/shopping_list_provider.dart';
import '../helpers/fake_database_service.dart';
import '../helpers/fake_notification_service.dart';

void main() {
  late FakeDatabaseService fakeDb;
  late FakeNotificationService fakeNotifications;
  late ShoppingListProvider provider;

  setUp(() {
    fakeDb = FakeDatabaseService();
    fakeNotifications = FakeNotificationService();
    provider = ShoppingListProvider(
      db: fakeDb,
      notifications: fakeNotifications,
    );
  });

  group('ShoppingListProvider', () {
    test('initial state is empty', () {
      expect(provider.shoppingLists, isEmpty);
      expect(provider.activeLists, isEmpty);
      expect(provider.completedLists, isEmpty);
      expect(provider.isLoading, false);
    });

    test('createShoppingList adds a new list', () async {
      final list = await provider.createShoppingList(
        name: 'Compras Semana',
        budgetLimit: 100,
      );

      expect(list.name, 'Compras Semana');
      expect(list.budgetLimit, 100);
      expect(provider.shoppingLists.length, 1);
    });

    test('activeLists and completedLists filter correctly', () async {
      await provider.createShoppingList(name: 'Activa 1');
      await provider.createShoppingList(name: 'Activa 2');

      expect(provider.activeLists.length, 2);
      expect(provider.completedLists.length, 0);

      await provider.completeList(provider.shoppingLists.first.id);
      await provider.loadShoppingLists();

      expect(provider.activeLists.length, 1);
      expect(provider.completedLists.length, 1);
    });

    test('addItemToList adds item', () async {
      final list = await provider.createShoppingList(name: 'Test');

      await provider.addItemToList(
        listId: list.id,
        productId: 'prod_1',
        productName: 'Leche',
        categoryId: 'cat_1',
        quantity: 2,
        unit: 'litro',
        estimatedPrice: 1.50,
      );

      await provider.loadShoppingLists();
      final updated = provider.shoppingLists.first;
      expect(updated.items.length, 1);
      expect(updated.items.first.productName, 'Leche');
    });

    test('toggleItemPurchased toggles purchase state', () async {
      final list = await provider.createShoppingList(name: 'Test');
      await provider.addItemToList(
        listId: list.id,
        productId: 'prod_1',
        productName: 'Pan',
        categoryId: 'cat_1',
      );
      await provider.loadShoppingLists();

      final itemId = provider.shoppingLists.first.items.first.id;
      expect(provider.shoppingLists.first.items.first.isPurchased, false);

      await provider.toggleItemPurchased(list.id, itemId);
      expect(provider.shoppingLists.first.items.first.isPurchased, true);
    });

    test('removeItemFromList removes the item', () async {
      final list = await provider.createShoppingList(name: 'Test');
      await provider.addItemToList(
        listId: list.id,
        productId: 'prod_1',
        productName: 'Sal',
        categoryId: 'cat_1',
      );
      await provider.loadShoppingLists();

      final itemId = provider.shoppingLists.first.items.first.id;
      await provider.removeItemFromList(itemId);

      expect(provider.shoppingLists.first.items, isEmpty);
    });

    test('deleteList removes the list', () async {
      await provider.createShoppingList(name: 'Para borrar');
      expect(provider.shoppingLists.length, 1);

      await provider.deleteList(provider.shoppingLists.first.id);
      expect(provider.shoppingLists, isEmpty);
    });

    test('generateFromLowStock creates list with items', () async {
      final lowStockProducts = [
        Product(
          id: 'p1',
          name: 'Leche',
          categoryId: 'cat_1',
          currentStock: 1,
          minimumStock: 5,
          estimatedPrice: 1.50,
        ),
        Product(
          id: 'p2',
          name: 'Pan',
          categoryId: 'cat_2',
          currentStock: 0,
          minimumStock: 3,
          estimatedPrice: 2.00,
        ),
      ];

      final list = await provider.generateFromLowStock(lowStockProducts);

      expect(list.name, contains('Compras'));
      await provider.loadShoppingLists();

      final updatedList = provider.shoppingLists
          .firstWhere((l) => l.id == list.id);
      expect(updatedList.items.length, 2);
    });

    test('completeList marks as completed', () async {
      final list = await provider.createShoppingList(name: 'Completar');
      await provider.completeList(list.id);
      await provider.loadShoppingLists();

      final completed = provider.shoppingLists
          .firstWhere((l) => l.id == list.id);
      expect(completed.status.name, 'completed');
    });

    test('sendShoppingReminder calls notification service', () async {
      final list = await provider.createShoppingList(name: 'Recordatorio');
      await provider.addItemToList(
        listId: list.id,
        productId: 'p1',
        productName: 'Item',
        categoryId: 'c1',
      );
      await provider.loadShoppingLists();

      await provider.sendShoppingReminder(list.id);
      expect(
        fakeNotifications.calls,
        contains('showShoppingReminder:Recordatorio'),
      );
    });
  });
}
