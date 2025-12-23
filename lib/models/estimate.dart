class Estimate {
  final int? id;
  final String? name; // Название сметы
  final String clientName;
  final String address;
  final double area;
  final double perimeter;
  final double pricePerMeter;
  final double totalPrice;
  final DateTime createdDate;
  final String? notes;
  // ДОБАВЬТЕ ЭТО ПОЛЕ:
  final List<EstimateItem> items; // Список элементов сметы

  Estimate({
    this.id,
    this.name,
    required this.clientName,
    required this.address,
    required this.area,
    required this.perimeter,
    required this.pricePerMeter,
    required this.totalPrice,
    required this.createdDate,
    this.notes,
    // ИНИЦИАЛИЗИРУЙТЕ ЕГО (по умолчанию пустой список):
    this.items = const [],
  });

  // Геттер для вычисления общего итога из items
  double get total => items.fold(0, (sum, item) => sum + item.total);

  // Геттер для группировки items по категориям
  Map<String, List<EstimateItem>> get itemsByCategory {
    final map = <String, List<EstimateItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  // Геттер для названия (используется в UI)
  String get title => name ?? 'Смета от ${createdDate.toString().substring(0, 10)}';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clientName': clientName,
      'address': address,
      'area': area,
      'perimeter': perimeter,
      'pricePerMeter': pricePerMeter,
      'totalPrice': totalPrice,
      'createdDate': createdDate.toIso8601String(),
      'notes': notes,
      // Items не сохраняются здесь, они сохраняются отдельно
    };
  }

  factory Estimate.fromMap(Map<String, dynamic> map) {
    return Estimate(
      id: map['id'],
      name: map['name'],
      clientName: map['clientName'],
      address: map['address'],
      area: map['area'],
      perimeter: map['perimeter'],
      pricePerMeter: map['pricePerMeter'],
      totalPrice: map['totalPrice'],
      createdDate: DateTime.parse(map['createdDate']),
      notes: map['notes'],
      items: const [], // Items загружаются отдельно
    );
  }

  Estimate copyWith({
    int? id,
    String? name,
    String? clientName,
    String? address,
    double? area,
    double? perimeter,
    double? pricePerMeter,
    double? totalPrice,
    DateTime? createdDate,
    String? notes,
    List<EstimateItem>? items,
  }) {
    return Estimate(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      address: address ?? this.address,
      area: area ?? this.area,
      perimeter: perimeter ?? this.perimeter,
      pricePerMeter: pricePerMeter ?? this.pricePerMeter,
      totalPrice: totalPrice ?? this.totalPrice,
      createdDate: createdDate ?? this.createdDate,
      notes: notes ?? this.notes,
      items: items ?? this.items,
    );
  }

  // --- ДОБАВЬТЕ ЭТИ МЕТОДЫ, КОТОРЫЕ ИСПОЛЬЗУЮТСЯ В КОДЕ ---

  // Метод для добавления элемента из шаблона
  Estimate addFromTemplate(EstimateItem template, {double quantity = 1.0}) {
    final newItem = template.copyWith(quantity: quantity);
    return copyWith(items: [...items, newItem]);
  }

  // Метод для добавления пользовательского элемента
  Estimate addCustomItem({
    required String name,
    required String category,
    required double price,
    required String unit,
    required double quantity,
  }) {
    final newItem = EstimateItem(
      name: name,
      category: category,
      price: price,
      unit: unit,
      quantity: quantity,
    );
    return copyWith(items: [...items, newItem]);
  }

  // Метод для обновления элемента
  Estimate updateItem(int index, EstimateItem updatedItem) {
    final newItems = List<EstimateItem>.from(items);
    newItems[index] = updatedItem;
    return copyWith(items: newItems);
  }

  // Метод для удаления элемента
  Estimate removeItem(int index) {
    final newItems = List<EstimateItem>.from(items);
    newItems.removeAt(index);
    return copyWith(items: newItems);
  }
}
