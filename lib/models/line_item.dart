// Модель позиции (line item) в коммерческом предложении.
// Соответствует таблице 'line_items' из технического задания.
// Может быть в разделе 'work' (работы) или 'equipment' (оборудование).

import 'package:flutter/foundation.dart';

class LineItem {
  // Уникальный идентификатор, генерируется базой данных
  int? id;

  // Ссылка на коммерческое предложение (внешний ключ)
  int quoteId;

  // Порядковый номер позиции в пределах раздела
  int position;

  // Раздел: 'work' (работы) или 'equipment' (оборудование)
  String section;

  // Описание позиции
  String description;

  // Единица измерения: 'm²', 'm.p.', 'pcs', 'пог. м' и др.
  String unit;

  // Количество (вещественное число, как указано в ТЗ)
  double quantity;

  // Цена за единицу
  double price;

  // Сумма (рассчитывается автоматически: quantity * price)
  double amount;

  // Примечание (опционально)
  String? note;

  // Технические поля для БД (временные метки)
  final DateTime createdAt;
  DateTime updatedAt;

  // Конструктор с обязательными полями и значениями по умолчанию
  LineItem({
    this.id,
    required this.quoteId,
    required this.position,
    required this.section,
    required this.description,
    required this.unit,
    required this.quantity,
    required this.price,
    double? amount,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : amount = amount ?? (quantity * price),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    // Убедимся, что сумма рассчитана корректно, даже если передана явно
    this.amount = this.quantity * this.price;
  }

  // Метод для преобразования объекта LineItem в Map для сохранения в БД
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quote_id': quoteId,
      'position': position,
      'section': section,
      'description': description,
      'unit': unit,
      'quantity': quantity,
      'price': price,
      'amount': amount,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Метод для создания объекта LineItem из Map (при чтении из БД)
  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      id: map['id'] as int?,
      quoteId: map['quote_id'] as int,
      position: map['position'] as int,
      section: map['section'] as String,
      description: map['description'] as String,
      unit: map['unit'] as String,
      quantity: map['quantity'] as double,
      price: map['price'] as double,
      amount: map['amount'] as double,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Копирование объекта с возможностью обновления полей
  // Особенно полезно при редактировании позиции
  LineItem copyWith({
    int? id,
    int? quoteId,
    int? position,
    String? section,
    String? description,
    String? unit,
    double? quantity,
    double? price,
    double? amount,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LineItem(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      position: position ?? this.position,
      section: section ?? this.section,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Вспомогательный геттер для отображения раздела в читаемом виде
  String get sectionDisplayName {
    switch (section) {
      case 'work':
        return 'Работы';
      case 'equipment':
        return 'Оборудование';
      default:
        return section;
    }
  }

  // Метод для перерасчёта суммы на основе текущих quantity и price
  void recalculateAmount() {
    amount = quantity * price;
  }

  // Переопределяем toString для удобства отладки
  @override
  String toString() {
    return 'LineItem(id: $id, pos: $position, $description, $quantity $unit @ $price = $amount, section: $section)';
  }

  // Переопределяем equals (==) и hashCode для корректного сравнения объектов
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          quoteId == other.quoteId &&
          position == other.position &&
          section == other.section;

  @override
  int get hashCode => id.hashCode ^ quoteId.hashCode ^ position.hashCode ^ section.hashCode;
}
