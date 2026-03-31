import 'shopping_item.dart';

enum ShoppingListStatus { active, completed, cancelled }

class ShoppingList {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? completedAt;
  final ShoppingListStatus status;
  final double? budgetLimit;
  final List<ShoppingItem> items;

  ShoppingList({
    required this.id,
    required this.name,
    DateTime? createdAt,
    this.completedAt,
    this.status = ShoppingListStatus.active,
    this.budgetLimit,
    this.items = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  int get totalItems => items.length;
  int get purchasedItems => items.where((i) => i.isPurchased).length;
  double get progress =>
      totalItems > 0 ? purchasedItems / totalItems : 0;

  double get totalEstimated =>
      items.fold(0, (sum, item) => sum + item.totalEstimated);
  double get totalActual =>
      items.fold(0, (sum, item) => sum + item.totalActual);

  bool get isOverBudget =>
      budgetLimit != null && totalActual > budgetLimit!;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status.name,
      'budgetLimit': budgetLimit,
    };
  }

  factory ShoppingList.fromMap(Map<String, dynamic> map,
      {List<ShoppingItem> items = const []}) {
    return ShoppingList(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      status: ShoppingListStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ShoppingListStatus.active,
      ),
      budgetLimit: (map['budgetLimit'] as num?)?.toDouble(),
      items: items,
    );
  }

  ShoppingList copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? completedAt,
    ShoppingListStatus? status,
    double? budgetLimit,
    List<ShoppingItem>? items,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      items: items ?? this.items,
    );
  }
}
