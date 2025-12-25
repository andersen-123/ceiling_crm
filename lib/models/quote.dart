// Модель коммерческого предложения (Quote) для хранения в SQLite.
// Соответствует таблице 'quotes' из технического задания.

import 'package:flutter/foundation.dart';

class Quote {
  // Уникальный идентификатор, генерируется базой данных
  int? id;

  // Основные данные клиента и объекта
  String customerName;
  String? customerPhone;
  String? customerEmail;
  String objectName; // Название объекта: "Квартира", "Офис" и т.д.
  String? address; // Полный адрес объекта

  // Параметры помещения (из ТЗ: S, P, h)
  double? areaS; // Площадь, м²
  double? perimeterP; // Периметр, м.п.
  double? heightH; // Высота, м
  String? ceilingSystem; // Тип системы: "гарпун", "теневой", "парящий"

  // Статус и финансовая информация
  String status; // 'draft', 'sent', 'approved', 'completed'
  String currencyCode; // Валюта: 'RUB', 'USD' и т.д.
  double subtotalWork; // Итого по работам
  double subtotalEquipment; // Итого по оборудованию
  double totalAmount; // Общая сумма

  // Условия и примечания
  String? paymentTerms; // Условия оплаты
  String? installationTerms; // Даты и условия монтажа
  String? notes; // Прочие примечания

  // Технические поля для БД (soft delete и временные метки)
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt; // Для мягкого удаления

  // Конструктор с обязательными полями и значениями по умолчанию
  Quote({
    this.id,
    required this.customerName,
    required this.objectName,
    this.customerPhone,
    this.customerEmail,
    this.address,
    this.areaS,
    this.perimeterP,
    this.heightH,
    this.ceilingSystem,
    this.status = 'draft',
    this.currencyCode = 'RUB',
    this.subtotalWork = 0.0,
    this.subtotalEquipment = 0.0,
    this.totalAmount = 0.0,
    this.paymentTerms,
    this.installationTerms,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Метод для преобразования объекта Quote в Map для сохранения в БД
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'object_name': objectName,
      'address': address,
      'area_s': areaS,
      'perimeter_p': perimeterP,
      'height_h': heightH,
      'ceiling_system': ceilingSystem,
      'status': status,
      'currency_code': currencyCode,
      'subtotal_work': subtotalWork,
      'subtotal_equipment': subtotalEquipment,
      'total_amount': totalAmount,
      'payment_terms': paymentTerms,
      'installation_terms': installationTerms,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  // Метод для создания объекта Quote из Map (при чтении из БД)
  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'] as int?,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String?,
      customerEmail: map['customer_email'] as String?,
      objectName: map['object_name'] as String,
      address: map['address'] as String?,
      areaS: map['area_s'] as double?,
      perimeterP: map['perimeter_p'] as double?,
      heightH: map['height_h'] as double?,
      ceilingSystem: map['ceiling_system'] as String?,
      status: map['status'] as String,
      currencyCode: map['currency_code'] as String,
      subtotalWork: map['subtotal_work'] as double,
      subtotalEquipment: map['subtotal_equipment'] as double,
      totalAmount: map['total_amount'] as double,
      paymentTerms: map['payment_terms'] as String?,
      installationTerms: map['installation_terms'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
    );
  }

  // Копирование объекта с возможностью обновления полей
  Quote copyWith({
    int? id,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? objectName,
    String? address,
    double? areaS,
    double? perimeterP,
    double? heightH,
    String? ceilingSystem,
    String? status,
    String? currencyCode,
    double? subtotalWork,
    double? subtotalEquipment,
    double? totalAmount,
    String? paymentTerms,
    String? installationTerms,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Quote(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      objectName: objectName ?? this.objectName,
      address: address ?? this.address,
      areaS: areaS ?? this.areaS,
      perimeterP: perimeterP ?? this.perimeterP,
      heightH: heightH ?? this.heightH,
      ceilingSystem: ceilingSystem ?? this.ceilingSystem,
      status: status ?? this.status,
      currencyCode: currencyCode ?? this.currencyCode,
      subtotalWork: subtotalWork ?? this.subtotalWork,
      subtotalEquipment: subtotalEquipment ?? this.subtotalEquipment,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      installationTerms: installationTerms ?? this.installationTerms,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  // Переопределяем toString для удобства отладки
  @override
  String toString() {
    return 'Quote(id: $id, customer: $customerName, object: $objectName, total: $totalAmount $currencyCode, status: $status)';
  }

  // Переопределяем equals (==) и hashCode для корректного сравнения объектов
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quote &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          customerName == other.customerName &&
          objectName == other.objectName;

  @override
  int get hashCode => id.hashCode ^ customerName.hashCode ^ objectName.hashCode;
}
