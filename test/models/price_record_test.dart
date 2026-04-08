import 'package:flutter_test/flutter_test.dart';
import 'package:pedidapp/models/price_record.dart';

void main() {
  group('PriceRecord', () {
    test('constructor sets default date to now', () {
      final before = DateTime.now();
      final record = PriceRecord(
        id: 'pr1',
        productId: 'p1',
        price: 9.99,
      );
      final after = DateTime.now();

      expect(record.id, 'pr1');
      expect(record.productId, 'p1');
      expect(record.price, 9.99);
      expect(record.source, isNull);
      expect(record.date.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(
          record.date.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('constructor with explicit date and source', () {
      final date = DateTime(2026, 3, 15);
      final record = PriceRecord(
        id: 'pr2',
        productId: 'p2',
        price: 15.50,
        date: date,
        source: 'shopping_list',
      );

      expect(record.date, date);
      expect(record.source, 'shopping_list');
    });

    test('toMap serializes correctly', () {
      final date = DateTime(2026, 4, 1, 10, 30);
      final record = PriceRecord(
        id: 'pr3',
        productId: 'p3',
        price: 25.00,
        date: date,
        source: 'manual',
      );

      final map = record.toMap();
      expect(map['id'], 'pr3');
      expect(map['productId'], 'p3');
      expect(map['price'], 25.00);
      expect(map['date'], date.toIso8601String());
      expect(map['source'], 'manual');
    });

    test('toMap with null source', () {
      final record = PriceRecord(
        id: 'pr4',
        productId: 'p4',
        price: 10.0,
        date: DateTime(2026, 1, 1),
      );

      final map = record.toMap();
      expect(map['source'], isNull);
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'id': 'pr5',
        'productId': 'p5',
        'price': 33.75,
        'date': '2026-04-08T14:00:00.000',
        'source': 'receipt',
      };

      final record = PriceRecord.fromMap(map);
      expect(record.id, 'pr5');
      expect(record.productId, 'p5');
      expect(record.price, 33.75);
      expect(record.date, DateTime(2026, 4, 8, 14, 0));
      expect(record.source, 'receipt');
    });

    test('fromMap with null source', () {
      final map = {
        'id': 'pr6',
        'productId': 'p6',
        'price': 5,
        'date': '2026-01-01T00:00:00.000',
        'source': null,
      };

      final record = PriceRecord.fromMap(map);
      expect(record.source, isNull);
      expect(record.price, 5.0);
    });

    test('roundtrip toMap/fromMap preserves data', () {
      final original = PriceRecord(
        id: 'pr7',
        productId: 'p7',
        price: 99.99,
        date: DateTime(2026, 6, 15, 8, 30),
        source: 'shopping_list',
      );

      final restored = PriceRecord.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.productId, original.productId);
      expect(restored.price, original.price);
      expect(restored.date, original.date);
      expect(restored.source, original.source);
    });

    test('fromMap handles integer price', () {
      final map = {
        'id': 'pr8',
        'productId': 'p8',
        'price': 10,
        'date': '2026-01-01T00:00:00.000',
        'source': null,
      };

      final record = PriceRecord.fromMap(map);
      expect(record.price, 10.0);
      expect(record.price, isA<double>());
    });
  });
}
