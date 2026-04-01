import 'package:flutter_test/flutter_test.dart';
import 'package:pedidapp/models/shopping_item.dart';
import 'package:pedidapp/models/shopping_list.dart';

void main() {
  group('ShoppingItem', () {
    late ShoppingItem item;

    setUp(() {
      item = ShoppingItem(
        id: 'si_1',
        shoppingListId: 'sl_1',
        productId: 'prod_1',
        productName: 'Leche',
        categoryId: 'cat_1',
        quantity: 2,
        unit: 'litro',
        estimatedPrice: 1.50,
      );
    });

    test('constructor sets default values', () {
      final i = ShoppingItem(
        id: 'x',
        shoppingListId: 'y',
        productId: 'z',
        productName: 'Test',
        categoryId: 'c1',
      );
      expect(i.quantity, 1);
      expect(i.unit, 'unidad');
      expect(i.isPurchased, false);
      expect(i.actualPrice, isNull);
    });

    test('totalEstimated calculates correctly', () {
      expect(item.totalEstimated, 3.0); // 1.50 * 2
    });

    test('totalEstimated returns 0 when no price', () {
      final i = item.copyWith(estimatedPrice: null);
      // copyWith won't set to null as it uses ?? operator
      // so we create a new one
      final noPrice = ShoppingItem(
        id: 'x',
        shoppingListId: 'y',
        productId: 'z',
        productName: 'Test',
        categoryId: 'c1',
        quantity: 5,
      );
      expect(noPrice.totalEstimated, 0);
    });

    test('totalActual uses actualPrice when available', () {
      final i = item.copyWith(actualPrice: 2.0);
      expect(i.totalActual, 4.0); // 2.0 * 2
    });

    test('totalActual falls back to estimatedPrice', () {
      expect(item.totalActual, 3.0); // 1.50 * 2
    });

    group('serialization', () {
      test('toMap converts isPurchased to int', () {
        final map = item.toMap();
        expect(map['isPurchased'], 0);

        final purchased = item.copyWith(isPurchased: true);
        expect(purchased.toMap()['isPurchased'], 1);
      });

      test('fromMap roundtrips correctly', () {
        final restored = ShoppingItem.fromMap(item.toMap());
        expect(restored.id, item.id);
        expect(restored.productName, item.productName);
        expect(restored.quantity, item.quantity);
        expect(restored.estimatedPrice, item.estimatedPrice);
        expect(restored.isPurchased, item.isPurchased);
      });
    });
  });

  group('ShoppingList', () {
    late ShoppingList list;
    late List<ShoppingItem> items;

    setUp(() {
      items = [
        ShoppingItem(
          id: 'si_1',
          shoppingListId: 'sl_1',
          productId: 'p1',
          productName: 'Leche',
          categoryId: 'c1',
          quantity: 2,
          estimatedPrice: 1.50,
          isPurchased: true,
        ),
        ShoppingItem(
          id: 'si_2',
          shoppingListId: 'sl_1',
          productId: 'p2',
          productName: 'Pan',
          categoryId: 'c2',
          quantity: 1,
          estimatedPrice: 0.80,
          isPurchased: false,
        ),
      ];
      list = ShoppingList(
        id: 'sl_1',
        name: 'Compras Semana',
        createdAt: DateTime(2026, 3, 15),
        status: ShoppingListStatus.active,
        budgetLimit: 10.0,
        items: items,
      );
    });

    test('totalItems returns item count', () {
      expect(list.totalItems, 2);
    });

    test('purchasedItems counts only purchased', () {
      expect(list.purchasedItems, 1);
    });

    test('progress calculates correctly', () {
      expect(list.progress, 0.5);
    });

    test('progress returns 0 for empty list', () {
      final empty = list.copyWith(items: []);
      expect(empty.progress, 0);
    });

    test('totalEstimated sums all items', () {
      expect(list.totalEstimated, 3.80); // 3.0 + 0.80
    });

    test('isOverBudget works correctly', () {
      expect(list.isOverBudget, false);
      final overBudget = list.copyWith(budgetLimit: 1.0);
      expect(overBudget.isOverBudget, true);
    });

    test('isOverBudget returns false when no budget limit', () {
      final noBudget = list.copyWith(budgetLimit: null);
      // copyWith with null won't work due to ?? operator, test with new instance
      final nl = ShoppingList(
        id: 'sl_2',
        name: 'Test',
        items: items,
      );
      expect(nl.isOverBudget, false);
    });

    group('serialization', () {
      test('toMap does not include items', () {
        final map = list.toMap();
        expect(map.containsKey('items'), false);
        expect(map['status'], 'active');
      });

      test('fromMap roundtrips correctly', () {
        final restored = ShoppingList.fromMap(list.toMap(), items: items);
        expect(restored.id, list.id);
        expect(restored.name, list.name);
        expect(restored.status, ShoppingListStatus.active);
        expect(restored.items.length, 2);
      });

      test('fromMap defaults status to active', () {
        final map = {
          'id': 'x',
          'name': 'Test',
          'createdAt': DateTime.now().toIso8601String(),
          'status': 'unknown',
        };
        final sl = ShoppingList.fromMap(map);
        expect(sl.status, ShoppingListStatus.active);
      });
    });

    group('copyWith', () {
      test('updates status correctly', () {
        final completed = list.copyWith(
          status: ShoppingListStatus.completed,
          completedAt: DateTime(2026, 3, 16),
        );
        expect(completed.status, ShoppingListStatus.completed);
        expect(completed.completedAt, DateTime(2026, 3, 16));
        expect(completed.name, list.name);
      });
    });
  });
}
