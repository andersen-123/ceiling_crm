// Модель профиля компании для настроек приложения.
// Соответствует таблице 'companies' из технического задания.
// Содержит данные, которые подставляются в PDF (название, логотип, контакты).

import 'package:flutter/foundation.dart';

class CompanyProfile {
  // Уникальный идентификатор, генерируется базой данных
  int? id;

  // Основные данные компании
  String name;
  String? phone;
  String? email;
  String? website;
  String? address;

  // Путь к файлу логотипа (из галереи или assets)
  String? logoPath;

  // Дополнительный текст для подвала PDF (условия, реквизиты и т.д.)
  String? footerNote;

  // Технические поля для БД (временные метки)
  final DateTime createdAt;
  DateTime updatedAt;

  // Конструктор с обязательными полями и значениями по умолчанию
  CompanyProfile({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.website,
    this.address,
    this.logoPath,
    this.footerNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Метод для преобразования объекта CompanyProfile в Map для сохранения в БД
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address,
      'logo_path': logoPath,
      'footer_note': footerNote,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Метод для создания объекта CompanyProfile из Map (при чтении из БД)
  factory CompanyProfile.fromMap(Map<String, dynamic> map) {
    return CompanyProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      website: map['website'] as String?,
      address: map['address'] as String?,
      logoPath: map['logo_path'] as String?,
      footerNote: map['footer_note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Копирование объекта с возможностью обновления полей
  // Полезно при редактировании профиля компании
  CompanyProfile copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? website,
    String? address,
    String? logoPath,
    String? footerNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      logoPath: logoPath ?? this.logoPath,
      footerNote: footerNote ?? this.footerNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Проверка, заполнены ли минимальные необходимые данные для экспорта в PDF
  bool get hasMinimalDataForPdf {
    return name.isNotEmpty;
  }

  // Вспомогательный геттер для отображения краткой информации
  String get displayInfo {
    return '$name${phone != null ? ' • $phone' : ''}';
  }

  // Переопределяем toString для удобства отладки
  @override
  String toString() {
    return 'CompanyProfile(id: $id, name: $name, phone: $phone, email: $email)';
  }

  // Переопределяем equals (==) и hashCode для корректного сравнения объектов
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
