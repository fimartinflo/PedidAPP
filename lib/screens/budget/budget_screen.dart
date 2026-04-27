import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/budget_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  Map<String, double> _categorySpending = {};

  @override
  void initState() {
    super.initState();
    _loadCategorySpending();
  }

  Future<void> _loadCategorySpending() async {
    final now = DateTime.now();
    final db = DatabaseService();
    final spending = await db.getSpendingByCategory(now.year, now.month);
    if (mounted) {
      setState(() => _categorySpending = spending);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presupuesto')),
      body: Consumer<BudgetProvider>(
        builder: (context, budget, child) {
          final current = budget.currentBudget;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCurrentBudget(context, current, budget),
                const SizedBox(height: 24),
                _buildMonthlyChart(budget),
                const SizedBox(height: 24),
                _buildCategoryPieChart(context),
                const SizedBox(height: 24),
                _buildHistory(budget),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentBudget(
      BuildContext context, currentBudget, BudgetProvider provider) {
    if (currentBudget == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No has definido un presupuesto para este mes',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showSetBudgetDialog(context, provider),
                icon: const Icon(Icons.add),
                label: const Text('Definir Presupuesto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '${currentBudget.monthName} ${currentBudget.year}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              width: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: (currentBudget.percentUsed / 100).clamp(0.0, 1.0),
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    color: currentBudget.isOverBudget
                        ? AppTheme.errorColor
                        : currentBudget.percentUsed >= 80
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${currentBudget.percentUsed.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const Text('usado'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BudgetStat(
                  label: 'Presupuesto',
                  value: '\$${currentBudget.budgetAmount.toStringAsFixed(2)}',
                  color: AppTheme.primaryColor,
                ),
                _BudgetStat(
                  label: 'Gastado',
                  value: '\$${currentBudget.spentAmount.toStringAsFixed(2)}',
                  color: AppTheme.warningColor,
                ),
                _BudgetStat(
                  label: 'Disponible',
                  value:
                      '\$${currentBudget.remainingAmount.toStringAsFixed(2)}',
                  color: currentBudget.isOverBudget
                      ? AppTheme.errorColor
                      : AppTheme.successColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showSetBudgetDialog(context, provider),
              icon: const Icon(Icons.edit),
              label: const Text('Modificar Presupuesto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(BudgetProvider provider) {
    final history = provider.getLastMonths(6);
    if (history.length < 2) return const SizedBox.shrink();

    final reversed = history.reversed.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparativa Mensual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _LegendDot(color: AppTheme.primaryColor, label: 'Presupuesto'),
                const SizedBox(width: 16),
                _LegendDot(color: AppTheme.accentColor, label: 'Gastado'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: reversed
                          .map((b) => b.budgetAmount > b.spentAmount
                              ? b.budgetAmount
                              : b.spentAmount)
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '\$${rod.toY.toStringAsFixed(0)}',
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= reversed.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              reversed[idx]
                                  .monthName
                                  .substring(0, 3),
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: reversed.asMap().entries.map((entry) {
                    final budget = entry.value;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: budget.budgetAmount,
                          color: AppTheme.primaryColor.withAlpha(180),
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: budget.spentAmount,
                          color: budget.isOverBudget
                              ? AppTheme.errorColor
                              : AppTheme.accentColor,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(BuildContext context) {
    if (_categorySpending.isEmpty) return const SizedBox.shrink();

    final inventory = context.read<InventoryProvider>();
    final total =
        _categorySpending.values.fold<double>(0, (sum, v) => sum + v);

    if (total <= 0) return const SizedBox.shrink();

    final sections = <PieChartSectionData>[];
    final legends = <Widget>[];

    for (final entry in _categorySpending.entries) {
      final category = inventory.categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => inventory.categories.last,
      );
      final percent = (entry.value / total * 100);
      final color = AppTheme.hexToColor(category.color);

      sections.add(PieChartSectionData(
        value: entry.value,
        title: '${percent.toStringAsFixed(0)}%',
        color: color,
        radius: 50,
        titleStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ));

      legends.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(category.name, style: const TextStyle(fontSize: 13))),
            Text('\$${entry.value.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gasto por Categoria',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: legends,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(BudgetProvider provider) {
    final history = provider.getLastMonths(6);
    if (history.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historial',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...history.skip(1).map((budget) {
          return Card(
            child: ListTile(
              title: Text('${budget.monthName} ${budget.year}'),
              subtitle: Text(
                'Presupuesto: \$${budget.budgetAmount.toStringAsFixed(2)}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${budget.spentAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: budget.isOverBudget
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                    ),
                  ),
                  Text(
                    '${budget.percentUsed.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showSetBudgetDialog(BuildContext context, BudgetProvider provider) {
    final now = DateTime.now();
    final controller = TextEditingController(
      text: provider.currentBudget?.budgetAmount.toStringAsFixed(2) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Definir Presupuesto Mensual'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Monto del presupuesto',
            prefixText: '\$ ',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                provider.setBudget(
                    year: now.year, month: now.month, amount: amount);
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

class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BudgetStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
