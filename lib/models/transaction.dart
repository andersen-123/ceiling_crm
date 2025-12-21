
class Transaction {
  int? id;
  final int projectId; // ID проекта/объекта
  final String type; // 'income' (доход), 'expense' (расход)
  final String category; // 'Бензин', 'Материалы', 'Аванс', 'Прочее'
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
      amount: map['amount'],
      comment: map['comment'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }
}
