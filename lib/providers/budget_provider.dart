import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class BudgetProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notifications = NotificationService();
  final Uuid _uuid = const Uuid();

  List<MonthlyBudget> _budgets = [];
  MonthlyBudget? _currentBudget;
  bool _isLoading = false;

  List<MonthlyBudget> get budgets => _budgets;
  MonthlyBudget? get currentBudget => _currentBudget;
  bool get isLoading => _isLoading;

  Future<void> loadBudgets() async {
    _isLoading = true;
    notifyListeners();

    _budgets = await _db.getBudgets();
    final now = DateTime.now();
    _currentBudget = await _db.getBudgetForMonth(now.year, now.month);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setBudget({
    required int year,
    required int month,
    required double amount,
  }) async {
    final existing = await _db.getBudgetForMonth(year, month);
    final budget = MonthlyBudget(
      id: existing?.id ?? _uuid.v4(),
      year: year,
      month: month,
      budgetAmount: amount,
      spentAmount: existing?.spentAmount ?? 0,
    );

    await _db.insertOrUpdateBudget(budget);
    await loadBudgets();
  }

  Future<void> addExpense(double amount) async {
    if (_currentBudget == null) return;

    final updated = _currentBudget!.copyWith(
      spentAmount: _currentBudget!.spentAmount + amount,
    );

    await _db.insertOrUpdateBudget(updated);
    _currentBudget = updated;
    notifyListeners();

    if (updated.percentUsed >= 80) {
      await _notifications.showBudgetWarning(updated.percentUsed);
    }
  }

  Future<void> resetMonthlySpent(int year, int month) async {
    final budget = await _db.getBudgetForMonth(year, month);
    if (budget != null) {
      await _db.updateBudgetSpent(budget.id, 0);
      await loadBudgets();
    }
  }

  List<MonthlyBudget> getLastMonths(int count) {
    return _budgets.take(count).toList();
  }
}
