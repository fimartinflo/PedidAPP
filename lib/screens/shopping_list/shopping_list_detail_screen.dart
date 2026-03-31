import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/shopping_list_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/budget_provider.dart';
import '../../models/shopping_list.dart';
import '../../utils/app_theme.dart';
import '../../widgets/empty_state.dart';

class ShoppingListDetailScreen extends StatelessWidget {
  final String listId;

  const ShoppingListDetailScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShoppingListProvider>(
      builder: (context, provider, child) {
        final list = provider.shoppingLists.firstWhere(
          (l) => l.id == listId,
          orElse: () => provider.shoppingLists.first,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(list.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Compartir lista',
                onPressed: () => _shareList(list, context),
              ),
              if (list.status == ShoppingListStatus.active)
                IconButton(
                  icon: const Icon(Icons.check_circle),
                  tooltip: 'Completar lista',
                  onPressed: () => _completeList(context, list, provider),
                ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Agregar producto',
                onPressed: () =>
                    _showAddItemDialog(context, list.id, provider),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildSummary(list),
              Expanded(child: _buildItemsList(context, list, provider)),
            ],
          ),
        );
      },
    );
  }

  void _shareList(ShoppingList list, BuildContext context) {
    final inventory = context.read<InventoryProvider>();
    final buffer = StringBuffer();
    buffer.writeln('Lista: ${list.name}');
    buffer.writeln('${'─' * 30}');

    // Group items by category
    final groupedItems = <String, List<dynamic>>{};
    for (final item in list.items) {
      final category = inventory.categories.firstWhere(
        (c) => c.id == item.categoryId,
        orElse: () => inventory.categories.last,
      );
      groupedItems.putIfAbsent(category.name, () => []).add(item);
    }

    for (final entry in groupedItems.entries) {
      buffer.writeln('\n${entry.key}:');
      for (final item in entry.value) {
        final check = item.isPurchased ? '✓' : '○';
        final price = item.estimatedPrice != null
            ? ' - \$${item.estimatedPrice.toStringAsFixed(2)}'
            : '';
        buffer.writeln(
            '  $check ${item.productName} (${item.quantity.toStringAsFixed(1)} ${item.unit})$price');
      }
    }

    buffer.writeln('\n${'─' * 30}');
    buffer.writeln(
        'Total estimado: \$${list.totalEstimated.toStringAsFixed(2)}');
    buffer.writeln(
        'Progreso: ${list.purchasedItems}/${list.totalItems} productos');
    buffer.writeln('\nEnviado desde PedidAPP');

    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  Widget _buildSummary(ShoppingList list) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withAlpha(25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '${list.purchasedItems}/${list.totalItems}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text('Productos'),
            ],
          ),
          Column(
            children: [
              Text(
                '${(list.progress * 100).toStringAsFixed(0)}%',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text('Progreso'),
            ],
          ),
          Column(
            children: [
              Text(
                '\$${list.totalEstimated.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text('Estimado'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, ShoppingList list,
      ShoppingListProvider provider) {
    if (list.items.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        message: 'Lista vacia',
        actionLabel: 'Agregar producto',
        onAction: () => _showAddItemDialog(context, list.id, provider),
      );
    }

    // Group items by category
    final groupedItems = <String, List<dynamic>>{};
    final inventory = context.read<InventoryProvider>();

    for (final item in list.items) {
      final category = inventory.categories.firstWhere(
        (c) => c.id == item.categoryId,
        orElse: () => inventory.categories.last,
      );
      groupedItems.putIfAbsent(category.name, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: groupedItems.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.key,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ...entry.value.map((item) {
              return Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: AppTheme.errorColor,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => provider.removeItemFromList(item.id),
                child: Card(
                  child: CheckboxListTile(
                    value: item.isPurchased,
                    onChanged: list.status == ShoppingListStatus.active
                        ? (_) =>
                            provider.toggleItemPurchased(list.id, item.id)
                        : null,
                    title: Text(
                      item.productName,
                      style: TextStyle(
                        decoration: item.isPurchased
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      '${item.quantity.toStringAsFixed(1)} ${item.unit}'
                      '${item.estimatedPrice != null ? ' - \$${item.estimatedPrice!.toStringAsFixed(2)}' : ''}',
                    ),
                    secondary: item.isPurchased
                        ? const Icon(Icons.check_circle,
                            color: AppTheme.successColor)
                        : const Icon(Icons.circle_outlined),
                  ),
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  void _showAddItemDialog(BuildContext context, String listId,
      ShoppingListProvider provider) {
    final inventory = context.read<InventoryProvider>();
    final products = inventory.products;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Agregar Producto',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text(
                            '${product.currentStock.toStringAsFixed(1)} ${product.unit}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: AppTheme.primaryColor),
                          onPressed: () async {
                            await provider.addItemToList(
                              listId: listId,
                              productId: product.id,
                              productName: product.name,
                              categoryId: product.categoryId,
                              unit: product.unit,
                              estimatedPrice: product.estimatedPrice,
                            );
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _completeList(BuildContext context, ShoppingList list,
      ShoppingListProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar Lista'),
        content: Text(
          'Completar "${list.name}"?\n'
          '${list.purchasedItems} de ${list.totalItems} productos comprados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Update stock for purchased items
              final inventory = context.read<InventoryProvider>();
              for (final item in list.items.where((i) => i.isPurchased)) {
                await inventory.incrementStock(
                    item.productId, item.quantity);
              }

              // Add to budget
              final budget = context.read<BudgetProvider>();
              if (list.totalActual > 0) {
                await budget.addExpense(list.totalActual);
              }

              await provider.completeList(list.id);
              if (context.mounted) {
                Navigator.pop(context); // dialog
                Navigator.pop(context); // detail screen
              }
            },
            child: const Text('Completar'),
          ),
        ],
      ),
    );
  }
}
