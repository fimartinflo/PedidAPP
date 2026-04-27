import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/price_record.dart';
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
  DateTime? _expiryDate;

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
    _expiryDate = product.expiryDate;
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
          _buildConsumptionPrediction(product, inventory),
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
          if (product.expiryDate != null) _buildExpiryCard(product),
          const SizedBox(height: 16),
          _buildPriceHistory(product, inventory),
          const SizedBox(height: 16),
          _buildPriceComparison(product, inventory),
        ],
      ),
    );
  }

  Widget _buildExpiryCard(product) {
    final days = product.daysUntilExpiry as int;
    final dateText = DateFormat('dd/MM/yyyy').format(product.expiryDate);
    Color color;
    String label;
    IconData icon;

    if (days < 0) {
      color = AppTheme.errorColor;
      label = 'Vencido hace ${-days} día${days == -1 ? '' : 's'}';
      icon = Icons.warning;
    } else if (days <= 3) {
      color = AppTheme.errorColor;
      label = days == 0 ? 'Vence hoy' : 'Vence en $days día${days == 1 ? '' : 's'}';
      icon = Icons.warning_amber;
    } else if (days <= 7) {
      color = AppTheme.warningColor;
      label = 'Vence en $days días';
      icon = Icons.event;
    } else {
      color = AppTheme.successColor;
      label = 'Vence en $days días';
      icon = Icons.event;
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: const Text('Vencimiento'),
        subtitle: Text(dateText),
        trailing: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPriceHistory(product, InventoryProvider inventory) {
    return FutureBuilder<List<PriceRecord>>(
      future: inventory.getPriceHistory(product.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.trending_flat, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sin historial de precios. Se registra al completar compras.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final records = snapshot.data!;
        final dateFormat = DateFormat('dd/MM/yy');
        final latest = records.first.price;
        final oldest = records.length > 1 ? records.last.price : latest;
        final diff = latest - oldest;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Historial de Precios',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    if (records.length > 1)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            diff > 0
                                ? Icons.trending_up
                                : diff < 0
                                    ? Icons.trending_down
                                    : Icons.trending_flat,
                            size: 18,
                            color: diff > 0
                                ? AppTheme.errorColor
                                : diff < 0
                                    ? AppTheme.successColor
                                    : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            diff > 0
                                ? '+\$${diff.toStringAsFixed(2)}'
                                : diff < 0
                                    ? '-\$${diff.abs().toStringAsFixed(2)}'
                                    : 'Estable',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: diff > 0
                                  ? AppTheme.errorColor
                                  : diff < 0
                                      ? AppTheme.successColor
                                      : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ...records.take(5).map((record) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          dateFormat.format(record.date),
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '\$${record.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(width: 8),
                        if (record.store != null && record.store!.isNotEmpty)
                          Expanded(
                            child: Text(
                              record.store!,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        else
                          const Spacer(),
                        if (record.source != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _sourceLabel(record.source!),
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.primaryColor),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                if (records.length > 5) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${records.length - 5} registros mas...',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceComparison(product, InventoryProvider inventory) {
    return FutureBuilder<Map<String, double>>(
      future: inventory.getPriceComparisonByStore(product.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final byStore = snapshot.data!;
        if (byStore.length < 2) {
          // Only one store, no comparison
          return const SizedBox.shrink();
        }

        final entries = byStore.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        final cheapest = entries.first;
        final mostExpensive = entries.last;
        final savings = mostExpensive.value - cheapest.value;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.compare_arrows,
                        color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Comparador de Precios',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                ...entries.map((e) {
                  final isCheapest = e.key == cheapest.key;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 18,
                          color: isCheapest
                              ? AppTheme.successColor
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.key,
                            style: TextStyle(
                              fontWeight: isCheapest
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          '\$${e.value.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isCheapest
                                ? AppTheme.successColor
                                : null,
                          ),
                        ),
                        if (isCheapest) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.star,
                              size: 16, color: AppTheme.successColor),
                        ],
                      ],
                    ),
                  );
                }),
                if (savings > 0) ...[
                  const Divider(height: 24),
                  Text(
                    'Ahorro de hasta \$${savings.toStringAsFixed(2)} comprando en ${cheapest.key}',
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'shopping_list':
        return 'Compra';
      case 'receipt':
        return 'Boleta';
      case 'manual':
        return 'Manual';
      default:
        return source;
    }
  }

  Widget _buildConsumptionPrediction(product, InventoryProvider inventory) {
    return FutureBuilder<List<double?>>(
      future: Future.wait([
        inventory.getEstimatedDaysUntilEmpty(product.id),
        inventory.getAverageDailyConsumption(product.id),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final daysUntilEmpty = snapshot.data![0];
        final avgDaily = snapshot.data![1] ?? 0.0;

        if (avgDaily <= 0) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.trending_down, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Registra consumo para ver predicciones',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prediccion de Consumo',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PredictionStat(
                        icon: Icons.speed,
                        label: 'Consumo diario',
                        value:
                            '${avgDaily.toStringAsFixed(2)} ${product.unit}/dia',
                      ),
                    ),
                    if (daysUntilEmpty != null)
                      Expanded(
                        child: _PredictionStat(
                          icon: Icons.event,
                          label: 'Se agota en',
                          value: daysUntilEmpty < 1
                              ? 'Hoy'
                              : '${daysUntilEmpty.toStringAsFixed(0)} dias',
                          isWarning: daysUntilEmpty <= 7,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickExpiryDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha de vencimiento',
                  prefixIcon: const Icon(Icons.event),
                  suffixIcon: _expiryDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () =>
                              setState(() => _expiryDate = null),
                        )
                      : null,
                ),
                child: Text(
                  _expiryDate != null
                      ? DateFormat('dd/MM/yyyy').format(_expiryDate!)
                      : 'Sin fecha',
                  style: TextStyle(
                    color: _expiryDate != null
                        ? null
                        : Theme.of(context).hintColor,
                  ),
                ),
              ),
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
      expiryDate: _expiryDate,
      clearExpiryDate: _expiryDate == null,
    );

    await inventory.updateProduct(updated);

    if (mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto actualizado')),
      );
    }
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
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

class _PredictionStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;

  const _PredictionStat({
    required this.icon,
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 20,
            color: isWarning ? AppTheme.warningColor : AppTheme.primaryColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isWarning ? AppTheme.warningColor : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
