import 'package:flutter_test/flutter_test.dart';
import 'package:pedidapp/services/receipt_parser_service.dart';

void main() {
  late ReceiptParserService parser;

  setUp(() {
    parser = ReceiptParserService();
  });

  tearDown(() {
    parser.dispose();
  });

  // =========================================================================
  // _parseLine (via @visibleForTesting parseLine)
  // =========================================================================

  group('parseLine - price extraction', () {
    test('extracts price with dollar sign', () {
      final item = parser.parseLine('Leche entera \$1.50');
      expect(item?.price, 1.50);
    });

    test('extracts price without dollar sign', () {
      final item = parser.parseLine('Pan integral 3.20');
      expect(item?.price, 3.20);
    });

    test('extracts price with comma decimal separator', () {
      final item = parser.parseLine('Arroz 2,50');
      expect(item?.price, 2.50);
    });

    test('no price field when line has no price', () {
      final item = parser.parseLine('Mantequilla');
      expect(item?.price, isNull);
    });
  });

  group('parseLine - quantity extraction', () {
    test('quantity prefix 2x', () {
      final item = parser.parseLine('2x Leche 1.50');
      expect(item?.quantity, 2.0);
    });

    test('quantity prefix 3 x with spaces', () {
      final item = parser.parseLine('3 x Pan 2.00');
      expect(item?.quantity, 3.0);
    });

    test('quantity suffix KG', () {
      final item = parser.parseLine('Azucar 2 KG 4.00');
      expect(item?.quantity, 2.0);
      expect(item?.unit, 'kg');
    });

    test('quantity suffix GR', () {
      final item = parser.parseLine('Sal 500 GR 1.00');
      expect(item?.quantity, 500.0);
      expect(item?.unit, 'gramo');
    });

    test('quantity suffix LT', () {
      final item = parser.parseLine('Aceite 1 LT 3.50');
      expect(item?.quantity, 1.0);
      expect(item?.unit, 'litro');
    });

    test('quantity suffix ML', () {
      final item = parser.parseLine('Jugo 500 ML 2.00');
      expect(item?.unit, 'ml');
    });

    test('quantity suffix UN', () {
      final item = parser.parseLine('Huevos 12 UN 5.00');
      expect(item?.unit, 'unidad');
    });

    test('quantity suffix PZ', () {
      final item = parser.parseLine('Limones 6 PZ 1.50');
      expect(item?.unit, 'pieza');
    });

    test('default quantity is 1 when not specified', () {
      final item = parser.parseLine('Mantequilla 2.50');
      expect(item?.quantity, 1.0);
    });

    test('default unit is unidad when not specified', () {
      final item = parser.parseLine('Yogur 1.80');
      expect(item?.unit, 'unidad');
    });
  });

  group('parseLine - name cleanup', () {
    test('normalizes product name to title case', () {
      final item = parser.parseLine('LECHE DESCREMADA 1.50');
      expect(item?.name, 'Leche Descremada');
    });

    test('removes leading product codes (4+ digits)', () {
      final item = parser.parseLine('1234 Leche 1.50');
      expect(item?.name, isNot(contains('1234')));
    });

    test('keeps product name without trailing price', () {
      final item = parser.parseLine('Coca Cola 2.50');
      expect(item?.name, 'Coca Cola');
      expect(item?.price, 2.50);
    });
  });

  group('parseLine - invalid/skipped lines', () {
    test('returns null for very short lines (< 3 chars)', () {
      expect(parser.parseLine('AB'), isNull);
    });

    test('returns null for empty line', () {
      expect(parser.parseLine(''), isNull);
    });

    test('returns null for subtotal line', () {
      expect(parser.parseLine('Subtotal 25.00'), isNull);
    });

    test('returns null for total line', () {
      expect(parser.parseLine('Total 28.00'), isNull);
    });

    test('returns null for descuento line', () {
      expect(parser.parseLine('Descuento 2.00'), isNull);
    });

    test('returns null for efectivo line', () {
      expect(parser.parseLine('Efectivo 30.00'), isNull);
    });

    test('returns null for separator line', () {
      expect(parser.parseLine('----------'), isNull);
    });

    test('returns null for RFC line', () {
      expect(parser.parseLine('RFC: ABC123456789'), isNull);
    });

    test('returns null for date line dd/mm/yyyy', () {
      expect(parser.parseLine('15/03/2026'), isNull);
    });

    test('returns null for cajero line', () {
      expect(parser.parseLine('Cajero: Juan'), isNull);
    });

    test('returns null for IVA line', () {
      expect(parser.parseLine('IVA 16% 2.40'), isNull);
    });

    test('returns null for gracias line', () {
      expect(parser.parseLine('Gracias por su compra'), isNull);
    });
  });

  group('parseLine - valid products pass through', () {
    test('product with name and price', () {
      final item = parser.parseLine('Coca Cola 2.50');
      expect(item, isNotNull);
    });

    test('product name only (no price)', () {
      final item = parser.parseLine('Jamon Serrano');
      expect(item, isNotNull);
      expect(item?.price, isNull);
    });

    test('fractional quantity', () {
      final item = parser.parseLine('1.5 x Pollo 8.00');
      expect(item?.quantity, 1.5);
    });
  });

  // =========================================================================
  // extractTotal (via @visibleForTesting extractTotal)
  // =========================================================================

  group('extractTotal', () {
    test('extracts total with dollar sign', () {
      const text = 'Subtotal \$20.00\nTotal \$23.50\nEfectivo \$25.00';
      expect(parser.extractTotal(text), 23.50);
    });

    test('extracts total case-insensitive TOTAL', () {
      expect(parser.extractTotal('TOTAL 15.75'), 15.75);
    });

    test('extracts total with comma separator', () {
      expect(parser.extractTotal('Total 45,90'), 45.90);
    });

    test('returns null when no total found', () {
      expect(parser.extractTotal('Leche 1.50\nPan 2.00'), isNull);
    });

    test('picks first total when multiple exist', () {
      const text = 'Total 10.00\nTotal parcial 5.00';
      expect(parser.extractTotal(text), 10.00);
    });
  });

  // =========================================================================
  // ReceiptItem model
  // =========================================================================

  group('ReceiptItem', () {
    test('toString shows name and quantity', () {
      const item = ReceiptItem(name: 'Leche', quantity: 2);
      expect(item.toString(), contains('Leche'));
      expect(item.toString(), contains('x2'));
    });

    test('toString shows price when present', () {
      const item = ReceiptItem(name: 'Pan', quantity: 1, price: 3.00);
      expect(item.toString(), contains('\$3.0'));
    });

    test('default unit is unidad', () {
      const item = ReceiptItem(name: 'Sal', quantity: 1);
      expect(item.unit, 'unidad');
    });
  });
}
