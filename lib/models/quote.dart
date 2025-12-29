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
  });

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
    );
  }

  @override
  String toString() {
    return 'Quote(id: $id, client: $clientName, total: $totalAmount, status: $status)';
  }
}
