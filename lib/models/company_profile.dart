class CompanyProfile {
  final int? id;
  final String companyName;
  final String email;
  final String phone;
  final String address;
  final String inn;
  final String website;
  final String? logoPath;  // ✅ ДОБАВЛЕНО для settings_screen.dart:107

  CompanyProfile({
    this.id,
    required this.companyName,
    this.email = '',
    this.phone = '',
    this.address = '',
    this.inn = '',
    this.website = '',
    this.logoPath,  // ✅ ДОБАВЛЕНО
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'email': email,
      'phone': phone,
      'address': address,
      'inn': inn,
      'website': website,
      'logo_path': logoPath,  // ✅ ДОБАВЛЕНО
    };
  }

  factory CompanyProfile.fromMap(Map<String, dynamic> map) {
    return CompanyProfile(
      id: map['id'] as int?,
      companyName: map['company_name'] ?? 'Моя Компания',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      inn: map['inn'] ?? '',
      website: map['website'] ?? '',
      logoPath: map['logo_path'],  // ✅ ДОБАВЛЕНО
    );
  }

  CompanyProfile copyWith({
    int? id,
    String? companyName,
    String? email,
    String? phone,
    String? address,
    String? inn,
    String? website,
    String? logoPath,
  }) {
    return CompanyProfile(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      inn: inn ?? this.inn,
      website: website ?? this.website,
      logoPath: logoPath ?? this.logoPath,
    );
  }

  // ✅ ДОПОЛНИТЕЛЬНЫЕ МЕТОДЫ ДЛЯ ПОЛНОЙ СОВМЕСТИМОСТИ

  Map<String, dynamic> toJson() => toMap();

  @override
  String toString() {
    return 'CompanyProfile(id: $id, companyName: $companyName, logoPath: $logoPath)';
  }
}
