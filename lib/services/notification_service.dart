import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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
}
