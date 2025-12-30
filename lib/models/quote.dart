class Quote {
  final int? id;
  final String title;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final List<LineItem> lineItems;
  final DateTime date;  // ✅ ДОБАВЛЕНО для pdf_service.dart:89
  final String? notes;
  final double? totalAmount;

  Quote({
    this.id,
    required this.title,
    required this.customerName,
    this.customerPhone = '',
    this.customerEmail = '',
    required this.lineItems,
    required this.date,  // ✅ ДОБАВЛЕНО
    this.notes,
    this.totalAmount,
  });

  double get total => totalAmount ?? lineItems.fold(0.0, (sum, item) => sum + item.total);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'date': date.toIso8601String(),  // ✅ ДОБАВЛЕНО
      'notes': notes,
      'total_amount': total,
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'] as int?,
      title: map['title'] ?? '',
      customerName: map['customer_name'] ?? '',
      customerPhone: map['customer_phone'] ?? '',
      customerEmail: map['customer_email'] ?? '',
      lineItems: [], // Заполняется отдельно
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),  // ✅ ДОБАВЛЕНО
      notes: map['notes'],
      totalAmount: (map['total_amount'] ?? 0.0).toDouble(),
    );
  }

  Quote copyWith({
    int? id,
    String? title,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    List<LineItem>? lineItems,
    DateTime? date,
    String? notes,
    double? totalAmount,
  }) {
    return Quote(
      id: id ?? this.id,
      title: title ?? this.title,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      lineItems: lineItems ?? this.lineItems,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  // ✅ ДОПОЛНИТЕЛЬНЫЕ МЕТОДЫ
  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() {
    return 'Quote(id: $id, title: $title, total: ${total.toStringAsFixed(2)}₽, date: $date)';
  }
}
