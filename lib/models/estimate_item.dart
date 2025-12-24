class EstimateItem {
  final int? id;
  final int? estimateId;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final double price;
  final String? description;

  EstimateItem({
    this.id,
    this.estimateId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.price,
    this.description,
  });

  // Конструктор для создания шаблона
  factory EstimateItem.template({
    required String name,
    required String category,
    required String unit,
    required double price,
    String? description,
  }) {
    return EstimateItem(
      name: name,
      category: category,
      quantity: 1.0,
      unit: unit,
      price: price,
      description: description,
    );
  }

  double get total => quantity * price;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'estimate_id': estimateId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'description': description,
    };
  }

  factory EstimateItem.fromMap(Map<String, dynamic> map) {
    return EstimateItem(
      id: map['id'] as int?,
      estimateId: map['estimate_id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      price: (map['price'] as num).toDouble(),
      description: map['description'] as String?,
    );
  }

  EstimateItem copyWith({
    int? id,
    int? estimateId,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    double? price,
    String? description,
  }) {
    return EstimateItem(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      description: description ?? this.description,
    );
  }
}
