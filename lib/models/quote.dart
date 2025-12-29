class Quote {
  final int? id;
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String clientAddress;
  final String projectName;
  final String projectDescription;
  final double totalAmount;
  final String status; // 'draft' или 'отправлено'
  final DateTime date;

  Quote({
    this.id,
    required this.clientName,
    this.clientEmail = '',
    this.clientPhone = '',
    this.clientAddress = '',
    required this.projectName,
    this.projectDescription = '',
    this.totalAmount = 0.0,
    this.status = 'черновик',
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_name': clientName,
      'client_email': clientEmail,
      'client_phone': clientPhone,
      'client_address': clientAddress,
      'project_name': projectName,
      'project_description': projectDescription,
      'total_amount': totalAmount,
      'status': status,
      'date': date.toIso8601String(),
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
      totalAmount: (map['total_amount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'черновик',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
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
    double? totalAmount,
    String? status,
    DateTime? date,
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
      date: date ?? this.date,
    );
  }
}
