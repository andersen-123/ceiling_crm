class LineItem {
  final int? id;
  final int quoteId;
  final String name;
  final String unit;
  final double price;
  final double quantity;
  final double total; // Убираем optional, вычисляем внутри

  LineItem({
    this.id,
    required this.quoteId,
    required this.name,
    required this.unit,
    required this.price,
    required this.quantity,
    double? total, // Делаем параметр необязательным
  }) : total = total ?? price * quantity; // Вычисляем если не передано

  // Фабричный конструктор из Map
  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      id: map['id'] as int?,
      quoteId: map['quote_id'] as int,
      name: map['name'] ?? '',
      unit: map['unit'] ?? 'шт.',
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      total: (map['total'] as num?)?.toDouble(),
    );
  }

  // Метод для преобразования в Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'quote_id': quoteId,
      'name': name,
      'unit': unit,
      'price': price,
      'quantity': quantity,
      'total': total ?? price * quantity,
    };
  }

  // Метод для создания копии
  LineItem copyWith({
    int? id,
    int? quoteId,
    String? name,
    String? unit,
    double? price,
    double? quantity,
    double? total,
  }) {
    return LineItem(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
    );
  }
}
