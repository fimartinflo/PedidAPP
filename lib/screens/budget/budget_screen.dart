import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../utils/app_theme.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

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
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600]),
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
