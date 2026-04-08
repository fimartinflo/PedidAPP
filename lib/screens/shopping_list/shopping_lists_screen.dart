import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/shopping_list_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/shopping_list.dart';
import '../../utils/app_theme.dart';
import 'shopping_list_detail_screen.dart';
import 'scan_receipt_screen.dart';

class ShoppingListsScreen extends StatelessWidget {
  const ShoppingListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Listas de Compras'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Activas'),
              Tab(text: 'Completadas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ListsView(showCompleted: false),
            _ListsView(showCompleted: true),
          ],
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'scan',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScanReceiptScreen(),
                ),
              ),
              tooltip: 'Escanear boleta',
              child: const Icon(Icons.receipt_long),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'create',
              onPressed: () => _showCreateDialog(context),
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Lista de Compras'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la lista',
                hintText: 'Ej: Compras de la semana',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budgetController,
              decoration: const InputDecoration(
                labelText: 'Presupuesto (opcional)',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final inventory = context.read<InventoryProvider>();
              final shopping = context.read<ShoppingListProvider>();
              final lowStock = inventory.lowStockProducts;

              if (lowStock.isNotEmpty) {
                await shopping.generateFromLowStock(
                  lowStock,
                  name: nameController.text.trim().isEmpty
                      ? null
                      : nameController.text.trim(),
                  budgetLimit: double.tryParse(budgetController.text),
                );
              } else {
                await shopping.createShoppingList(
                  name: nameController.text.trim().isEmpty
                      ? 'Compras ${DateFormat('dd/MM').format(DateTime.now())}'
                      : nameController.text.trim(),
                  budgetLimit: double.tryParse(budgetController.text),
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}

class _ListsView extends StatelessWidget {
  final bool showCompleted;

  const _ListsView({required this.showCompleted});

  @override
  Widget build(BuildContext context) {
    return Consumer<ShoppingListProvider>(
      builder: (context, provider, child) {
        final lists =
            showCompleted ? provider.completedLists : provider.activeLists;

        if (lists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  showCompleted
                      ? Icons.check_circle_outline
                      : Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  showCompleted
                      ? 'No hay listas completadas'
                      : 'No hay listas activas',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: lists.length,
          itemBuilder: (context, index) {
            final list = lists[index];
            return _buildListCard(context, list, provider);
          },
        );
      },
    );
  }

  Widget _buildListCard(
      BuildContext context, ShoppingList list, ShoppingListProvider provider) {
    final dateFormat = DateFormat('dd MMM yyyy', 'es');

    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ShoppingListDetailScreen(listId: list.id),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      list.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        provider.deleteList(list.id);
                      } else if (value == 'complete') {
                        provider.completeList(list.id);
                      }
                    },
                    itemBuilder: (context) => [
                      if (list.status == ShoppingListStatus.active)
                        const PopupMenuItem(
                          value: 'complete',
                          child: Text('Completar'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar',
                            style: TextStyle(color: AppTheme.errorColor)),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                dateFormat.format(list.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: list.progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${list.purchasedItems}/${list.totalItems}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (list.totalEstimated > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Estimado: \$${list.totalEstimated.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
