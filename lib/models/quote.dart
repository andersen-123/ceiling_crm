import 'package:flutter/foundation.dart';

class Quote {
  int? id;
  String clientName;
  String clientPhone;
  String objectAddress;
  String? notes;
  String status; // draft, sent, accepted, rejected
  DateTime createdAt;
  DateTime? updatedAt;
  double total;
  double vatRate;
  
  Quote({
    this.id,
    required this.clientName,
    required this.clientPhone,
    required this.objectAddress,
    this.notes,
    this.status = 'draft',
    required this.createdAt,
    this.updatedAt,
    this.total = 0.0,
    this.vatRate = 20.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_name': clientName,
      'client_phone': clientPhone,
      'object_address': objectAddress,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'total': total,
      'vat_rate': vatRate,
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'],
      clientName: map['client_name'] ?? '',
      clientPhone: map['client_phone'] ?? '',
      objectAddress: map['object_address'] ?? '',
      notes: map['notes'],
      status: map['status'] ?? 'draft',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      total: map['total']?.toDouble() ?? 0.0,
      vatRate: map['vat_rate']?.toDouble() ?? 20.0,
    );
  }

  @override
  String toString() {
    return 'Quote(id: $id, client: $clientName, total: $total, status: $status)';
  }

  Quote copyWith({
    int? id,
    String? clientName,
    String? clientPhone,
    String? objectAddress,
    String? notes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? total,
    double? vatRate,
  }) {
    return Quote(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      objectAddress: objectAddress ?? this.objectAddress,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      total: total ?? this.total,
      vatRate: vatRate ?? this.vatRate,
    );
  }
}
