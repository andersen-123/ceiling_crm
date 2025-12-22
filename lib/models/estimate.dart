class EstimateItem {
  int? id;
  int? estimateId;
  String name;
  String category;
  double quantity;
  String unit;
  double price;
  bool isCustom;
  String? notes;
  int? positionNumber;

  EstimateItem({
    this.id,
    this.estimateId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.price,
    this.isCustom = false,
    this.notes,
    this.positionNumber,
  });

  double get total => quantity * price;

  EstimateItem.template({
    required String name,
    required String category,
    required String unit,
    required double price,
  }) : this(
          name: name,
          category: category,
          quantity: 0.0,
          unit: unit,
          price: price,
          isCustom: false,
        );

  EstimateItem.custom({
    required String name,
    double quantity = 1.0,
    String unit = 'шт.',
    double price = 0.0,
    String category = 'Прочее',
    String? notes,
  }) : this(
          name: name,
          category: category,
          quantity: quantity,
          unit: unit,
          price: price,
          isCustom: true,
          notes: notes,
        );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'estimate_id': estimateId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'is_custom': isCustom ? 1 : 0,
      'notes': notes,
      'position_number': positionNumber,
    };
  }

  factory EstimateItem.fromMap(Map<String, dynamic> map) {
    return EstimateItem(
      id: map['id'],
      estimateId: map['estimate_id'],
      name: map['name'],
      category: map['category'],
      quantity: map['quantity'] is int
          ? (map['quantity'] as int).toDouble()
          : map['quantity'],
      unit: map['unit'],
      price: map['price'] is int
          ? (map['price'] as int).toDouble()
          : map['price'],
      isCustom: map['is_custom'] == 1,
      notes: map['notes'],
      positionNumber: map['position_number'],
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
    bool? isCustom,
    String? notes,
    int? positionNumber,
  }) {
    return EstimateItem(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      isCustom: isCustom ?? this.isCustom,
      notes: notes ?? this.notes,
      positionNumber: positionNumber ?? this.positionNumber,
    );
  }
}

class Estimate {
  int? id;
  int? clientId;
  String title;
  List<EstimateItem> items;
  DateTime createdAt;

  Estimate({
    this.id,
    this.clientId,
    required this.title,
    required this.items,
    required this.createdAt,
  });

  double get total =>
      items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));

  Map<String, List<EstimateItem>> get itemsByCategory {
    final map = <String, List<EstimateItem>>{};
    for (var item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  void addFromTemplate(EstimateItem template, {double quantity = 1.0}) {
    final newItem = template.copyWith(
      quantity: quantity,
      estimateId: id,
      positionNumber: items.length + 1,
    );
    items.add(newItem);
  }

  void addCustomItem({
    required String name,
    double quantity = 1.0,
    String unit = 'шт.',
    double price = 0.0,
    String category = 'Прочее',
    String? notes,
  }) {
    final newItem = EstimateItem.custom(
      name: name,
      quantity: quantity,
      unit: unit,
      price: price,
      category: category,
      notes: notes,
    )
      ..estimateId = id
      ..positionNumber = items.length + 1;

    items.add(newItem);
  }

  void updateItem(int index, EstimateItem updatedItem) {
    if (index >= 0 && index < items.length) {
      items[index] = updatedItem.copyWith(positionNumber: index + 1);
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      for (var i = 0; i < items.length; i++) {
        items[i] = items[i].copyWith(positionNumber: i + 1);
      }
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'title': title,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Estimate.fromMap(Map<String, dynamic> map) {
    return Estimate(
      id: map['id'],
      clientId: map['client_id'],
      title: map['title'],
      items: [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Estimate copyWith({
    int? id,
    int? clientId,
    String? title,
    List<EstimateItem>? items,
    DateTime? createdAt,
  }) {
    return Estimate(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
