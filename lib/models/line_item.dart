class LineItem {
  int? id;
  int quoteId;
  String name;
  String? description;
  double quantity;
  String unit;
  double price;
  double total;
  int sortOrder;
  DateTime createdAt;
  
  LineItem({
    this.id,
    required this.quoteId,
    required this.name,
    this.description,
    required this.quantity,
    this.unit = 'шт.',
    required this.price,
    required this.total,
    this.sortOrder = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quote_id': quoteId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'total': total,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      id: map['id'],
      quoteId: map['quote_id'],
      name: map['name'] ?? '',
      description: map['description'],
      quantity: map['quantity']?.toDouble() ?? 1.0,
      unit: map['unit'] ?? 'шт.',
      price: map['price']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
      sortOrder: map['sort_order'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  @override
  String toString() {
    return 'LineItem(id: $id, name: $name, qty: $quantity $unit, price: $price)';
  }

  LineItem copyWith({
    int? id,
    int? quoteId,
    String? name,
    String? description,
    double? quantity,
    String? unit,
    double? price,
    double? total,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return LineItem(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      total: total ?? this.total,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Вспомогательный метод для создания из шаблона
  factory LineItem.fromTemplate(Map<String, dynamic> template, int quoteId) {
    return LineItem(
      quoteId: quoteId,
      name: template['name'] ?? '',
      description: template['description'],
      quantity: template['quantity']?.toDouble() ?? 1.0,
      unit: template['unit'] ?? 'шт.',
      price: template['price']?.toDouble() ?? 0.0,
      total: (template['price']?.toDouble() ?? 0.0) * (template['quantity']?.toDouble() ?? 1.0),
      sortOrder: 0,
      createdAt: DateTime.now(),
    );
  }
}
