class MonthlyBudget {
  final String id;
  final int year;
  final int month;
  final double budgetAmount;
  final double spentAmount;

  MonthlyBudget({
    required this.id,
    required this.year,
    required this.month,
    required this.budgetAmount,
    this.spentAmount = 0,
  });

  double get remainingAmount => budgetAmount - spentAmount;
  double get percentUsed =>
      budgetAmount > 0 ? (spentAmount / budgetAmount) * 100 : 0;
  bool get isOverBudget => spentAmount > budgetAmount;

  String get monthName {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'month': month,
      'budgetAmount': budgetAmount,
      'spentAmount': spentAmount,
    };
  }

  factory MonthlyBudget.fromMap(Map<String, dynamic> map) {
    return MonthlyBudget(
      id: map['id'] as String,
      year: map['year'] as int,
      month: map['month'] as int,
      budgetAmount: (map['budgetAmount'] as num).toDouble(),
      spentAmount: (map['spentAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  MonthlyBudget copyWith({
    String? id,
    int? year,
    int? month,
    double? budgetAmount,
    double? spentAmount,
  }) {
    return MonthlyBudget(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      spentAmount: spentAmount ?? this.spentAmount,
    );
  }
}
