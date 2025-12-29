class CompanyProfile {
  final int? id;
  final String companyName;
  final String email;
  final String phone;
  final String address;
  final String inn;
  final String website;

  CompanyProfile({
    this.id,
    required this.companyName,
    this.email = '',
    this.phone = '',
    this.address = '',
    this.inn = '',
    this.website = '',
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
    };
  }

  factory CompanyProfile.fromMap(Map<String, dynamic> map) {
    return CompanyProfile(
      id: map['id'],
      companyName: map['company_name'] ?? 'Моя Компания',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      inn: map['inn'] ?? '',
      website: map['website'] ?? '',
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
  }) {
    return CompanyProfile(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      inn: inn ?? this.inn,
      website: website ?? this.website,
    );
  }
}
