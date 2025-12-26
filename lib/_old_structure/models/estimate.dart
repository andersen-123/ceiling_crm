import 'package:ceiling_crm/models/estimate_item.dart';

// Убедитесь, что класс Estimate имеет эти поля:
class Estimate {
  final int? id;
  final String? name; // ← ДОЛЖНО БЫТЬ
  final String clientName;
  final String address;
  final double area;
  final double perimeter;
  final double pricePerMeter;
  final double totalPrice;
  final DateTime createdDate;
  final String? notes; // ← ДОЛЖНО БЫТЬ
  final List<EstimateItem> items;

  Estimate({
    this.id,
    this.name, // ← ДОЛЖЕН БЫТЬ В КОНСТРУКТОРЕ
    required this.clientName,
    required this.address,
    required this.area,
    required this.perimeter,
    required this.pricePerMeter,
    required this.totalPrice,
    required this.createdDate,
    this.notes, // ← ДОЛЖЕН БЫТЬ В КОНСТРУКТОРЕ
    this.items = const [],
  });
  
  // Добавьте геттеры для name и notes:
  String? get name => _name;
  String? get notes => _notes;
}

  double get total => items.fold(0, (sum, item) => sum + item.total);

  Map<String, List<EstimateItem>> get itemsByCategory {
    final map = <String, List<EstimateItem>>{};
    for (var item in items) {
      if (!map.containsKey(item.category)) {
        map[item.category] = [];
      }
      map[item.category]!.add(item);
    }
    return map;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_name': clientName,
      'address': address,
      'area': area,
      'perimeter': perimeter,
      'price_per_meter': pricePerMeter,
      'total_price': totalPrice,
      'created_date': createdDate.toIso8601String(),
    };
  }

  factory Estimate.fromMap(Map<String, dynamic> map) {
    return Estimate(
      id: map['id'] as int?,
      clientName: map['client_name'] as String,
      address: map['address'] as String,
      area: (map['area'] as num).toDouble(),
      perimeter: (map['perimeter'] as num).toDouble(),
      pricePerMeter: (map['price_per_meter'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      createdDate: DateTime.parse(map['created_date'] as String),
      items: [],
    );
  }

  Estimate copyWith({
    int? id,
    String? clientName,
    String? address,
    double? area,
    double? perimeter,
    double? pricePerMeter,
    double? totalPrice,
    DateTime? createdDate,
    List<EstimateItem>? items,
  }) {
    return Estimate(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      address: address ?? this.address,
      area: area ?? this.area,
      perimeter: perimeter ?? this.perimeter,
      pricePerMeter: pricePerMeter ?? this.pricePerMeter,
      totalPrice: totalPrice ?? this.totalPrice,
      createdDate: createdDate ?? this.createdDate,
      items: items ?? this.items,
    );
  }

  Estimate addFromTemplate(EstimateItem template, {double quantity = 1.0}) {
    final newItem = EstimateItem(
      name: template.name,
      category: template.category,
      quantity: quantity,
      unit: template.unit,
      price: template.price,
      description: template.description,
    );

    final newItems = List<EstimateItem>.from(items)..add(newItem);
    return copyWith(items: newItems);
  }

  Estimate updateItem(int index, EstimateItem updatedItem) {
    final newItems = List<EstimateItem>.from(items);
    newItems[index] = updatedItem;
    return copyWith(items: newItems);
  }

  Estimate removeItem(int index) {
    final newItems = List<EstimateItem>.from(items);
    newItems.removeAt(index);
    return copyWith(items: newItems);
  }
}
