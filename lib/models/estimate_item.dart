class EstimateItem {
  final int? id; // Может быть null, когда элемент создаётся впервые
  final int estimateId; // Связь со сметой (estimate_id)
  final String name;
  final String category; // Добавлено из схемы БД
  final String unit;
  final double price;
  final double quantity;
  final int isCustom; // В БД это INTEGER (0 или 1)
  final String? notes; // Может быть null
  final int? positionNumber; // Может быть null

  EstimateItem({
    this.id,
    required this.estimateId,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    required this.quantity,
    this.isCustom = 0,
    this.notes,
    this.positionNumber,
  });

  double get total => price * quantity;

  // Конвертирует Map из базы данных в объект EstimateItem
  factory EstimateItem.fromMap(Map<String, dynamic> map) {
    return EstimateItem(
      id: map['id'] as int?,
      estimateId: map['estimate_id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      unit: map['unit'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      isCustom: map['is_custom'] as int? ?? 0,
      notes: map['notes'] as String?,
      positionNumber: map['position_number'] as int?,
    );
  }

  // Конвертирует объект EstimateItem в Map для базы данных
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'estimate_id': estimateId,
      'name': name,
      'category': category,
      'unit': unit,
      'price': price,
      'quantity': quantity,
      'is_custom': isCustom,
      'notes': notes,
      'position_number': positionNumber,
    };
  }

  // Метод для копирования объекта с изменениями (используется в copyWith)
  EstimateItem copyWith({
    int? id,
    int? estimateId,
    String? name,
    String? category,
    String? unit,
    double? price,
    double? quantity,
    int? isCustom,
    String? notes,
    int? positionNumber,
  }) {
    return EstimateItem(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isCustom: isCustom ?? this.isCustom,
      notes: notes ?? this.notes,
      positionNumber: positionNumber ?? this.positionNumber,
    );
  }
}
