import 'package:flutter_test/flutter_test.dart';
import 'package:pedidapp/models/product.dart';

void main() {
  group('Product', () {
    late Product product;

    setUp(() {
      product = Product(
        id: 'prod_1',
        name: 'Leche',
        categoryId: 'cat_1',
        unit: 'litro',
        currentStock: 2,
        minimumStock: 3,
        estimatedPrice: 1.50,
        notes: 'Descremada',
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1),
      );
    });

    test('constructor sets default values correctly', () {
      final p = Product(id: 'x', name: 'Test', categoryId: 'c1');
      expect(p.unit, 'unidad');
      expect(p.currentStock, 0);
      expect(p.minimumStock, 1);
      expect(p.estimatedPrice, isNull);
      expect(p.notes, isNull);
      expect(p.barcode, isNull);
    });

    group('computed getters', () {
      test('isLowStock returns true when stock <= minimum', () {
        expect(product.isLowStock, true);
      });

      test('isLowStock returns false when stock > minimum', () {
        final p = product.copyWith(currentStock: 5);
        expect(p.isLowStock, false);
      });

      test('isOutOfStock returns true when stock <= 0', () {
        final p = product.copyWith(currentStock: 0);
        expect(p.isOutOfStock, true);
      });

      test('isOutOfStock returns false when stock > 0', () {
        expect(product.isOutOfStock, false);
      });

      test('stockNeeded calculates correctly when low', () {
        // minimumStock - currentStock + minimumStock = 3 - 2 + 3 = 4
        expect(product.stockNeeded, 4);
      });

      test('stockNeeded returns 0 when stock is sufficient', () {
        final p = product.copyWith(currentStock: 5);
        expect(p.stockNeeded, 0);
      });
    });

    group('serialization', () {
      test('toMap produces correct map', () {
        final map = product.toMap();
        expect(map['id'], 'prod_1');
        expect(map['name'], 'Leche');
        expect(map['categoryId'], 'cat_1');
        expect(map['unit'], 'litro');
        expect(map['currentStock'], 2.0);
        expect(map['minimumStock'], 3.0);
        expect(map['estimatedPrice'], 1.50);
        expect(map['notes'], 'Descremada');
      });

      test('fromMap roundtrips correctly', () {
        final map = product.toMap();
        final restored = Product.fromMap(map);
        expect(restored.id, product.id);
        expect(restored.name, product.name);
        expect(restored.categoryId, product.categoryId);
        expect(restored.unit, product.unit);
        expect(restored.currentStock, product.currentStock);
        expect(restored.minimumStock, product.minimumStock);
        expect(restored.estimatedPrice, product.estimatedPrice);
        expect(restored.notes, product.notes);
      });

      test('fromMap handles null optional fields', () {
        final map = {
          'id': 'x',
          'name': 'Test',
          'categoryId': 'c1',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
        final p = Product.fromMap(map);
        expect(p.unit, 'unidad');
        expect(p.currentStock, 0);
        expect(p.minimumStock, 1);
        expect(p.estimatedPrice, isNull);
      });
    });

    group('copyWith', () {
      test('preserves unchanged fields', () {
        final copy = product.copyWith(name: 'Leche Entera');
        expect(copy.id, product.id);
        expect(copy.name, 'Leche Entera');
        expect(copy.categoryId, product.categoryId);
        expect(copy.currentStock, product.currentStock);
      });

      test('updates specified fields', () {
        final copy = product.copyWith(
          currentStock: 10,
          estimatedPrice: 2.0,
        );
        expect(copy.currentStock, 10);
        expect(copy.estimatedPrice, 2.0);
        expect(copy.name, product.name);
      });
    });
  });
}
