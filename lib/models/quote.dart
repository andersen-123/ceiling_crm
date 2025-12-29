import 'line_item.dart';  // ДОБАВЛЕНО

class Quote {
  int? id;
  String clientName;
  String clientEmail;
  String clientPhone;
  String clientAddress;
  String projectName;
  String projectDescription;
  double totalAmount;
  String status;
  String notes;
  DateTime createdAt;
  DateTime updatedAt;
  List<LineItem> items;

  Quote({
    this.id,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.clientAddress,
    required this.projectName,
    required this.projectDescription,
    required this.totalAmount,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  void addItem(LineItem item) {
    items.add(item);
    _calculateTotal();
  }

  void addItems(List<LineItem> newItems) {
    items.addAll(newItems);
    _calculateTotal();
  }

  void updateItem(int index, LineItem item) {
    if (index >= 0 && index < items.length) {
      items[index] = item;
      _calculateTotal();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      _calculateTotal();
    }
  }

  void _calculateTotal() {
    totalAmount = items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

    // Метод для создания копии с изменениями
  Quote copyWith({
    int? id,
    String? clientName,
    String? clientEmail,
    String? clientPhone,
    String? clientAddress,
    String? projectName,
    String? projectDescription,
    double? totalAmount,
    String? status,
    String? notes,
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
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'client_name': clientName,
      'client_email': clientEmail,
      'client_phone': clientPhone,
      'client_address': clientAddress,
      'project_name': projectName,
      'project_description': projectDescription,
      'total_amount': totalAmount,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'],
      clientName: map['client_name'] ?? '',
      clientEmail: map['client_email'] ?? '',
      clientPhone: map['client_phone'] ?? '',
      clientAddress: map['client_address'] ?? '',
      projectName: map['project_name'] ?? '',
      projectDescription: map['project_description'] ?? '',
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'черновик',
      notes: map['notes'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      items: [],
    );
  }

  @override
  String toString() {
    return 'Quote(id: $id, client: $clientName, total: $totalAmount, status: $status, items: ${items.length})';
  }
}
