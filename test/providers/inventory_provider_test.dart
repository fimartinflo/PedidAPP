import 'package:flutter_test/flutter_test.dart';
import 'package:pedidapp/providers/inventory_provider.dart';
import '../helpers/fake_database_service.dart';
import '../helpers/fake_notification_service.dart';

void main() {
  late FakeDatabaseService fakeDb;
  late FakeNotificationService fakeNotifications;
  late InventoryProvider provider;

  setUp(() {
    fakeDb = FakeDatabaseService();
    fakeNotifications = FakeNotificationService();
    provider = InventoryProvider(
      db: fakeDb,
      notifications: fakeNotifications,
    );
  });

  group('InventoryProvider', () {
    test('initial state is empty', () {
      expect(provider.products, isEmpty);
      expect(provider.categories, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    test('loadData populates categories and products', () async {
      await provider.loadData();

      expect(provider.categories, isNotEmpty);
      expect(provider.categories.length, 10); // 10 default categories
      expect(provider.isLoading, false);
    });

    test('addProduct adds to list and persists', () async {
      await provider.loadData();
      final catId = provider.categories.first.id;

      await provider.addProduct(
        name: 'Arroz',
        categoryId: catId,
        unit: 'kg',
        currentStock: 5,
        minimumStock: 2,
        estimatedPrice: 3.50,
      );

      expect(provider.products.length, 1);
      expect(provider.products.first.name, 'Arroz');
      expect(provider.products.first.unit, 'kg');
      expect(provider.products.first.currentStock, 5);
    });

    test('updateStock updates product stock', () async {
      await provider.loadData();
      await provider.addProduct(
        name: 'Leche',
        categoryId: provider.categories.first.id,
        currentStock: 10,
        minimumStock: 3,
      );

      final productId = provider.products.first.id;
      await provider.updateStock(productId, 2);

      expect(provider.products.first.currentStock, 2);
    });

    test('incrementStock increases stock', () async {
      await provider.loadData();
      await provider.addProduct(
        name: 'Pan',
        categoryId: provider.categories.first.id,
        currentStock: 3,
        minimumStock: 1,
      );

      final productId = provider.products.first.id;
      await provider.incrementStock(productId, 2);

      expect(provider.products.first.currentStock, 5);
    });

    test('decrementStock decreases stock and logs consumption', () async {
      await provider.loadData();
      await provider.addProduct(
        name: 'Huevos',
        categoryId: provider.categories.first.id,
        currentStock: 12,
        minimumStock: 4,
      );

      final productId = provider.products.first.id;
      await provider.decrementStock(productId, 3);

      expect(provider.products.first.currentStock, 9);
    });

    test('decrementStock does not go below zero', () async {
      await provider.loadData();
      await provider.addProduct(
        name: 'Sal',
        categoryId: provider.categories.first.id,
        currentStock: 1,
        minimumStock: 2,
      );

      final productId = provider.products.first.id;
      await provider.decrementStock(productId, 5);

      expect(provider.products.first.currentStock, 0);
    });

    test('deleteProduct removes from list', () async {
      await provider.loadData();
      await provider.addProduct(
        name: 'Azucar',
        categoryId: provider.categories.first.id,
      );

      expect(provider.products.length, 1);

      await provider.deleteProduct(provider.products.first.id);
      expect(provider.products, isEmpty);
    });

    test('lowStockProducts filters correctly', () async {
      await provider.loadData();
      final catId = provider.categories.first.id;

      await provider.addProduct(
        name: 'Normal',
        categoryId: catId,
        currentStock: 10,
        minimumStock: 2,
      );
      await provider.addProduct(
        name: 'Bajo',
        categoryId: catId,
        currentStock: 1,
        minimumStock: 5,
      );

      expect(provider.lowStockProducts.length, 1);
      expect(provider.lowStockProducts.first.name, 'Bajo');
    });

    test('searchProducts filters by name', () async {
      await provider.loadData();
      final catId = provider.categories.first.id;

      await provider.addProduct(name: 'Leche Entera', categoryId: catId);
      await provider.addProduct(name: 'Leche Descremada', categoryId: catId);
      await provider.addProduct(name: 'Pan Integral', categoryId: catId);

      final results = provider.searchProducts('leche');
      expect(results.length, 2);
    });

    test('low stock triggers notification', () async {
      await provider.loadData();
      await provider.addProduct(
        name: 'Jabón',
        categoryId: provider.categories.first.id,
        currentStock: 5,
        minimumStock: 3,
      );

      final productId = provider.products.first.id;
      await provider.updateStock(productId, 2);

      expect(
        fakeNotifications.calls.contains('showLowStockNotification'),
        true,
      );
    });

    test('addCategory adds new category', () async {
      await provider.loadData();
      final initialCount = provider.categories.length;

      await provider.addCategory(name: 'Mascotas', icon: 'pets');

      expect(provider.categories.length, initialCount + 1);
      expect(provider.categories.last.name, 'Mascotas');
    });

    test('deleteCategory removes category', () async {
      await provider.loadData();
      final initialCount = provider.categories.length;
      final catId = provider.categories.last.id;

      await provider.deleteCategory(catId);

      expect(provider.categories.length, initialCount - 1);
    });
  });
}
