class CompanyProfile {
  String name;
  String phone;
  String email;
  String address;
  String? website;
  String? logoPath;
  double vatRate;
  double defaultMargin;
  String currency;
  
  CompanyProfile({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.website,
    this.logoPath,
    this.vatRate = 20.0,
    this.defaultMargin = 30.0,
    this.currency = '₽',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'website': website,
      'logo_path': logoPath,
      'vat_rate': vatRate,
      'default_margin': defaultMargin,
      'currency': currency,
    };
  }

  factory CompanyProfile.fromMap(Map<String, dynamic> map) {
    return CompanyProfile(
      name: map['name'] ?? 'Моя Компания',
      phone: map['phone'] ?? '+7 (999) 123-45-67',
      email: map['email'] ?? 'info@company.ru',
      address: map['address'] ?? 'г. Москва, ул. Примерная, д. 1',
      website: map['website'],
      logoPath: map['logo_path'],
      vatRate: map['vat_rate']?.toDouble() ?? 20.0,
      defaultMargin: map['default_margin']?.toDouble() ?? 30.0,
      currency: map['currency'] ?? '₽',
    );
  }

  @override
  String toString() {
    return 'CompanyProfile(name: $name, vat: $vatRate%, margin: $defaultMargin%)';
  }

  CompanyProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? website,
    String? logoPath,
    double? vatRate,
    double? defaultMargin,
    String? currency,
  }) {
    return CompanyProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      website: website ?? this.website,
      logoPath: logoPath ?? this.logoPath,
      vatRate: vatRate ?? this.vatRate,
      defaultMargin: defaultMargin ?? this.defaultMargin,
      currency: currency ?? this.currency,
    );
  }

  // Стандартный профиль по умолчанию
  static CompanyProfile get defaultProfile {
    return CompanyProfile(
      name: 'Моя Компания',
      phone: '+7 (999) 123-45-67',
      email: 'info@company.ru',
      address: 'г. Москва, ул. Примерная, д. 1',
      vatRate: 20.0,
      defaultMargin: 30.0,
      currency: '₽',
    );
  }
}
