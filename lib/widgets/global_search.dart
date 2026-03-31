import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../models/product.dart';
import '../models/shopping_list.dart';
import '../utils/app_theme.dart';
import '../screens/inventory/product_detail_screen.dart';
import '../screens/shopping_list/shopping_list_detail_screen.dart';
import 'category_avatar.dart';

class GlobalSearchDelegate extends SearchDelegate<String> {
  GlobalSearchDelegate() : super(searchFieldLabel: 'Buscar en PedidAPP...');

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Busca productos o listas de compras',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final inventory = context.read<InventoryProvider>();
    final shopping = context.read<ShoppingListProvider>();
    final lowerQuery = query.toLowerCase();

    final matchedProducts = inventory.products
        .where((p) => p.name.toLowerCase().contains(lowerQuery))
        .toList();

    final matchedLists = shopping.shoppingLists
        .where((l) => l.name.toLowerCase().contains(lowerQuery))
        .toList();

    if (matchedProducts.isEmpty && matchedLists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Sin resultados para "$query"',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (matchedProducts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Productos (${matchedProducts.length})',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...matchedProducts.map((product) =>
              _buildProductResult(context, product, inventory)),
        ],
        if (matchedLists.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Listas (${matchedLists.length})',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...matchedLists
              .map((list) => _buildListResult(context, list)),
        ],
      ],
    );
  }

  Widget _buildProductResult(
      BuildContext context, Product product, InventoryProvider inventory) {
    final category = inventory.categories.firstWhere(
      (c) => c.id == product.categoryId,
      orElse: () => inventory.categories.last,
    );

    return Card(
      child: ListTile(
        leading: CategoryAvatar(category: category),
        title: Text(product.name),
        subtitle: Text(
            '${product.currentStock.toStringAsFixed(1)} ${product.unit}'),
        trailing: product.isLowStock
            ? Icon(Icons.warning_amber,
                color: product.isOutOfStock
                    ? AppTheme.errorColor
                    : AppTheme.warningColor)
            : null,
        onTap: () {
          close(context, '');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailScreen(productId: product.id),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListResult(BuildContext context, ShoppingList list) {
    final isActive = list.status == ShoppingListStatus.active;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isActive ? AppTheme.accentColor : AppTheme.successColor,
          child: Icon(
            isActive ? Icons.shopping_cart : Icons.check,
            color: Colors.white,
          ),
        ),
        title: Text(list.name),
        subtitle: Text(
            '${list.purchasedItems}/${list.totalItems} productos'),
        trailing: Text(
          isActive ? 'Activa' : 'Completada',
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppTheme.accentColor : AppTheme.successColor,
          ),
        ),
        onTap: () {
          close(context, '');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ShoppingListDetailScreen(listId: list.id),
            ),
          );
        },
      ),
    );
  }
}
