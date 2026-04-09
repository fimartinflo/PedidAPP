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
}
