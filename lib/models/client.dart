
class Client {
  int? id; // Будет null, пока не сохранен в БД
  final String name;
  final String phone;
  final String? objectAddress; // Адрес объекта (например, "Нежинская 1к2")
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

  // Преобразование в Map для сохранения в базу данных (sqflite)
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

  // Создание объекта Client из Map (при чтении из базы данных)
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
}
