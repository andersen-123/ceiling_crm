class EstimateItem {
  final String name; // "Полотно MSD Premium", "Бензин"
  final String category; // "Материалы", "Работы", "Расходы", "Доходы"
  final double quantity;
  final String unit; // "м²", "шт.", "л", "руб."
  final double price;
  final bool isCustom; // true = уникальная позиция, false = из шаблона

  EstimateItem({
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.price,
    this.isCustom = false,
  });

  double get total => quantity * price;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'price': price,
      'is_custom': isCustom ? 1 : 0,
    };
  }

  factory EstimateItem.fromMap(Map<String, dynamic> map) {
    return EstimateItem(
      name: map['name'],
      category: map['category'],
      quantity: map['quantity'],
      unit: map['unit'],
      price: map['price'],
      isCustom: map['is_custom'] == 1,
    );
  }
}

class Estimate {
  int? id;
  int? clientId; // Может быть null
  final String title; // "Смета для объекта Нежинская 1к2"
  final List<EstimateItem> items;
  final DateTime createdAt;

  Estimate({
    this.id,
    this.clientId,
    required this.title,
    required this.items,
    required this.createdAt,
  });

  double get total => items.fold(0, (sum, item) => sum + item.total);

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
      items: [], // Элементы загружаются отдельным запросом
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }
}
