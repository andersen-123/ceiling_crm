class Transaction {
  int? id;
  final int projectId;
  final String type;
  final String category;
  final double amount;
  final String? comment;
  final DateTime date;

  Transaction({
    this.id,
    required this.projectId,
    required this.type,
    required this.category,
    required this.amount,
    this.comment,
    required this.date,
  });

  Transaction.gasoline({
    required int projectId,
    required double amount,
    String? comment,
    DateTime? date,
  }) : this(
          projectId: projectId,
          type: 'expense',
          category: 'Бензин',
          amount: amount,
          comment: comment,
          date: date ?? DateTime.now(),
        );

  Transaction.materials({
    required int projectId,
    required double amount,
    required String materialName,
    String? comment,
    DateTime? date,
  }) : this(
          projectId: projectId,
          type: 'expense',
          category: materialName,
          amount: amount,
          comment: comment,
          date: date ?? DateTime.now(),
        );

  Transaction.income({
    required int projectId,
    required double amount,
    required String source,
    String? comment,
    DateTime? date,
  }) : this(
          projectId: projectId,
          type: 'income',
          category: source,
          amount: amount,
          comment: comment,
          date: date ?? DateTime.now(),
        );

  Transaction.prepayment({
    required int projectId,
    required double amount,
    String? comment,
    DateTime? date,
  }) : this(
          projectId: projectId,
          type: 'income',
          category: 'Аванс',
          amount: amount,
          comment: comment,
          date: date ?? DateTime.now(),
        );

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'type': type,
      'category': category,
      'amount': amount,
      'comment': comment,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      projectId: map['project_id'],
      type: map['type'],
      category: map['category'],
      amount: map['amount'] is int
          ? (map['amount'] as int).toDouble()
          : map['amount'],
      comment: map['comment'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }

  Transaction copyWith({
    int? id,
    int? projectId,
    String? type,
    String? category,
    double? amount,
    String? comment,
    DateTime? date,
  }) {
    return Transaction(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      comment: comment ?? this.comment,
      date: date ?? this.date,
    );
  }
}
