import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/shopping_list_provider.dart';
import '../../models/shopping_list.dart';
import '../../utils/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../shopping_list/shopping_list_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'all'; // all, thisMonth, lastMonth
  final _dateFormat = DateFormat('dd MMM yyyy', 'es');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Compras'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'all', child: Text('Todas')),
              PopupMenuItem(value: 'thisMonth', child: Text('Este mes')),
              PopupMenuItem(value: 'lastMonth', child: Text('Mes pasado')),
            ],
          ),
        ],
      ),
      body: Consumer<ShoppingListProvider>(
        builder: (context, provider, child) {
          var lists = provider.completedLists;

          lists = _applyFilter(lists);

          if (lists.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              message: 'No hay compras completadas',
            );
          }

          final totalSpent =
              lists.fold<double>(0, (sum, l) => sum + l.totalActual);
          final totalItems =
              lists.fold<int>(0, (sum, l) => sum + l.purchasedItems);

          return Column(
            children: [
              _buildSummaryBar(lists.length, totalSpent, totalItems),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: lists.length,
                  itemBuilder: (context, index) =>
                      _buildHistoryCard(context, lists[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<ShoppingList> _applyFilter(List<ShoppingList> lists) {
    final now = DateTime.now();
    switch (_filter) {
      case 'thisMonth':
        return lists
            .where((l) =>
                l.completedAt != null &&
                l.completedAt!.year == now.year &&
                l.completedAt!.month == now.month)
            .toList();
      case 'lastMonth':
        final lastMonth = DateTime(now.year, now.month - 1);
        return lists
            .where((l) =>
                l.completedAt != null &&
                l.completedAt!.year == lastMonth.year &&
                l.completedAt!.month == lastMonth.month)
            .toList();
      default:
        return lists;
    }
  }

  Widget _buildSummaryBar(int listCount, double totalSpent, int totalItems) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withAlpha(25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryStat(
            label: 'Compras',
            value: '$listCount',
            icon: Icons.shopping_bag,
          ),
          _SummaryStat(
            label: 'Productos',
            value: '$totalItems',
            icon: Icons.inventory_2,
          ),
          _SummaryStat(
            label: 'Total',
            value: '\$${totalSpent.toStringAsFixed(2)}',
            icon: Icons.attach_money,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, ShoppingList list) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShoppingListDetailScreen(listId: list.id),
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
                  const Icon(Icons.check_circle,
                      color: AppTheme.successColor, size: 20),
                ],
              ),
              const SizedBox(height: 4),
              if (list.completedAt != null)
                Text(
                  'Completada: ${_dateFormat.format(list.completedAt!)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.shopping_cart,
                    label: '${list.purchasedItems} productos',
                  ),
                  const SizedBox(width: 12),
                  if (list.totalActual > 0)
                    _InfoChip(
                      icon: Icons.attach_money,
                      label: '\$${list.totalActual.toStringAsFixed(2)}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }
}
