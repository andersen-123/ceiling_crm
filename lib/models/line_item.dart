class LineItem {
  final int? id;
  final int quoteId;
  final String name;
  final String description;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  
  // Вычисляемое поле
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
      id: map['id'] as int?,
      quoteId: map['quote_id'] as int,
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

  // ✅ ДОПОЛНИТЕЛЬНЫЕ МЕТОДЫ ДЛЯ СОВМЕСТИМОСТИ С КОДОМ

  // Для обратной совместимости с кодом, ожидающим price
  double get price => total;

  // Статический конструктор для быстрого создания (database_helper.dart)
  factory LineItem.quick({
    required String name,
    required double quantity,
    required String unit,
    required double pricePerUnit,
    int quoteId = 1,
  }) {
    return LineItem(
      quoteId: quoteId,
      name: name,
      quantity: quantity,
      unit: unit,
      pricePerUnit: pricePerUnit,
    );
  }

  // JSON сериализация для PDF и других сервисов
  Map<String, dynamic> toJson() => toMap();

  // Строка представления для отладки
  @override
  String toString() {
    return 'LineItem(id: $id, name: $name, quantity: $quantity $unit, total: ${total.toStringAsFixed(2)}₽)';
  }
}
