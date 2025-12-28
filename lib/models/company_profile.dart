class CompanyProfile {
  int id;
  String name;
  String email;
  String phone;
  String address;
  String website;
  String taxId;
  String logoPath;
  DateTime createdAt;

  CompanyProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.website,
    required this.taxId,
    required this.logoPath,
    required this.createdAt,
  });

  // Метод для удобного обновления полей
  CompanyProfile copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? website,
    String? taxId,
    String? logoPath,
    DateTime? createdAt,
  }) {
    return CompanyProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      website: website ?? this.website,
      taxId: taxId ?? this.taxId,
      logoPath: logoPath ?? this.logoPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'website': website,
      'taxId': taxId,
      'logoPath': logoPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CompanyProfile.fromMap(Map<String, dynamic> map) {
    return CompanyProfile(
      id: map['id'],
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      website: map['website'] ?? '',
      taxId: map['taxId'] ?? '',
      logoPath: map['logoPath'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  @override
  String toString() {
    return 'CompanyProfile(id: $id, name: $name, email: $email, phone: $phone)';
  }
}
