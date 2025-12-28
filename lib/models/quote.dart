import 'dart:convert';

class Quote {
  int? id;
  String title;
  String clientName;
  String? clientPhone;
  String? clientEmail;
  String? clientAddress;
  DateTime createdAt;
  DateTime? validUntil;
  String notes;
  double totalPrice;
  
  // НОВОЕ ПОЛЕ: статус КП
  String status; // 'draft', 'sent', 'accepted', 'rejected', 'expired'
  DateTime? statusChangedAt;
  String? statusComment;
  
  // Конструктор
  Quote({
    this.id,
    required this.title,
    required this.clientName,
    this.clientPhone,
    this.clientEmail,
    this.clientAddress,
    required this.createdAt,
    this.validUntil,
    this.notes = '',
    required this.totalPrice,
    this.status = 'draft',
    this.statusChangedAt,
    this.statusComment,
  });

  // Конвертация в Map для SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'client_name': clientName,
      'client_phone': clientPhone,
      'client_email': clientEmail,
      'client_address': clientAddress,
      'created_at': createdAt.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'notes': notes,
      'total_price': totalPrice,
      // НОВЫЕ ПОЛЯ
      'status': status,
      'status_changed_at': statusChangedAt?.toIso8601String(),
      'status_comment': statusComment,
    };
  }

  // Создание объекта из Map
  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'],
      title: map['title'],
      clientName: map['client_name'],
      clientPhone: map['client_phone'],
      clientEmail: map['client_email'],
      clientAddress: map['client_address'],
      createdAt: DateTime.parse(map['created_at']),
      validUntil: map['valid_until'] != null ? DateTime.parse(map['valid_until']) : null,
      notes: map['notes'] ?? '',
      totalPrice: map['total_price'],
      // НОВЫЕ ПОЛЯ
      status: map['status'] ?? 'draft',
      statusChangedAt: map['status_changed_at'] != null 
          ? DateTime.parse(map['status_changed_at']) 
          : null,
      statusComment: map['status_comment'],
    );
  }

  // Конвертация в JSON
  String toJson() => json.encode(toMap());

  // Создание из JSON
  factory Quote.fromJson(String source) => Quote.fromMap(json.decode(source));

  // Методы для изменения статуса
  void markAsSent() {
    status = 'sent';
    statusChangedAt = DateTime.now();
  }

  void markAsAccepted({String? comment}) {
    status = 'accepted';
    statusChangedAt = DateTime.now();
    statusComment = comment;
  }

  void markAsRejected({String? comment}) {
    status = 'rejected';
    statusChangedAt = DateTime.now();
    statusComment = comment;
  }

  // Геттер для отображения статуса
  String get statusDisplay {
    switch (status) {
      case 'draft': return 'Черновик';
      case 'sent': return 'Отправлен';
      case 'accepted': return 'Принят';
      case 'rejected': return 'Отклонен';
      case 'expired': return 'Просрочен';
      default: return 'Черновик';
    }
  }

  // Проверка статусов
  bool get isDraft => status == 'draft';
  bool get isSent => status == 'sent';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  
  // Цвет статуса для UI
  Color get statusColor {
    switch (status) {
      case 'draft': return Colors.grey;
      case 'sent': return Colors.blue;
      case 'accepted': return Colors.green;
      case 'rejected': return Colors.red;
      case 'expired': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
