class LineItem {
  int? id;
  int quoteId;
  String name;
  String? description;
  double price;
  int quantity;
  String unit;

  LineItem({
    this.id,
    required this.quoteId,
    required this.name,
    this.description,
    required this.price,
    this.quantity = 1,
    this.unit = 'шт.',
  });

  // Геттер для обратной совместимости
  double get unitPrice => price;
  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quoteId': quoteId,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      id: map['id'],
      quoteId: map['quoteId'],
      name: map['name'],
      description: map['description'],
      price: map['price'] ?? map['unitPrice'] ?? 0.0,
      quantity: map['quantity'] ?? 1,
      unit: map['unit'] ?? 'шт.',
    );
  }

  LineItem copyWith({
    int? id,
    int? quoteId,
    String? name,
    String? description,
    double? price,
    int? quantity,
    String? unit,
  }) {
    return LineItem(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }
}
