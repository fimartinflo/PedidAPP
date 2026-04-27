import 'package:flutter_test/flutter_test.dart';
import 'package:pedidapp/providers/budget_provider.dart';
import '../helpers/fake_database_service.dart';
import '../helpers/fake_notification_service.dart';

void main() {
  late FakeDatabaseService fakeDb;
  late FakeNotificationService fakeNotifications;
  late BudgetProvider provider;

  setUp(() {
    fakeDb = FakeDatabaseService();
    fakeNotifications = FakeNotificationService();
    provider = BudgetProvider(
      db: fakeDb,
      notifications: fakeNotifications,
    );
  });

  group('BudgetProvider', () {
    test('initial state has no budgets', () {
      expect(provider.budgets, isEmpty);
      expect(provider.currentBudget, isNull);
      expect(provider.isLoading, false);
    });

    test('setBudget creates a new budget', () async {
      await provider.setBudget(year: 2026, month: 4, amount: 500);

      expect(provider.budgets.length, 1);
      expect(provider.currentBudget, isNotNull);
      expect(provider.currentBudget!.budgetAmount, 500);
      expect(provider.currentBudget!.spentAmount, 0);
    });

    test('setBudget updates existing budget amount', () async {
      await provider.setBudget(year: 2026, month: 4, amount: 500);
      await provider.setBudget(year: 2026, month: 4, amount: 700);

      expect(provider.currentBudget!.budgetAmount, 700);
      expect(provider.currentBudget!.spentAmount, 0);
    });

    test('addExpense increases spent amount', () async {
      await provider.setBudget(year: 2026, month: 4, amount: 1000);

      await provider.addExpense(150);
      expect(provider.currentBudget!.spentAmount, 150);

      await provider.addExpense(200);
      expect(provider.currentBudget!.spentAmount, 350);
    });

    test('addExpense triggers warning at 80%', () async {
      await provider.setBudget(year: 2026, month: 4, amount: 100);

      await provider.addExpense(85);

      expect(provider.currentBudget!.percentUsed, 85);
      expect(
        fakeNotifications.calls.contains('showBudgetWarning'),
        true,
      );
    });

    test('addExpense does nothing when no current budget', () async {
      await provider.addExpense(100);
      expect(provider.currentBudget, isNull);
    });

    test('resetMonthlySpent resets spent to zero', () async {
      await provider.setBudget(year: 2026, month: 4, amount: 500);
      await provider.addExpense(300);

      await provider.resetMonthlySpent(2026, 4);
      expect(provider.currentBudget!.spentAmount, 0);
    });

    test('getLastMonths returns correct count', () async {
      await provider.setBudget(year: 2026, month: 1, amount: 400);
      await provider.setBudget(year: 2026, month: 2, amount: 450);
      await provider.setBudget(year: 2026, month: 3, amount: 500);
      await provider.setBudget(year: 2026, month: 4, amount: 550);

      final last3 = provider.getLastMonths(3);
      expect(last3.length, 3);
    });

    test('loadBudgets sets current budget for current month', () async {
      final now = DateTime.now();
      await provider.setBudget(
        year: now.year,
        month: now.month,
        amount: 600,
      );

      await provider.loadBudgets();

      expect(provider.currentBudget, isNotNull);
      expect(provider.currentBudget!.budgetAmount, 600);
    });
  });
}
