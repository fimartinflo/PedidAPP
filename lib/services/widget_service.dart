import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Updates the Android home screen widget with current inventory stats.
class WidgetService {
  static const String _androidWidgetName = 'PedidAppWidgetProvider';

  /// Updates widget data. Safe to call on iOS/web (no-op).
  static Future<void> updateWidget({
    required int totalProducts,
    required int lowStockCount,
    required int expiringCount,
  }) async {
    if (!_isAndroid) return;
    try {
      await HomeWidget.saveWidgetData<int>('total_products', totalProducts);
      await HomeWidget.saveWidgetData<int>('low_stock_count', lowStockCount);
      await HomeWidget.saveWidgetData<int>('expiring_count', expiringCount);
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }

  static bool get _isAndroid =>
      defaultTargetPlatform == TargetPlatform.android;
}
