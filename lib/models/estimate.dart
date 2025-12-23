class Estimate {
  final int? id;
  final String? name; // Добавьте это поле
  final String clientName;
  final String address;
  final double area;
  final double perimeter;
  final double pricePerMeter;
  final double totalPrice;
  final DateTime createdDate;
  final String? notes;

  Estimate({
    this.id,
    this.name,
    required this.clientName,
    required this.address,
    required this.area,
    required this.perimeter,
    required this.pricePerMeter,
    required this.totalPrice,
    required this.createdDate,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clientName': clientName,
      'address': address,
      'area': area,
      'perimeter': perimeter,
      'pricePerMeter': pricePerMeter,
      'totalPrice': totalPrice,
      'createdDate': createdDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory Estimate.fromMap(Map<String, dynamic> map) {
    return Estimate(
      id: map['id'],
      name: map['name'],
      clientName: map['clientName'],
      address: map['address'],
      area: map['area'],
      perimeter: map['perimeter'],
      pricePerMeter: map['pricePerMeter'],
      totalPrice: map['totalPrice'],
      createdDate: DateTime.parse(map['createdDate']),
      notes: map['notes'],
    );
  }

  // Для отладки
  @override
  String toString() {
    return 'Estimate{id: $id, name: $name, clientName: $clientName, address: $address, area: $area, totalPrice: $totalPrice}';
  }

  // Копировать с изменениями
  Estimate copyWith({
    int? id,
    String? name,
    String? clientName,
    String? address,
    double? area,
    double? perimeter,
    double? pricePerMeter,
    double? totalPrice,
    DateTime? createdDate,
    String? notes,
  }) {
    return Estimate(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      address: address ?? this.address,
      area: area ?? this.area,
      perimeter: perimeter ?? this.perimeter,
      pricePerMeter: pricePerMeter ?? this.pricePerMeter,
      totalPrice: totalPrice ?? this.totalPrice,
      createdDate: createdDate ?? this.createdDate,
      notes: notes ?? this.notes,
    );
  }
}
