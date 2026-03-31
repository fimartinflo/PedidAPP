import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  String? _selectedCategoryId;
  String _selectedUnit = 'unidad';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _stockController = TextEditingController();
    _minStockController = TextEditingController();
    _priceController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateFields() {
    final inventory = context.read<InventoryProvider>();
    final product =
        inventory.products.firstWhere((p) => p.id == widget.productId);

    _nameController.text = product.name;
    _stockController.text = product.currentStock.toString();
    _minStockController.text = product.minimumStock.toString();
    _priceController.text = product.estimatedPrice?.toString() ?? '';
    _notesController.text = product.notes ?? '';
    _selectedCategoryId = product.categoryId;
    _selectedUnit = product.unit;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, child) {
        final product = inventory.products.firstWhere(
          (p) => p.id == widget.productId,
          orElse: () => inventory.products.first,
        );

        final category = inventory.categories.firstWhere(
          (c) => c.id == product.categoryId,
          orElse: () => inventory.categories.last,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Editar Producto' : product.name),
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _populateFields();
                    setState(() => _isEditing = true);
                  },
                ),
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDelete(context, inventory),
                ),
            ],
          ),
          body: _isEditing
              ? _buildEditForm(inventory)
              : _buildDetailView(product, category, inventory),
        );
      },
    );
  }

  Widget _buildDetailView(product, category, InventoryProvider inventory) {
    final stockStatus = AppConstants.getStockStatus(
        product.currentStock, product.minimumStock);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        AppTheme.hexToColor(category.color).withAlpha(40),
                    child: Icon(
                      AppTheme.getIconByName(category.icon),
                      size: 40,
                      color: AppTheme.hexToColor(category.color),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(category.name,
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Stock',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStockAction(
                        icon: Icons.remove,
                        color: AppTheme.errorColor,
                        onTap: () =>
                            inventory.decrementStock(product.id, 1),
                      ),
                      Column(
                        children: [
                          Text(
                            product.currentStock.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: stockStatus == 'ok'
                                  ? AppTheme.successColor
                                  : stockStatus == 'low'
                                      ? AppTheme.warningColor
                                      : AppTheme.errorColor,
                            ),
                          ),
                          Text(product.unit),
                        ],
                      ),
                      _buildStockAction(
                        icon: Icons.add,
                        color: AppTheme.successColor,
                        onTap: () =>
                            inventory.incrementStock(product.id, 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: product.minimumStock > 0
                        ? (product.currentStock / (product.minimumStock * 3))
                            .clamp(0.0, 1.0)
                        : 1.0,
                    backgroundColor: Colors.grey[200],
                    color: stockStatus == 'ok'
                        ? AppTheme.successColor
                        : stockStatus == 'low'
                            ? AppTheme.warningColor
                            : AppTheme.errorColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Stock minimo: ${product.minimumStock.toStringAsFixed(1)} ${product.unit}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (product.estimatedPrice != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Precio estimado'),
                trailing: Text(
                  '\$${product.estimatedPrice!.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (product.notes != null && product.notes!.isNotEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.note),
                title: const Text('Notas'),
                subtitle: Text(product.notes!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStockAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          shape: BoxShape.circle,
          border: Border.all(color: color),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  Widget _buildEditForm(InventoryProvider inventory) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Categoria *'),
              items: inventory.categories.map((cat) {
                return DropdownMenuItem(
                    value: cat.id, child: Text(cat.name));
              }).toList(),
              onChanged: (v) =>
                  setState(() => _selectedCategoryId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedUnit,
              decoration: const InputDecoration(labelText: 'Unidad'),
              items: AppConstants.units
                  .map((u) =>
                      DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedUnit = v);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration:
                        const InputDecoration(labelText: 'Stock actual'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _minStockController,
                    decoration:
                        const InputDecoration(labelText: 'Stock minimo'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration:
                  const InputDecoration(labelText: 'Precio estimado'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notas'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _saveChanges(inventory),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges(InventoryProvider inventory) async {
    if (!_formKey.currentState!.validate()) return;

    final product =
        inventory.products.firstWhere((p) => p.id == widget.productId);

    final updated = product.copyWith(
      name: _nameController.text.trim(),
      categoryId: _selectedCategoryId,
      unit: _selectedUnit,
      currentStock: double.tryParse(_stockController.text),
      minimumStock: double.tryParse(_minStockController.text),
      estimatedPrice: double.tryParse(_priceController.text),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    await inventory.updateProduct(updated);

    if (mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto actualizado')),
      );
    }
  }

  void _confirmDelete(BuildContext context, InventoryProvider inventory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: const Text(
            'Estas seguro de que deseas eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await inventory.deleteProduct(widget.productId);
              if (context.mounted) Navigator.pop(context);
              if (mounted) Navigator.pop(this.context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
