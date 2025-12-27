import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'line_item.dart';

class Quote {
  int id;
  String clientName;
  String clientAddress;
  String clientPhone;
  String clientEmail;
  String notes;
  List<LineItem> items;
  DateTime createdAt;
  DateTime updatedAt;

  Quote({
    this.id = 0,
    required this.clientName,
    required this.clientAddress,
    required this.clientPhone,
    required this.clientEmail,
    required this.notes,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'clientAddress': clientAddress,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
      'notes': notes,
      'items': jsonEncode(items.map((item) => item.toMap()).toList()),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    List<LineItem> items = [];
    try {
      if (map['items'] != null) {
        final itemsList = jsonDecode(map['items'] as String) as List;
        items = itemsList.map((itemMap) => LineItem.fromMap(itemMap)).toList();
      }
    } catch (e) {
      print('Error parsing items: $e');
    }

    return Quote(
      id: map['id'] as int,
      clientName: map['clientName'] as String,
      clientAddress: map['clientAddress'] as String,
      clientPhone: map['clientPhone'] as String,
      clientEmail: map['clientEmail'] as String,
      notes: map['notes'] as String,
      items: items,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Quote copyWith({
    int? id,
    String? clientName,
    String? clientAddress,
    String? clientPhone,
    String? clientEmail,
    String? notes,
    List<LineItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quote(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientAddress: clientAddress ?? this.clientAddress,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      notes: notes ?? this.notes,
      items: items ?? List.from(this.items),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Метод для загрузки стандартных позиций из JSON файла
  static Future<List<LineItem>> loadStandardPositions() async {
    try {
      final jsonString = await rootBundle.loadString('assets/standard_positions.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      return jsonList.map((item) {
        return LineItem(
          id: 0,
          name: item['name'] ?? '',
          quantity: 1.0,
          unit: item['unit'] ?? 'шт.',
          price: (item['price'] as num).toDouble(),
          note: item['note'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('Ошибка загрузки стандартных позиций: $e');
      return _getDefaultPositions();
    }
  }

  static List<LineItem> _getDefaultPositions() {
    return [
      LineItem(
        id: 0,
        name: 'Полотно MSD Premium белое матовое с установкой',
        quantity: 1.0,
        unit: 'м²',
        price: 610.0,
        note: 'Стандартная установка',
      ),
      LineItem(
        id: 0,
        name: 'Профиль стеновой/потолочный гарпунный с установкой',
        quantity: 1.0,
        unit: 'м.п.',
        price: 310.0,
        note: '',
      ),
      LineItem(
        id: 0,
        name: 'Вставка по периметру гарпунная',
        quantity: 1.0,
        unit: 'м.п.',
        price: 220.0,
        note: '',
      ),
    ];
  }
}
