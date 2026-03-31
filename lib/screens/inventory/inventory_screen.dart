import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';
  String? _selectedCategoryId;
  String _stockFilter = 'all'; // all, low, out

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Despensa'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _stockFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Todos')),
              const PopupMenuItem(value: 'low', child: Text('Stock Bajo')),
              const PopupMenuItem(value: 'out', child: Text('Agotados')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () =>
                            setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value),
            ),
          ),
          _buildCategoryFilter(),
          Expanded(child: _buildProductList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const AddProductScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, child) {
        return SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('Todos'),
                  selected: _selectedCategoryId == null,
                  onSelected: (_) =>
                      setState(() => _selectedCategoryId = null),
                ),
              ),
              ...inventory.categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      AppTheme.getIconByName(cat.icon),
                      size: 18,
                      color: AppTheme.hexToColor(cat.color),
                    ),
                    label: Text(cat.name),
                    selected: _selectedCategoryId == cat.id,
                    onSelected: (_) => setState(
                        () => _selectedCategoryId = cat.id),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductList() {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, child) {
        var products = inventory.products;

        if (_searchQuery.isNotEmpty) {
          products = inventory.searchProducts(_searchQuery);
        }

        if (_selectedCategoryId != null) {
          products = products
              .where((p) => p.categoryId == _selectedCategoryId)
              .toList();
        }

        if (_stockFilter == 'low') {
          products = products.where((p) => p.isLowStock).toList();
        } else if (_stockFilter == 'out') {
          products = products.where((p) => p.isOutOfStock).toList();
        }

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No se encontraron productos'
                      : 'Tu despensa esta vacia',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                if (_searchQuery.isEmpty)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const AddProductScreen()),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Producto'),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final category = inventory.categories.firstWhere(
              (c) => c.id == product.categoryId,
              orElse: () => inventory.categories.last,
            );

            final stockStatus = AppConstants.getStockStatus(
                product.currentStock, product.minimumStock);

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      AppTheme.hexToColor(category.color).withAlpha(40),
                  child: Icon(
                    AppTheme.getIconByName(category.icon),
                    color: AppTheme.hexToColor(category.color),
                  ),
                ),
                title: Text(product.name),
                subtitle: Text(
                  '${product.currentStock.toStringAsFixed(1)} ${product.unit} '
                  '(min: ${product.minimumStock.toStringAsFixed(1)})',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (stockStatus != 'ok')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: stockStatus == 'out'
                              ? AppTheme.errorColor
                              : AppTheme.warningColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppConstants.stockStatusLabels[stockStatus]!,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () =>
                          inventory.decrementStock(product.id, 1),
                      color: AppTheme.errorColor,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () =>
                          inventory.incrementStock(product.id, 1),
                      color: AppTheme.successColor,
                    ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProductDetailScreen(productId: product.id),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
