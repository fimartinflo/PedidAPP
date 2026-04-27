import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../providers/budget_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/category_avatar.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/stock_indicator.dart';
import '../../widgets/global_search.dart';
import '../../services/notification_service.dart';
import '../../services/widget_service.dart';
import '../inventory/inventory_screen.dart';
import '../shopping_list/shopping_lists_screen.dart';
import '../budget/budget_screen.dart';
import '../settings/settings_screen.dart';
import '../history/history_screen.dart';
import '../consumption/consumption_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _DashboardView(),
    InventoryScreen(),
    ShoppingListsScreen(),
    BudgetScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final inventory = context.read<InventoryProvider>();
    final shopping = context.read<ShoppingListProvider>();
    final budget = context.read<BudgetProvider>();

    await Future.wait([
      inventory.loadData(),
      shopping.loadShoppingLists(),
      budget.loadBudgets(),
    ]);

    // Notify about expiring products
    await NotificationService().checkAndNotifyExpiring(inventory.products);

    // Update Android home widget
    await WidgetService.updateWidget(
      totalProducts: inventory.totalProducts,
      lowStockCount: inventory.lowStockCount,
      expiringCount:
          inventory.expiringSoonProducts.length + inventory.expiredProducts.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Despensa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Compras',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Presupuesto',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PedidAPP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar',
            onPressed: () => showSearch(
              context: context,
              delegate: GlobalSearchDelegate(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.trending_down),
            tooltip: 'Prediccion de consumo',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ConsumptionScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de compras',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<InventoryProvider>().loadData();
          await context.read<ShoppingListProvider>().loadShoppingLists();
          await context.read<BudgetProvider>().loadBudgets();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 16),
              _buildStatsCards(context),
              const SizedBox(height: 24),
              _buildExpiringSection(context),
              _buildLowStockSection(context),
              const SizedBox(height: 24),
              _buildSmartSuggestionsSection(context),
              _buildActiveListsSection(context),
              const SizedBox(height: 24),
              _buildBudgetSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Buenos dias';
    } else if (hour < 18) {
      greeting = 'Buenas tardes';
    } else {
      greeting = 'Buenas noches';
    }

    return Text(
      greeting,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, child) {
        return Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.inventory_2,
                label: 'Productos',
                value: '${inventory.totalProducts}',
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.warning_amber,
                label: 'Stock Bajo',
                value: '${inventory.lowStockCount}',
                color: inventory.lowStockCount > 0
                    ? AppTheme.warningColor
                    : AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Consumer<ShoppingListProvider>(
                builder: (context, shopping, child) {
                  return StatCard(
                    icon: Icons.shopping_cart,
                    label: 'Listas',
                    value: '${shopping.activeLists.length}',
                    color: AppTheme.accentColor,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpiringSection(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, child) {
        final expiring = inventory.expiringSoonProducts;
        final expired = inventory.expiredProducts;
        final all = [...expired, ...expiring];
        if (all.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Por Vencer'),
            const SizedBox(height: 8),
            ...all.take(5).map((product) {
              final days = product.daysUntilExpiry ?? 0;
              final isExpired = days < 0;
              final color = isExpired || days <= 3
                  ? AppTheme.errorColor
                  : days <= 7
                      ? AppTheme.warningColor
                      : AppTheme.successColor;
              final label = isExpired
                  ? 'Vencido'
                  : days == 0
                      ? 'Hoy'
                      : '$days día${days == 1 ? '' : 's'}';

              return Card(
                color: color.withAlpha(15),
                child: ListTile(
                  leading: Icon(
                    isExpired ? Icons.warning : Icons.event,
                    color: color,
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    'Stock: ${product.currentStock.toStringAsFixed(1)} ${product.unit}',
                  ),
                  trailing: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildSmartSuggestionsSection(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, child) {
        return FutureBuilder<List<SmartSuggestion>>(
          future: inventory.getSmartSuggestions(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final suggestions = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Sugerencias Inteligentes',
                  actionLabel: 'Crear lista',
                  actionIcon: Icons.auto_awesome,
                  onAction: () async {
                    final shopping = context.read<ShoppingListProvider>();
                    final products =
                        suggestions.map((s) => s.product).toList();
                    await shopping.generateFromLowStock(
                      products,
                      name: 'Sugerencias del ${DateTime.now().day}/${DateTime.now().month}',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Lista creada con sugerencias inteligentes'),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                ...suggestions.take(3).map((s) {
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.accentColor,
                        child: Icon(Icons.auto_awesome,
                            color: Colors.white, size: 18),
                      ),
                      title: Text(s.product.name),
                      subtitle: Text(s.reason),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLowStockSection(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, child) {
        final lowStock = inventory.lowStockProducts;
        if (lowStock.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.successColor),
                  const SizedBox(width: 12),
                  const Text('Tu despensa esta completa'),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Stock Bajo',
              actionLabel: 'Crear lista',
              actionIcon: Icons.add_shopping_cart,
              onAction: () async {
                final shopping = context.read<ShoppingListProvider>();
                await shopping.generateFromLowStock(lowStock);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lista de compras generada'),
                    ),
                  );
                }
              },
            ),
            ...lowStock.take(5).map((product) {
              final category = inventory.categories.firstWhere(
                (c) => c.id == product.categoryId,
                orElse: () => inventory.categories.last,
              );
              return Card(
                child: ListTile(
                  leading: CategoryAvatar(category: category),
                  title: Text(product.name),
                  subtitle: Text(
                    'Stock: ${product.currentStock.toStringAsFixed(1)} ${product.unit}',
                  ),
                  trailing: StockIndicator(
                    currentStock: product.currentStock,
                    minimumStock: product.minimumStock,
                    compact: true,
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildActiveListsSection(BuildContext context) {
    return Consumer<ShoppingListProvider>(
      builder: (context, shopping, child) {
        final activeLists = shopping.activeLists;
        if (activeLists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Listas Activas'),
            const SizedBox(height: 8),
            ...activeLists.take(3).map((list) {
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.accentColor,
                    child: Icon(Icons.shopping_cart, color: Colors.white),
                  ),
                  title: Text(list.name),
                  subtitle: LinearProgressIndicator(
                    value: list.progress,
                    backgroundColor: Colors.grey[200],
                  ),
                  trailing: Text(
                    '${list.purchasedItems}/${list.totalItems}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildBudgetSection(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, budget, child) {
        final current = budget.currentBudget;
        if (current == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Presupuesto del Mes'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gastado: \$${current.spentAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Limite: \$${current.budgetAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (current.percentUsed / 100).clamp(0.0, 1.0),
                        minHeight: 12,
                        backgroundColor: Colors.grey[200],
                        color: current.isOverBudget
                            ? AppTheme.errorColor
                            : current.percentUsed >= 80
                                ? AppTheme.warningColor
                                : AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Disponible: \$${current.remainingAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: current.isOverBudget
                            ? AppTheme.errorColor
                            : AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
