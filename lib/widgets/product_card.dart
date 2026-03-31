import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'category_avatar.dart';
import 'stock_indicator.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final Category category;
  final VoidCallback? onTap;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const ProductCard({
    super.key,
    required this.product,
    required this.category,
    this.onTap,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final stockStatus =
        AppConstants.getStockStatus(product.currentStock, product.minimumStock);

    return Card(
      child: ListTile(
        leading: CategoryAvatar(category: category),
        title: Text(product.name),
        subtitle: Text(
          '${product.currentStock.toStringAsFixed(1)} ${product.unit} '
          '(min: ${product.minimumStock.toStringAsFixed(1)})',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stockStatus != 'ok')
              StockIndicator(
                currentStock: product.currentStock,
                minimumStock: product.minimumStock,
                compact: true,
              ),
            if (onDecrement != null)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: onDecrement,
                color: AppTheme.errorColor,
              ),
            if (onIncrement != null)
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: onIncrement,
                color: AppTheme.successColor,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
