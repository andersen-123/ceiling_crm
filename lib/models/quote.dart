// lib/models/quote.dart
import 'package:ceiling_crm/models/line_item.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class Quote {
  int? id;
  String clientName;
  String address;
  String phone;
  String email;
  String notes;
  double totalAmount;
  List<LineItem> positions;
  DateTime? createdAt;
  DateTime? updatedAt;

  Quote({
    this.id,
    required this.clientName,
    required this.address,
    this.phone = '',
    this.email = '',
    this.notes = '',
    this.totalAmount = 0.0,
    List<LineItem>? positions,
    this.createdAt,
    this.updatedAt,
  }) : positions = positions ?? [];

  // Преобразование в Map для SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'address': address,
      'phone': phone,
      'email': email,
      'notes': notes,
      'totalAmount': totalAmount,
      'positions': jsonEncode(positions.map((p) => p.toMap()).toList()),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Создание из Map из SQLite
  factory Quote.fromMap(Map<String, dynamic> map) {
    List<LineItem> positions = [];
    try {
      if (map['positions'] != null && map['positions'].isNotEmpty) {
        final positionsList = jsonDecode(map['positions']) as List;
        positions = positionsList
            .map((p) => LineItem.fromMap(p as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error parsing positions: $e');
    }

    return Quote(
      id: map['id'],
      clientName: map['clientName'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      notes: map['notes'] ?? '',
      totalAmount: map['totalAmount'] ?? 0.0,
      positions: positions,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  // Копирование объекта с изменениями
  Quote copyWith({
    int? id,
    String? clientName,
    String? address,
    String? phone,
    String? email,
    String? notes,
    double? totalAmount,
    List<LineItem>? positions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quote(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      totalAmount: totalAmount ?? this.totalAmount,
      positions: positions ?? List.from(this.positions),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Расчет общей суммы
  double calculateTotal() {
    return positions.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
  }

  @override
  String toString() {
    return 'Quote(id: $id, clientName: $clientName, total: $totalAmount)';
  }
  // Метод для загрузки стандартных позиций из JSON
  static Future<List<LineItem>> loadStandardPositions() async {
    try {
      final jsonString = await rootBundle.loadString('assets/standard_positions.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      return jsonList.map((item) {
        return LineItem(
          id: 0, // ID будет установлен при добавлении
          name: item['name'] ?? '',
          quantity: 1.0, // По умолчанию 1
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

  // Запасной метод на случай ошибки загрузки файла
  static List<LineItem> _getDefaultPositions() {
    return [
      LineItem(
        id: 0,
        name: 'Полотно MSD Premium белое матовое с установкой',
        quantity: 1.0,
        unit: 'м²',
        price: 610.0,
        note: '',
      ),
      LineItem(
        id: 0,
        name: 'Профиль стеновой/потолочный гарпунный с установкой',
        quantity: 1.0,
        unit: 'м.п.',
        price: 310.0,
        note: '',
      ),
      // ... добавьте другие позиции по аналогии
    ];
  }
}

