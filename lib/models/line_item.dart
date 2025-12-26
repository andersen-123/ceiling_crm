// lib/models/line_item.dart

class LineItem {
  int? id;
  final int quoteId; // Ссылка на id коммерческого предложения
  final String section; // Раздел: "Работы", "Материалы" и т.д.
  final String description; // Описание позиции
  final String unit; // Единица измерения: "м2", "шт.", "п.м."
  final double quantity;
  final double unitPrice;
  double get total => quantity * unitPrice; // Автоматический расчёт суммы

  LineItem({
    this.id,
    required this.quoteId,
    required this.section,
    required this.description,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
  });

  // Конвертация в Map для SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'quoteId': quoteId,
      'section': section,
      'description': description,
      'unit': unit,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  // Создание объекта из Map (из SQLite)
  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      id: map['id'],
      quoteId: map['quoteId'],
      section: map['section'],
      description: map['description'],
      unit: map['unit'],
      quantity: map['quantity'],
      unitPrice: map['unitPrice'],
    );
  }

  // Копия объекта с изменениями (удобно для редактирования)
  LineItem copyWith({
    int? id,
    int? quoteId,
    String? section,
    String? description,
    String? unit,
    double? quantity,
    double? unitPrice,
  }) {
    return LineItem(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      section: section ?? this.section,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}
