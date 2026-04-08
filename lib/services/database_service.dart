import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/shopping_item.dart';
import '../models/shopping_list.dart';
import '../models/budget.dart';
import '../models/consumption_log.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Constructor for testing subclasses
  @protected
  DatabaseService.forTesting();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pedidapp.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT DEFAULT 'category',
        color TEXT DEFAULT '#4CAF50',
        sortOrder INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        unit TEXT DEFAULT 'unidad',
        currentStock REAL DEFAULT 0,
        minimumStock REAL DEFAULT 1,
        estimatedPrice REAL,
        notes TEXT,
        barcode TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE shopping_lists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        status TEXT DEFAULT 'active',
        budgetLimit REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE shopping_items (
        id TEXT PRIMARY KEY,
        shoppingListId TEXT NOT NULL,
        productId TEXT NOT NULL,
        productName TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        quantity REAL DEFAULT 1,
        unit TEXT DEFAULT 'unidad',
        estimatedPrice REAL,
        isPurchased INTEGER DEFAULT 0,
        actualPrice REAL,
        notes TEXT,
        FOREIGN KEY (shoppingListId) REFERENCES shopping_lists(id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE monthly_budgets (
        id TEXT PRIMARY KEY,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        budgetAmount REAL NOT NULL,
        spentAmount REAL DEFAULT 0,
        UNIQUE(year, month)
      )
    ''');

    await db.execute('''
      CREATE TABLE consumption_logs (
        id TEXT PRIMARY KEY,
        productId TEXT NOT NULL,
        quantity REAL NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (productId) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    // Insert default categories
    for (final category in Category.defaultCategories()) {
      await db.insert('categories', category.toMap());
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS consumption_logs (
          id TEXT PRIMARY KEY,
          productId TEXT NOT NULL,
          quantity REAL NOT NULL,
          timestamp TEXT NOT NULL,
          FOREIGN KEY (productId) REFERENCES products(id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // ==================== CATEGORIES ====================

  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'sortOrder ASC');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<Category?> getCategoryById(String id) async {
    final db = await database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  Future<void> insertCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update('categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== PRODUCTS ====================

  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'name ASC');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    final db = await database;
    final maps = await db.query('products',
        where: 'categoryId = ?',
        whereArgs: [categoryId],
        orderBy: 'name ASC');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final maps = await db.rawQuery(
        'SELECT * FROM products WHERE currentStock <= minimumStock ORDER BY currentStock ASC');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<void> insertProduct(Product product) async {
    final db = await database;
    await db.insert('products', product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update('products', product.toMap(),
        where: 'id = ?', whereArgs: [product.id]);
  }

  Future<void> updateProductStock(String productId, double newStock) async {
    final db = await database;
    await db.update(
      'products',
      {'currentStock': newStock, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== SHOPPING LISTS ====================

  Future<List<ShoppingList>> getShoppingLists() async {
    final db = await database;
    final listMaps =
        await db.query('shopping_lists', orderBy: 'createdAt DESC');
    final lists = <ShoppingList>[];

    for (final map in listMaps) {
      final itemMaps = await db.query('shopping_items',
          where: 'shoppingListId = ?', whereArgs: [map['id']]);
      final items = itemMaps.map((m) => ShoppingItem.fromMap(m)).toList();
      lists.add(ShoppingList.fromMap(map, items: items));
    }
    return lists;
  }

  Future<ShoppingList?> getShoppingListById(String id) async {
    final db = await database;
    final maps =
        await db.query('shopping_lists', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;

    final itemMaps = await db.query('shopping_items',
        where: 'shoppingListId = ?', whereArgs: [id]);
    final items = itemMaps.map((m) => ShoppingItem.fromMap(m)).toList();
    return ShoppingList.fromMap(maps.first, items: items);
  }

  Future<void> insertShoppingList(ShoppingList list) async {
    final db = await database;
    await db.insert('shopping_lists', list.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateShoppingList(ShoppingList list) async {
    final db = await database;
    await db.update('shopping_lists', list.toMap(),
        where: 'id = ?', whereArgs: [list.id]);
  }

  Future<void> deleteShoppingList(String id) async {
    final db = await database;
    await db.delete('shopping_items',
        where: 'shoppingListId = ?', whereArgs: [id]);
    await db.delete('shopping_lists', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== SHOPPING ITEMS ====================

  Future<void> insertShoppingItem(ShoppingItem item) async {
    final db = await database;
    await db.insert('shopping_items', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateShoppingItem(ShoppingItem item) async {
    final db = await database;
    await db.update('shopping_items', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteShoppingItem(String id) async {
    final db = await database;
    await db.delete('shopping_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleShoppingItemPurchased(String id, bool isPurchased) async {
    final db = await database;
    await db.update('shopping_items', {'isPurchased': isPurchased ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateShoppingItemActualPrice(
      String id, double actualPrice) async {
    final db = await database;
    await db.update(
      'shopping_items',
      {'actualPrice': actualPrice},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== BUDGETS ====================

  Future<List<MonthlyBudget>> getBudgets() async {
    final db = await database;
    final maps = await db.query('monthly_budgets',
        orderBy: 'year DESC, month DESC');
    return maps.map((map) => MonthlyBudget.fromMap(map)).toList();
  }

  Future<MonthlyBudget?> getBudgetForMonth(int year, int month) async {
    final db = await database;
    final maps = await db.query('monthly_budgets',
        where: 'year = ? AND month = ?', whereArgs: [year, month]);
    if (maps.isEmpty) return null;
    return MonthlyBudget.fromMap(maps.first);
  }

  Future<void> insertOrUpdateBudget(MonthlyBudget budget) async {
    final db = await database;
    await db.insert('monthly_budgets', budget.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateBudgetSpent(String id, double spentAmount) async {
    final db = await database;
    await db.update('monthly_budgets', {'spentAmount': spentAmount},
        where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CONSUMPTION LOGS ====================

  Future<void> insertConsumptionLog(ConsumptionLog log) async {
    final db = await database;
    await db.insert('consumption_logs', log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ConsumptionLog>> getConsumptionLogs(String productId,
      {int days = 30}) async {
    final db = await database;
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final maps = await db.query(
      'consumption_logs',
      where: 'productId = ? AND timestamp >= ?',
      whereArgs: [productId, since],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => ConsumptionLog.fromMap(m)).toList();
  }

  Future<double> getAverageDailyConsumption(String productId,
      {int days = 30}) async {
    final db = await database;
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(quantity), 0) as total
      FROM consumption_logs
      WHERE productId = ? AND timestamp >= ?
    ''', [productId, since]);

    final totalConsumed = (result.first['total'] as num?)?.toDouble() ?? 0;
    return totalConsumed / days;
  }

  Future<double?> estimateDaysUntilEmpty(
      String productId, double currentStock) async {
    final avgDaily = await getAverageDailyConsumption(productId);
    if (avgDaily <= 0) return null;
    return currentStock / avgDaily;
  }

  // ==================== SPENDING BY CATEGORY ====================

  Future<Map<String, double>> getSpendingByCategory(
      int year, int month) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT si.categoryId, SUM(
        CASE WHEN si.actualPrice IS NOT NULL
          THEN si.actualPrice * si.quantity
          ELSE COALESCE(si.estimatedPrice, 0) * si.quantity
        END
      ) as total
      FROM shopping_items si
      INNER JOIN shopping_lists sl ON si.shoppingListId = sl.id
      WHERE sl.status = 'completed'
        AND sl.completedAt IS NOT NULL
        AND CAST(strftime('%Y', sl.completedAt) AS INTEGER) = ?
        AND CAST(strftime('%m', sl.completedAt) AS INTEGER) = ?
        AND si.isPurchased = 1
      GROUP BY si.categoryId
    ''', [year, month]);

    final map = <String, double>{};
    for (final row in results) {
      map[row['categoryId'] as String] =
          (row['total'] as num?)?.toDouble() ?? 0;
    }
    return map;
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getStats() async {
    final db = await database;

    final totalProducts =
        (await db.rawQuery('SELECT COUNT(*) as count FROM products')).first;
    final lowStock = (await db.rawQuery(
            'SELECT COUNT(*) as count FROM products WHERE currentStock <= minimumStock'))
        .first;
    final outOfStock = (await db.rawQuery(
            'SELECT COUNT(*) as count FROM products WHERE currentStock <= 0'))
        .first;
    final activeLists = (await db.rawQuery(
            "SELECT COUNT(*) as count FROM shopping_lists WHERE status = 'active'"))
        .first;

    return {
      'totalProducts': totalProducts['count'],
      'lowStockCount': lowStock['count'],
      'outOfStockCount': outOfStock['count'],
      'activeListsCount': activeLists['count'],
    };
  }
}
