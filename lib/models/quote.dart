// lib/models/quote.dart

class Quote {
  int? id;
  String customerName;
  String customerPhone;
  String address;
  DateTime quoteDate;
  double totalAmount;
  double prepayment;
  String status;
  String notes;

  Quote({
    this.id,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.quoteDate,
    required this.totalAmount,
    this.prepayment = 0.0,
    this.status = 'Черновик',
    this.notes = '',
  });

  // Конвертация в Map для SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'address': address,
      'quoteDate': quoteDate.toIso8601String(),
      'totalAmount': totalAmount,
      'prepayment': prepayment,
      'status': status,
      'notes': notes,
    };
  }

  // Создание объекта из Map (из SQLite)
  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'],
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      address: map['address'],
      quoteDate: DateTime.parse(map['quoteDate']),
      totalAmount: map['totalAmount'],
      prepayment: map['prepayment'],
      status: map['status'],
      notes: map['notes'],
    );
  }

  // Копия объекта с изменениями
  Quote copyWith({
    int? id,
    String? customerName,
    String? customerPhone,
    String? address,
    DateTime? quoteDate,
    double? totalAmount,
    double? prepayment,
    String? status,
    String? notes,
  }) {
    return Quote(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      address: address ?? this.address,
      quoteDate: quoteDate ?? this.quoteDate,
      totalAmount: totalAmount ?? this.totalAmount,
      prepayment: prepayment ?? this.prepayment,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
