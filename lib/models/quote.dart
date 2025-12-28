import 'package:ceiling_crm/models/line_item.dart';

class Quote {
  int? id;
  String clientName;
  String clientPhone;
  String clientAddress;
  String notes;
  double totalAmount;
  DateTime createdAt;
  DateTime? updatedAt;
  List<LineItem> items;

  Quote({
    this.id,
    required this.clientName,
    this.clientPhone = '',
    this.clientAddress = '',
    this.notes = '',
    this.totalAmount = 0.0,
    required this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientAddress': clientAddress,
      'notes': notes,
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'],
      clientName: map['clientName'],
      clientPhone: map['clientPhone'] ?? '',
      clientAddress: map['clientAddress'] ?? '',
      notes: map['notes'] ?? '',
      totalAmount: map['totalAmount'] ?? 0.0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  void addItem(LineItem item) {
    final newItem = item.copyWith(quoteId: id ?? 0);
    items.add(newItem);
    _calculateTotal();
  }

  void addItems(List<LineItem> newItems) {
    for (var item in newItems) {
      addItem(item);
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      _calculateTotal();
    }
  }

  void updateItem(int index, LineItem newItem) {
    if (index >= 0 && index < items.length) {
      items[index] = newItem.copyWith(quoteId: id ?? 0);
      _calculateTotal();
    }
  }

  void _calculateTotal() {
    totalAmount = items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  Quote copyWith({
    int? id,
    String? clientName,
    String? clientPhone,
    String? clientAddress,
    String? notes,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LineItem>? items,
  }) {
    return Quote(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientAddress: clientAddress ?? this.clientAddress,
      notes: notes ?? this.notes,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? List.from(this.items),
    );
  }
}
