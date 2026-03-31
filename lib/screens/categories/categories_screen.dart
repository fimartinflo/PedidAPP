import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/app_theme.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      body: Consumer<InventoryProvider>(
        builder: (context, inventory, child) {
          final categories = inventory.categories;

          if (categories.isEmpty) {
            return const Center(child: Text('No hay categorias'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final productCount =
                  inventory.getProductsByCategory(cat.id).length;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        AppTheme.hexToColor(cat.color).withAlpha(40),
                    child: Icon(
                      AppTheme.getIconByName(cat.icon),
                      color: AppTheme.hexToColor(cat.color),
                    ),
                  ),
                  title: Text(cat.name),
                  subtitle: Text('$productCount producto${productCount != 1 ? 's' : ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () =>
                            _showEditDialog(context, inventory, cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 20, color: AppTheme.errorColor),
                        onPressed: () {
                          if (productCount > 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'No puedes eliminar una categoria con productos'),
                              ),
                            );
                            return;
                          }
                          inventory.deleteCategory(cat.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Categoria'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nombre'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                context
                    .read<InventoryProvider>()
                    .addCategory(name: nameController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, InventoryProvider inventory, cat) {
    final nameController = TextEditingController(text: cat.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Categoria'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nombre'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                inventory.updateCategory(
                    cat.copyWith(name: nameController.text.trim()));
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
