class LineItem {
  final int? id;
  final int quoteId;
  final String name;
  final String description;
  final double quantity;
  final String unit;
  final double price;
  final double pricePerUnit;

  LineItem({
    this.id,
    required this.quoteId,
    required this.name,
    this.description = '',
    required this.quantity,
    required this.unit,
    double? price,
    double? pricePerUnit,
  })  : price = price ?? (pricePerUnit ?? 0) * quantity,
        pricePerUnit = pricePerUnit ?? (price ?? 0) / (quantity == 0 ? 1 : quantity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quote_id': quoteId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'price': price,
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
      price: (map['price'] ?? 0.0).toDouble(),
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
    double? price,
    double? pricePerUnit,
  }) {
    return LineItem(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
    );
  }
}
