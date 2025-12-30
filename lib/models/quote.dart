import 'package:intl/intl.dart';
import 'line_item.dart';

class Quote {
  final int? id;
  final String title;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String? customerAddress;
  final String? projectNameField;  // ✅ Переименовано чтобы избежать конфликта
  final String status;
  final List<LineItem> items;
  final DateTime date;
  final String? notes;
  final double? totalAmount;

  Quote({
    this.id,
    required this.title,
    required this.customerName,
    this.customerPhone = '',
    this.customerEmail,
    this.customerAddress,
    this.projectNameField,  // ✅ Используем новое имя
    this.status = 'черновик',
    required this.items,
    required this.date,
    this.notes,
    this.totalAmount,
  });

  // ✅ ГЕТТЕРЫ ДЛЯ СОВМЕСТИМОСТИ (без конфликтов)
  String get clientName => customerName;
  String get clientPhone => customerPhone;
  String get clientEmail => customerEmail ?? '';
  String get clientAddress => customerAddress ?? '';
  String get projectName => projectNameField ?? '';
  List<LineItem> get lineItems => items;
  
  double get total => totalAmount ?? items.fold(0.0, (sum, item) => sum + item.total);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'customer_address': customerAddress,
      'project_name': projectName,  // ✅ Используем геттер
      'status': status,
      'date': date.toIso8601String(),
      'notes': notes,
      'total_amount': total,
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map, {List<LineItem>? items}) {
    return Quote(
      id: map['id'] as int?,
      title: map['title'] ?? '',
      customerName: map['customer_name'] ?? '',
      customerPhone: map['customer_phone'] ?? '',
      customerEmail: map['customer_email'],
      customerAddress: map['customer_address'],
      projectNameField: map['project_name'],  // ✅ В поле
      status: map['status'] ?? 'черновик',
      items: items ?? [],
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
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
    String? customerAddress,
    String? projectNameField,
    String? status,
    List<LineItem>? items,
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
      customerAddress: customerAddress ?? this.customerAddress,
      projectNameField: projectNameField ?? this.projectNameField,
      status: status ?? this.status,
      items: items ?? this.items,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() {
    return 'Quote(id: $id, title: $title, total: ${total.toStringAsFixed(2)}₽)';
  }
}
