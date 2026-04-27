import 'package:flutter_test/flutter_test.dart';
import 'package:pedidapp/models/consumption_log.dart';

void main() {
  group('ConsumptionLog', () {
    test('constructor sets timestamp to now when not provided', () {
      final before = DateTime.now();
      final log = ConsumptionLog(
        id: 'log_1',
        productId: 'prod_1',
        quantity: 2.5,
      );
      final after = DateTime.now();

      expect(log.id, 'log_1');
      expect(log.productId, 'prod_1');
      expect(log.quantity, 2.5);
      expect(
        log.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        log.timestamp.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('constructor uses provided timestamp', () {
      final ts = DateTime(2026, 1, 15, 10, 30);
      final log = ConsumptionLog(
        id: 'log_2',
        productId: 'prod_2',
        quantity: 1.0,
        timestamp: ts,
      );

      expect(log.timestamp, ts);
    });

    group('serialization', () {
      test('toMap produces correct map', () {
        final ts = DateTime(2026, 3, 1, 12, 0);
        final log = ConsumptionLog(
          id: 'log_1',
          productId: 'prod_1',
          quantity: 3.0,
          timestamp: ts,
        );

        final map = log.toMap();
        expect(map['id'], 'log_1');
        expect(map['productId'], 'prod_1');
        expect(map['quantity'], 3.0);
        expect(map['timestamp'], ts.toIso8601String());
      });

      test('fromMap roundtrips correctly', () {
        final ts = DateTime(2026, 3, 1, 12, 0);
        final original = ConsumptionLog(
          id: 'log_1',
          productId: 'prod_1',
          quantity: 3.0,
          timestamp: ts,
        );

        final restored = ConsumptionLog.fromMap(original.toMap());
        expect(restored.id, original.id);
        expect(restored.productId, original.productId);
        expect(restored.quantity, original.quantity);
        expect(restored.timestamp, original.timestamp);
      });

      test('fromMap handles integer quantity', () {
        final map = {
          'id': 'log_1',
          'productId': 'prod_1',
          'quantity': 5,
          'timestamp': '2026-03-01T12:00:00.000',
        };
        final log = ConsumptionLog.fromMap(map);
        expect(log.quantity, 5.0);
      });
    });
  });
}
