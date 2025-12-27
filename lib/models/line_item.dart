class LineItem {
  int id;
  String name;
  double quantity;
  String unit;
  double price;
  String description; // Изменили note на description

  LineItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'description': description,
    };
  }

  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      id: map['id'] as int,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      price: (map['price'] as num).toDouble(),
      description: map['description'] as String,
    );
  }

  LineItem copyWith({
    int? id,
    String? name,
    double? quantity,
    String? unit,
    double? price,
    String? description,
  }) {
    return LineItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      description: description ?? this.description,
    );
  }
}
