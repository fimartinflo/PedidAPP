import 'package:flutter_test/flutter_test.dart';
import 'package:pedidapp/models/budget.dart';

void main() {
  group('MonthlyBudget', () {
    late MonthlyBudget budget;

    setUp(() {
      budget = MonthlyBudget(
        id: 'b1',
        year: 2026,
        month: 3,
        budgetAmount: 500,
        spentAmount: 350,
      );
    });

    group('computed getters', () {
      test('remainingAmount calculates correctly', () {
        expect(budget.remainingAmount, 150);
      });

      test('percentUsed calculates correctly', () {
        expect(budget.percentUsed, 70);
      });

      test('percentUsed returns 0 when budgetAmount is 0', () {
        final b = budget.copyWith(budgetAmount: 0);
        expect(b.percentUsed, 0);
      });

      test('isOverBudget returns false when under budget', () {
        expect(budget.isOverBudget, false);
      });

      test('isOverBudget returns true when over budget', () {
        final b = budget.copyWith(spentAmount: 600);
        expect(b.isOverBudget, true);
      });

      test('monthName returns correct Spanish month', () {
        expect(budget.monthName, 'Marzo');
        expect(budget.copyWith(month: 1).monthName, 'Enero');
        expect(budget.copyWith(month: 12).monthName, 'Diciembre');
      });

      test('remainingAmount can be negative when over budget', () {
        final b = budget.copyWith(spentAmount: 600);
        expect(b.remainingAmount, -100);
      });
    });

    group('serialization', () {
      test('toMap produces correct map', () {
        final map = budget.toMap();
        expect(map['id'], 'b1');
        expect(map['year'], 2026);
        expect(map['month'], 3);
        expect(map['budgetAmount'], 500.0);
        expect(map['spentAmount'], 350.0);
      });

      test('fromMap roundtrips correctly', () {
        final restored = MonthlyBudget.fromMap(budget.toMap());
        expect(restored.id, budget.id);
        expect(restored.year, budget.year);
        expect(restored.month, budget.month);
        expect(restored.budgetAmount, budget.budgetAmount);
        expect(restored.spentAmount, budget.spentAmount);
      });

      test('fromMap defaults spentAmount to 0', () {
        final map = {
          'id': 'x',
          'year': 2026,
          'month': 1,
          'budgetAmount': 100,
        };
        final b = MonthlyBudget.fromMap(map);
        expect(b.spentAmount, 0);
      });
    });

    group('copyWith', () {
      test('preserves unchanged fields', () {
        final copy = budget.copyWith(spentAmount: 400);
        expect(copy.budgetAmount, 500);
        expect(copy.spentAmount, 400);
        expect(copy.id, 'b1');
      });
    });
  });
}
