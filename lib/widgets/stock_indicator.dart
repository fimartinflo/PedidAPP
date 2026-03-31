import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class StockIndicator extends StatelessWidget {
  final double currentStock;
  final double minimumStock;
  final String unit;
  final bool showLabel;
  final bool compact;

  const StockIndicator({
    super.key,
    required this.currentStock,
    required this.minimumStock,
    this.unit = 'unidad',
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = AppConstants.getStockStatus(currentStock, minimumStock);
    final color = _colorForStatus(status);
    final label = AppConstants.stockStatusLabels[status]!;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${currentStock.toStringAsFixed(1)} $unit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: minimumStock > 0
                ? (currentStock / (minimumStock * 3)).clamp(0.0, 1.0)
                : 1.0,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            color: color,
          ),
        ),
      ],
    );
  }

  static Color _colorForStatus(String status) {
    switch (status) {
      case 'out':
        return AppTheme.errorColor;
      case 'low':
        return AppTheme.warningColor;
      default:
        return AppTheme.successColor;
    }
  }
}
