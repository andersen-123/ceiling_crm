class Client {
  int? id;
  final String name;
  final String phone;
  final String? objectAddress;
  final String? notes;
  final DateTime createdAt;

  Client({
    this.id,
    required this.name,
    required this.phone,
    this.objectAddress,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'object_address': objectAddress,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      objectAddress: map['object_address'],
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Client copyWith({
    int? id,
    String? name,
    String? phone,
    String? objectAddress,
    String? notes,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      objectAddress: objectAddress ?? this.objectAddress,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
