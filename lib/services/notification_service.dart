import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class ShoppingReminder {
  final bool enabled;
  final int dayOfWeek; // 1=Mon, 7=Sun
  final int hour;
  final int minute;

  const ShoppingReminder({
    this.enabled = false,
    this.dayOfWeek = 6, // Saturday
    this.hour = 9,
    this.minute = 0,
  });

  String get dayName {
    const days = [
      'Lunes', 'Martes', 'Miercoles', 'Jueves',
      'Viernes', 'Sabado', 'Domingo'
    ];
    return days[dayOfWeek - 1];
  }

  String get timeString {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Constructor for testing subclasses
  @protected
  NotificationService.forTesting();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  Future<void> showLowStockNotification(List<Product> lowStockProducts) async {
    if (lowStockProducts.isEmpty) return;

    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    final count = lowStockProducts.length;
    final productNames = lowStockProducts
        .take(3)
        .map((p) => p.name)
        .join(', ');
    final suffix = count > 3 ? ' y ${count - 3} más' : '';

    const androidDetails = AndroidNotificationDetails(
      'low_stock_channel',
      'Alertas de Stock Bajo',
      channelDescription: 'Notificaciones cuando productos tienen stock bajo',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'Stock Bajo - $count producto${count > 1 ? 's' : ''}',
      '$productNames$suffix necesita${count > 1 ? 'n' : ''} reposición',
      details,
    );
  }

  Future<void> showShoppingReminder(String listName, int itemCount) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    const androidDetails = AndroidNotificationDetails(
      'shopping_reminder_channel',
      'Recordatorios de Compras',
      channelDescription: 'Recordatorios para ir de compras',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      'Recordatorio de Compras',
      'Tienes $itemCount productos pendientes en "$listName"',
      details,
    );
  }

  Future<void> showBudgetWarning(double percentUsed) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    const androidDetails = AndroidNotificationDetails(
      'budget_channel',
      'Alertas de Presupuesto',
      channelDescription: 'Notificaciones sobre el presupuesto mensual',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    String title;
    String body;

    if (percentUsed >= 100) {
      title = 'Presupuesto Excedido';
      body = 'Has superado tu presupuesto mensual de compras';
    } else if (percentUsed >= 80) {
      title = 'Presupuesto al ${percentUsed.toStringAsFixed(0)}%';
      body = 'Estás cerca de alcanzar tu límite mensual';
    } else {
      return;
    }

    await _notifications.show(2, title, body, details);
  }

  // ==================== SCHEDULED REMINDERS ====================

  static const int _reminderNotificationId = 100;

  Future<ShoppingReminder> getShoppingReminder() async {
    final prefs = await SharedPreferences.getInstance();
    return ShoppingReminder(
      enabled: prefs.getBool('reminder_enabled') ?? false,
      dayOfWeek: prefs.getInt('reminder_day') ?? 6,
      hour: prefs.getInt('reminder_hour') ?? 9,
      minute: prefs.getInt('reminder_minute') ?? 0,
    );
  }

  Future<void> saveShoppingReminder(ShoppingReminder reminder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', reminder.enabled);
    await prefs.setInt('reminder_day', reminder.dayOfWeek);
    await prefs.setInt('reminder_hour', reminder.hour);
    await prefs.setInt('reminder_minute', reminder.minute);

    if (reminder.enabled) {
      await _scheduleWeeklyReminder(reminder);
    } else {
      await cancelShoppingReminder();
    }
  }

  Future<void> _scheduleWeeklyReminder(ShoppingReminder reminder) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    // Cancel existing reminder first
    await _notifications.cancel(_reminderNotificationId);

    const androidDetails = AndroidNotificationDetails(
      'shopping_reminder_channel',
      'Recordatorios de Compras',
      channelDescription: 'Recordatorio semanal para ir de compras',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.periodicallyShow(
      _reminderNotificationId,
      'Recordatorio de Compras',
      'Es ${reminder.dayName} - hora de revisar tu lista de compras',
      RepeatInterval.weekly,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelShoppingReminder() async {
    await _notifications.cancel(_reminderNotificationId);
  }

  // ==================== EXPIRY NOTIFICATIONS ====================

  /// Notification IDs for expiry start at 1000 + hash to avoid collisions
  int _expiryNotificationId(String productId) =>
      1000 + (productId.hashCode & 0x7FFFFFFF) % 100000;

  /// Schedules a notification when a product is 3 days from expiry.
  /// Currently uses immediate show if already within 3 days, since
  /// flutter_local_notifications zonedSchedule requires timezone setup.
  Future<void> scheduleExpiryNotification(Product product) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;
    if (product.expiryDate == null) return;

    final id = _expiryNotificationId(product.id);
    await _notifications.cancel(id);

    final days = product.daysUntilExpiry;
    if (days == null) return;

    // Only show immediate alert if expiring soon or expired
    if (days < 0) {
      await _showExpiryNotification(id, product, expired: true);
    } else if (days <= 3) {
      await _showExpiryNotification(id, product, expired: false);
    }
  }

  Future<void> _showExpiryNotification(int id, Product product,
      {required bool expired}) async {
    const androidDetails = AndroidNotificationDetails(
      'expiry_channel',
      'Vencimientos',
      channelDescription: 'Alertas de productos próximos a vencer',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final title = expired ? 'Producto Vencido' : 'Producto por Vencer';
    final body = expired
        ? '${product.name} ya está vencido'
        : '${product.name} vence en ${product.daysUntilExpiry} día'
            '${product.daysUntilExpiry == 1 ? '' : 's'}';

    await _notifications.show(id, title, body, details);
  }

  /// Cancels any pending expiry notification for a product.
  Future<void> cancelExpiryNotification(String productId) async {
    await _notifications.cancel(_expiryNotificationId(productId));
  }

  /// Sends notifications for all products that are expiring soon (called on app start).
  Future<void> checkAndNotifyExpiring(List<Product> products) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    final expiringSoon = products
        .where((p) => p.expiryDate != null && (p.isExpiringSoon || p.isExpired))
        .toList();

    if (expiringSoon.isEmpty) return;

    final count = expiringSoon.length;
    final names = expiringSoon.take(3).map((p) => p.name).join(', ');
    final suffix = count > 3 ? ' y ${count - 3} más' : '';

    const androidDetails = AndroidNotificationDetails(
      'expiry_channel',
      'Vencimientos',
      channelDescription: 'Alertas de productos próximos a vencer',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      999,
      'Productos próximos a vencer ($count)',
      '$names$suffix',
      details,
    );
  }
}
