import 'dart:convert';

class LineItem {
  int? id;
  int quoteId;
  String description;
  double quantity;
  double unitPrice;
  double totalPrice;

  LineItem({
    this.id,
    required this.quoteId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quote_id': quoteId,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      id: map['id'],
      quoteId: map['quote_id'],
      description: map['description'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'],
      totalPrice: map['total_price'],
    );
  }

  String toJson() => json.encode(toMap());

  factory LineItem.fromJson(String source) => LineItem.fromMap(json.decode(source));

  LineItem copyWith({
    int? id,
    int? quoteId,
    String? description,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return LineItem(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}
