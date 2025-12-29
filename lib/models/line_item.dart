class LineItem {
  int? id;
  int quoteId;
  String description;
  int quantity;
  double pricePerUnit;
  String? unit;
  double total;

  LineItem({
    this.id,
    required this.quoteId,
    required this.description,
    required this.quantity,
    required this.pricePerUnit,
    this.unit,
    required this.total,
  });

  LineItem copyWith({
    int? id,
    int? quoteId,
    String? description,
    int? quantity,
    double? pricePerUnit,
    String? unit,
    double? total,
  }) {
    return LineItem(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      unit: unit ?? this.unit,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quote_id': quoteId,
      'description': description,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'unit': unit,
      'total': total,
    };
  }

  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      id: map['id'],
      quoteId: map['quote_id'],
      description: map['description'],
      quantity: map['quantity'],
      pricePerUnit: map['price_per_unit'] ?? 0,
      unit: map['unit'],
      total: map['total'] ?? 0,
    );
  }
}
