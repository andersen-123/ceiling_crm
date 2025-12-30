import 'line_item.dart'; // ← ДОБАВЛЕН ИМПОРТ

class Quote {
  final int? id;
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String clientAddress;
  final String projectName;
  final String projectDescription;
  final String notes;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt; // ← ДОБАВЛЕНО
  final List<LineItem> items; // ← ДОБАВЛЕНО

  String get email => clientEmail;
  String get phone => clientPhone;
  String get address => clientAddress;

  Quote({
    this.id,
    required this.clientName,
    this.clientEmail = '',
    this.clientPhone = '',
    this.clientAddress = '',
    required this.projectName,
    this.projectDescription = '',
    this.notes = '',
    this.status = 'draft',
    this.totalAmount = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.items = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'client_name': clientName,
      'client_email': clientEmail,
      'client_phone': clientPhone,
      'client_address': clientAddress,
      'project_name': projectName,
      'project_description': projectDescription,
      'notes': notes,
      'status': status,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map, {List<LineItem>? items}) {
    return Quote(
      id: map['id'] as int?,
      clientName: map['client_name'] as String? ?? '',
      clientEmail: map['client_email'] as String? ?? '',
      clientPhone: map['client_phone'] as String? ?? '',
      clientAddress: map['client_address'] as String? ?? '',
      projectName: map['project_name'] as String? ?? '',
      projectDescription: map['project_description'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      status: map['status'] as String? ?? 'draft',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      items: items ?? [],
    );
  }

  Quote copyWith({
    int? id,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? clientAddress,
    String? projectName,
    String? projectDescription,
    String? notes,
    String? status,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LineItem>? items,
  }) {
    return Quote(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      clientAddress: clientAddress ?? this.clientAddress,
      projectName: projectName ?? this.projectName,
      projectDescription: projectDescription ?? this.projectDescription,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  double calculateTotal() => items.fold(0.0, (sum, item) => sum + item.total);
}
