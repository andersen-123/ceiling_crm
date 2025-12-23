class EstimateItem {
  final int? id;
  final int? estimateId; // Связь с родительской сметой (Estimate)
  final String name;
  final String category;
  final double price;
  final String unit; // Например: 'шт.', 'м.п.', 'м²'
  final double quantity;
  final double total;

  EstimateItem({
    this.id,
    this.estimateId,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    required this.quantity,
  }) : total = price * quantity;

  // Именованный конструктор для создания элементов из шаблонов
  factory EstimateItem.template({
    required String name,
    required String category,
    required double price,
    required String unit,
  }) {
    return EstimateItem(
      name: name,
      category: category,
      price: price,
      unit: unit,
      quantity: 1.0, // Количество по умолчанию
    );
  }

  // Преобразование в Map для базы данных
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'estimate_id': estimateId,
      'name': name,
      'category': category,
      'price': price,
      'unit': unit,
      'quantity': quantity,
      'total': total,
    };
  }

  // Создание из Map (из базы данных)
  factory EstimateItem.fromMap(Map<String, dynamic> map) {
    return EstimateItem(
      id: map['id'],
      estimateId: map['estimate_id'],
      name: map['name'],
      category: map['category'],
      price: map['price'].toDouble(),
      unit: map['unit'],
      quantity: map['quantity'].toDouble(),
    );
  }

  // Создание копии с изменениями
  EstimateItem copyWith({
    int? id,
    int? estimateId,
    String? name,
    String? category,
    double? price,
    String? unit,
    double? quantity,
  }) {
    return EstimateItem(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
    );
  }
}
