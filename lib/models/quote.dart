class Quote {
  int? id;
  String clientName;
  String? address;
  String? phone;
  String? email;
  double totalAmount;
  DateTime createdAt;
  DateTime updatedAt;

  Quote({
    this.id,
    required this.clientName,
    this.address,
    this.phone,
    this.email,
    this.totalAmount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_name': clientName,
      'address': address,
      'phone': phone,
      'email': email,
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Quote.fromMap(Map<String, dynamic> map) {
    return Quote(
      id: map['id'],
      clientName: map['client_name'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      totalAmount: map['total_amount'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
