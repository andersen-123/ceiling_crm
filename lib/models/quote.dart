import 'package:flutter/material.dart';

class Quote {
  final int? id;
  final String clientName;
  final String? clientPhone;
  final String? objectAddress;
  final String status;
  final DateTime createdAt;
  final double? total;
  final double? vatRate;
  final double? vatAmount;
  final double? totalWithVat;

  Quote({
    this.id,
    required this.clientName,
    this.clientPhone,
    this.objectAddress,
    this.status = 'draft',
    DateTime? createdAt,
    this.total,
    this.vatRate,
    this.vatAmount,
    this.totalWithVat,
  }) : createdAt = createdAt ?? DateTime.now();

  // Фабричный конструктор из Map
  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'] as int?,
      clientName: map['client_name'] ?? '',
      clientPhone: map['client_phone'],
      objectAddress: map['object_address'],
      status: map['status'] ?? 'draft',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      total: (map['total'] as num?)?.toDouble(),
      vatRate: (map['vat_rate'] as num?)?.toDouble(),
      vatAmount: (map['vat_amount'] as num?)?.toDouble(),
      totalWithVat: (map['total_with_vat'] as num?)?.toDouble(),
    );
  }

  // Метод для преобразования в Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'client_name': clientName,
      'client_phone': clientPhone,
      'object_address': objectAddress,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'total': total,
      'vat_rate': vatRate,
      'vat_amount': vatAmount,
      'total_with_vat': totalWithVat,
    };
  }

  // Метод для создания копии
  Quote copyWith({
    int? id,
    String? clientName,
    String? clientPhone,
    String? objectAddress,
    String? status,
    DateTime? createdAt,
    double? total,
    double? vatRate,
    double? vatAmount,
    double? totalWithVat,
  }) {
    return Quote(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      objectAddress: objectAddress ?? this.objectAddress,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      total: total ?? this.total,
      vatRate: vatRate ?? this.vatRate,
      vatAmount: vatAmount ?? this.vatAmount,
      totalWithVat: totalWithVat ?? this.totalWithVat,
    );
  }

  // Геттер для цвета статуса
  Color get statusColor {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default: // draft
        return Colors.grey;
    }
  }

  // Геттер для текста статуса
  String get statusText {
    switch (status) {
      case 'accepted':
        return 'Принят';
      case 'rejected':
        return 'Отклонен';
      case 'pending':
        return 'На рассмотрении';
      default: // draft
        return 'Черновик';
    }
  }
}
