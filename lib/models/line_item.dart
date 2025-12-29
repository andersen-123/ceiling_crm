class LineItem {
  int? id;
  int quoteId;
  String description;
  double quantity;
  double price;
  String unit;
  String? name;

  LineItem({
    this.id,
    required this.quoteId,
    required this.description,
    required this.quantity,
    required this.price,
    required this.unit,
    this.name,
  });

  double get totalPrice => quantity * price;

  // Метод для создания копии с измененными полями
  LineItem copyWith({
    int? id,
    int? quoteId,
    String? description,
    double? quantity,
    double? price,
    String? unit,
    String? name,
  }) {
    return LineItem(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'quote_id': quoteId,
      'description': description,
      'quantity': quantity,
      'price': price,
      'unit': unit,
      'name': name,
    };
  }

  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      id: map['id'],
      quoteId: map['quote_id'],
      description: map['description'] ?? '',
      quantity: map['quantity']?.toDouble() ?? 0.0,
      price: map['price']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'шт',
      name: map['name'],
    );
  }

  @override
  String toString() {
    return 'LineItem(id: $id, desc: $description, qty: $quantity, price: $price)';
  }
}
