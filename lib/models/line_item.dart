// lib/models/line_item.dart
class LineItem {
  int id;
  String name;
  String description;
  double quantity;
  String unit;
  double price;

  LineItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.quantity,
    required this.unit,
    required this.price,
  });

  // Преобразование в Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'total': quantity * price,
    };
  }

  // Создание из Map
  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch,
      name: map['name'] ?? 'Без названия',
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 1.0,
      unit: map['unit'] ?? 'шт.',
      price: map['price'] ?? 0.0,
    );
  }

  // Копирование с изменениями
  LineItem copyWith({
    int? id,
    String? name,
    String? description,
    double? quantity,
    String? unit,
    double? price,
  }) {
    return LineItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
    );
  }

  // Получение суммы
  double get total => quantity * price;

  @override
  String toString() {
    return 'LineItem($name: $quantity $unit × $price = $total)';
  }
}
