import 'package:pedidapp/models/product.dart';
import 'package:pedidapp/services/notification_service.dart';

/// Fake NotificationService for testing — records calls without platform plugins.
class FakeNotificationService extends NotificationService {
  FakeNotificationService() : super.forTesting();

  final List<String> calls = [];
  List<Product> lastLowStockProducts = [];
  double? lastBudgetWarningPercent;
  ShoppingReminder? lastSavedReminder;

  @override
  Future<void> initialize() async {
    calls.add('initialize');
  }

  @override
  Future<void> requestPermissions() async {
    calls.add('requestPermissions');
  }

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    calls.add('setNotificationsEnabled:$enabled');
  }

  @override
  Future<void> showLowStockNotification(List<Product> lowStockProducts) async {
    calls.add('showLowStockNotification');
    lastLowStockProducts = lowStockProducts;
  }

  @override
  Future<void> showShoppingReminder(String listName, int itemCount) async {
    calls.add('showShoppingReminder:$listName');
  }

  @override
  Future<void> showBudgetWarning(double percentUsed) async {
    calls.add('showBudgetWarning');
    lastBudgetWarningPercent = percentUsed;
  }

  @override
  Future<ShoppingReminder> getShoppingReminder() async {
    return lastSavedReminder ?? const ShoppingReminder();
  }

  @override
  Future<void> saveShoppingReminder(ShoppingReminder reminder) async {
    calls.add('saveShoppingReminder:${reminder.dayName}');
    lastSavedReminder = reminder;
  }

  @override
  Future<void> cancelShoppingReminder() async {
    calls.add('cancelShoppingReminder');
  }
}
