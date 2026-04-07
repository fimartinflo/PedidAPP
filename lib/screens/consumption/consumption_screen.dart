import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/category_avatar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stock_indicator.dart';

class ConsumptionScreen extends StatefulWidget {
  const ConsumptionScreen({super.key});

  @override
  State<ConsumptionScreen> createState() => _ConsumptionScreenState();
}

class _ConsumptionScreenState extends State<ConsumptionScreen> {
  Map<String, _ConsumptionData> _consumptionData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConsumptionData();
  }

  Future<void> _loadConsumptionData() async {
    final inventory = context.read<InventoryProvider>();
    final data = <String, _ConsumptionData>{};

    await Future.wait(inventory.products.map((product) async {
      final results = await Future.wait([
        inventory.getEstimatedDaysUntilEmpty(product.id),
        inventory.getAverageDailyConsumption(product.id),
      ]);
      data[product.id] = _ConsumptionData(
        daysUntilEmpty: results[0],
        avgDaily: results[1] ?? 0.0,
      );
    }));

    if (mounted) {
      setState(() {
        _consumptionData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prediccion de Consumo')),
      body: Consumer<InventoryProvider>(
        builder: (context, inventory, child) {
          final products = inventory.products;

          if (products.isEmpty) {
            return const EmptyState(
              icon: Icons.trending_down,
              message: 'No hay productos registrados',
            );
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _loadConsumptionData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(inventory),
                const SizedBox(height: 16),
                const Text(
                  'Productos con prediccion',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...products.map((product) {
                  final data = _consumptionData[product.id];
                  return _ProductConsumptionCard(
                    product: product,
                    inventory: inventory,
                    daysUntilEmpty: data?.daysUntilEmpty,
                    avgDaily: data?.avgDaily ?? 0.0,
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(InventoryProvider inventory) {
    final total = inventory.products.length;
    final lowStock = inventory.lowStockCount;
    final outOfStock = inventory.outOfStockProducts.length;

    return Card(
      color: AppTheme.primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryItem(
              value: '$total',
              label: 'Productos',
              icon: Icons.inventory_2,
            ),
            _SummaryItem(
              value: '$lowStock',
              label: 'Stock bajo',
              icon: Icons.warning_amber,
            ),
            _SummaryItem(
              value: '$outOfStock',
              label: 'Agotados',
              icon: Icons.remove_shopping_cart,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsumptionData {
  final double? daysUntilEmpty;
  final double avgDaily;

  const _ConsumptionData({this.daysUntilEmpty, this.avgDaily = 0.0});
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _SummaryItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}

class _ProductConsumptionCard extends StatelessWidget {
  final Product product;
  final InventoryProvider inventory;
  final double? daysUntilEmpty;
  final double avgDaily;

  const _ProductConsumptionCard({
    required this.product,
    required this.inventory,
    required this.daysUntilEmpty,
    required this.avgDaily,
  });

  @override
  Widget build(BuildContext context) {
    final category = inventory.categories.firstWhere(
      (c) => c.id == product.categoryId,
      orElse: () => inventory.categories.last,
    );
    final hasConsumptionData = avgDaily > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryAvatar(category: category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${product.currentStock.toStringAsFixed(1)} ${product.unit} disponibles',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            if (hasConsumptionData) ...[
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.speed,
                      label: 'Consumo diario',
                      value:
                          '${avgDaily.toStringAsFixed(2)} ${product.unit}',
                    ),
                  ),
                  if (daysUntilEmpty != null)
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.event,
                        label: 'Se agota en',
                        value: daysUntilEmpty! < 1
                            ? 'Hoy'
                            : '${daysUntilEmpty!.toStringAsFixed(0)} dias',
                        isWarning: daysUntilEmpty! <= 7,
                      ),
                    ),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.inventory,
                      label: 'Stock minimo',
                      value:
                          '${product.minimumStock.toStringAsFixed(1)} ${product.unit}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StockIndicator(
                currentStock: product.currentStock,
                minimumStock: product.minimumStock,
                showLabel: false,
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Sin datos de consumo aun. Registra uso para ver predicciones.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    String label;
    Color color;

    if (product.isOutOfStock) {
      label = 'Agotado';
      color = AppTheme.errorColor;
    } else if (daysUntilEmpty != null && daysUntilEmpty! <= 3) {
      label = 'Critico';
      color = AppTheme.errorColor;
    } else if (product.isLowStock) {
      label = 'Bajo';
      color = AppTheme.warningColor;
    } else if (daysUntilEmpty != null && daysUntilEmpty! <= 7) {
      label = 'Pronto';
      color = AppTheme.warningColor;
    } else {
      label = 'OK';
      color = AppTheme.successColor;
    }

    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? AppTheme.warningColor : AppTheme.primaryColor;

    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isWarning ? AppTheme.warningColor : null,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
