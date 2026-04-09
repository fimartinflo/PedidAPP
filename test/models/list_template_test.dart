import 'package:flutter_test/flutter_test.dart';
import 'package:pedidapp/models/list_template.dart';

void main() {
  group('ListTemplate', () {
    test('constructor sets default date to now', () {
      final before = DateTime.now();
      final template = ListTemplate(id: 't1', name: 'Test');
      final after = DateTime.now();

      expect(template.id, 't1');
      expect(template.name, 'Test');
      expect(template.items, isEmpty);
      expect(template.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(template.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('totalItems returns item count', () {
      final template = ListTemplate(
        id: 't1',
        name: 'Test',
        items: [
          TemplateItem(id: 'i1', templateId: 't1', productId: 'p1',
              productName: 'Leche', categoryId: 'c1'),
          TemplateItem(id: 'i2', templateId: 't1', productId: 'p2',
              productName: 'Pan', categoryId: 'c1'),
        ],
      );
      expect(template.totalItems, 2);
    });

    test('totalEstimated sums price * quantity', () {
      final template = ListTemplate(
        id: 't1',
        name: 'Test',
        items: [
          TemplateItem(id: 'i1', templateId: 't1', productId: 'p1',
              productName: 'Leche', categoryId: 'c1',
              quantity: 2, estimatedPrice: 10.0),
          TemplateItem(id: 'i2', templateId: 't1', productId: 'p2',
              productName: 'Pan', categoryId: 'c1',
              quantity: 1, estimatedPrice: 5.50),
        ],
      );
      expect(template.totalEstimated, 25.50);
    });

    test('totalEstimated with null prices', () {
      final template = ListTemplate(
        id: 't1',
        name: 'Test',
        items: [
          TemplateItem(id: 'i1', templateId: 't1', productId: 'p1',
              productName: 'Leche', categoryId: 'c1'),
        ],
      );
      expect(template.totalEstimated, 0);
    });

    test('toMap serializes correctly', () {
      final date = DateTime(2026, 4, 1);
      final template = ListTemplate(id: 't1', name: 'Semanal', createdAt: date);
      final map = template.toMap();

      expect(map['id'], 't1');
      expect(map['name'], 'Semanal');
      expect(map['createdAt'], date.toIso8601String());
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'id': 't2',
        'name': 'Mensual',
        'createdAt': '2026-04-01T00:00:00.000',
      };
      final template = ListTemplate.fromMap(map);

      expect(template.id, 't2');
      expect(template.name, 'Mensual');
      expect(template.createdAt, DateTime(2026, 4, 1));
      expect(template.items, isEmpty);
    });

    test('fromMap with items', () {
      final map = {
        'id': 't3',
        'name': 'Con items',
        'createdAt': '2026-04-01T00:00:00.000',
      };
      final items = [
        TemplateItem(id: 'i1', templateId: 't3', productId: 'p1',
            productName: 'Arroz', categoryId: 'c1'),
      ];
      final template = ListTemplate.fromMap(map, items: items);
      expect(template.items.length, 1);
      expect(template.items.first.productName, 'Arroz');
    });

    test('copyWith creates modified copy', () {
      final original = ListTemplate(id: 't1', name: 'Original');
      final copy = original.copyWith(name: 'Modified');

      expect(copy.id, 't1');
      expect(copy.name, 'Modified');
      expect(copy.createdAt, original.createdAt);
    });

    test('roundtrip toMap/fromMap preserves data', () {
      final original = ListTemplate(
        id: 't5',
        name: 'Roundtrip',
        createdAt: DateTime(2026, 6, 15),
      );
      final restored = ListTemplate.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.createdAt, original.createdAt);
    });
  });

  group('TemplateItem', () {
    test('constructor with defaults', () {
      final item = TemplateItem(
        id: 'i1',
        templateId: 't1',
        productId: 'p1',
        productName: 'Leche',
        categoryId: 'c1',
      );

      expect(item.quantity, 1);
      expect(item.unit, 'unidad');
      expect(item.estimatedPrice, isNull);
    });

    test('toMap serializes correctly', () {
      final item = TemplateItem(
        id: 'i1',
        templateId: 't1',
        productId: 'p1',
        productName: 'Leche',
        categoryId: 'c1',
        quantity: 3,
        unit: 'litro',
        estimatedPrice: 12.50,
      );
      final map = item.toMap();

      expect(map['id'], 'i1');
      expect(map['templateId'], 't1');
      expect(map['productId'], 'p1');
      expect(map['productName'], 'Leche');
      expect(map['categoryId'], 'c1');
      expect(map['quantity'], 3);
      expect(map['unit'], 'litro');
      expect(map['estimatedPrice'], 12.50);
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'id': 'i2',
        'templateId': 't2',
        'productId': 'p2',
        'productName': 'Pan',
        'categoryId': 'c2',
        'quantity': 2,
        'unit': 'kg',
        'estimatedPrice': 8.0,
      };
      final item = TemplateItem.fromMap(map);

      expect(item.id, 'i2');
      expect(item.templateId, 't2');
      expect(item.productName, 'Pan');
      expect(item.quantity, 2.0);
      expect(item.unit, 'kg');
      expect(item.estimatedPrice, 8.0);
    });

    test('fromMap with null estimatedPrice', () {
      final map = {
        'id': 'i3',
        'templateId': 't3',
        'productId': 'p3',
        'productName': 'Agua',
        'categoryId': 'c3',
        'quantity': null,
        'unit': null,
        'estimatedPrice': null,
      };
      final item = TemplateItem.fromMap(map);

      expect(item.quantity, 1);
      expect(item.unit, 'unidad');
      expect(item.estimatedPrice, isNull);
    });

    test('roundtrip toMap/fromMap preserves data', () {
      final original = TemplateItem(
        id: 'i5',
        templateId: 't5',
        productId: 'p5',
        productName: 'Huevos',
        categoryId: 'c5',
        quantity: 12,
        unit: 'unidad',
        estimatedPrice: 45.00,
      );
      final restored = TemplateItem.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.templateId, original.templateId);
      expect(restored.productId, original.productId);
      expect(restored.productName, original.productName);
      expect(restored.quantity, original.quantity);
      expect(restored.estimatedPrice, original.estimatedPrice);
    });
  });
}
