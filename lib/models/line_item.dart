class LineItem {
  final int? id;
  final int quoteId;
  final String name;
  final String description;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  
  // Вычисляемое поле
  double get price => pricePerUnit * quantity;
  double get total => pricePerUnit * quantity;

  LineItem({
    this.id,
    required this.quoteId,
    required this.name,
    this.description = '',
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quote_id': quoteId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'price_per_unit': pricePerUnit,
    };
  }

  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      id: map['id'],
      quoteId: map['quote_id'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      pricePerUnit: (map['price_per_unit'] ?? 0.0).toDouble(),
    );
  }

  LineItem copyWith({
    int? id,
    int? quoteId,
    String? name,
    String? description,
    double? quantity,
    String? unit,
    double? pricePerUnit,
  }) {
    return LineItem(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
    );
  }
}

