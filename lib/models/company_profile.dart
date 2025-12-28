class CompanyProfile {
  int? id;
  String companyName;
  String? address;
  String? phone;
  String? email;
  String? website;
  String? bankDetails;
  String? directorName;

  CompanyProfile({
    this.id,
    required this.companyName,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.bankDetails,
    this.directorName,
  });

  factory CompanyProfile.defaultProfile() {
    return CompanyProfile(
      companyName: 'ООО "Натяжные Потолки"',
      address: 'г. Москва, ул. Примерная, д. 1',
      phone: '+7 (999) 123-45-67',
      email: 'info@potolki.ru',
      website: 'www.potolki.ru',
      bankDetails: 'Банк: Тинькофф\nР/с: 40702810500000000001\nК/с: 30101810100000000741\nБИК: 044525974',
      directorName: 'Иванов И.И.',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyName': companyName,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'bankDetails': bankDetails,
      'directorName': directorName,
    };
  }

  factory CompanyProfile.fromMap(Map<String, dynamic> map) {
    return CompanyProfile(
      id: map['id'],
      companyName: map['companyName'] ?? '',
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
      bankDetails: map['bankDetails'],
      directorName: map['directorName'],
    );
  }
}
