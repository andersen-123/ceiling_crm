import 'dart:convert';

class CompanyProfile {
  int? id;
  String companyName;
  String? phone;
  String? email;
  String? address;
  String? managerName;
  String? position;
  String? vatNumber;
  String? logoPath;

  CompanyProfile({
    this.id,
    required this.companyName,
    this.phone,
    this.email,
    this.address,
    this.managerName,
    this.position,
    this.vatNumber,
    this.logoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'phone': phone,
      'email': email,
      'address': address,
      'manager_name': managerName,
      'position': position,
      'vat_number': vatNumber,
      'logo_path': logoPath,
    };
  }

  factory CompanyProfile.fromMap(Map<String, dynamic> map) {
    return CompanyProfile(
      id: map['id'],
      companyName: map['company_name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      managerName: map['manager_name'],
      position: map['position'],
      vatNumber: map['vat_number'],
      logoPath: map['logo_path'],
    );
  }

  String toJson() => json.encode(toMap());

  factory CompanyProfile.fromJson(String source) => CompanyProfile.fromMap(json.decode(source));

  CompanyProfile copyWith({
    int? id,
    String? companyName,
    String? phone,
    String? email,
    String? address,
    String? managerName,
    String? position,
    String? vatNumber,
    String? logoPath,
  }) {
    return CompanyProfile(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      managerName: managerName ?? this.managerName,
      position: position ?? this.position,
      vatNumber: vatNumber ?? this.vatNumber,
      logoPath: logoPath ?? this.logoPath,
    );
  }
}
