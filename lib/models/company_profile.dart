class CompanyProfile {
  final int? id;
  final String companyName; // Основное название компании (вместо name)
  final String managerName;
  final String position;
  final String? phone;
  final String? email;
  final String? address;
  final String? website; // Добавляем поле
  final double vatRate; // Добавляем поле
  final double defaultMargin; // Добавляем поле
  final String currency; // Добавляем поле

  CompanyProfile({
    this.id,
    required this.companyName,
    required this.managerName,
    required this.position,
    this.phone,
    this.email,
    this.address,
    this.website,
    this.vatRate = 0.0,
    this.defaultMargin = 0.0,
    this.currency = '₽',
  });

  // Фабричный конструктор для создания объекта из Map (из БД)
  factory CompanyProfile.fromMap(Map<String, dynamic> map) {
    return CompanyProfile(
      id: map['id'] as int?,
      companyName: map['company_name'] ?? '',
      managerName: map['manager_name'] ?? '',
      position: map['position'] ?? '',
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      website: map['website'],
      vatRate: (map['vat_rate'] as num?)?.toDouble() ?? 0.0,
      defaultMargin: (map['default_margin'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? '₽',
    );
  }

  // Метод для преобразования объекта в Map (для сохранения в БД)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'company_name': companyName,
      'manager_name': managerName,
      'position': position,
      'phone': phone,
      'email': email,
      'address': address,
      'website': website,
      'vat_rate': vatRate,
      'default_margin': defaultMargin,
      'currency': currency,
    };
  }

  // Метод для создания копии с изменениями
  CompanyProfile copyWith({
    int? id,
    String? companyName,
    String? managerName,
    String? position,
    String? phone,
    String? email,
    String? address,
    String? website,
    double? vatRate,
    double? defaultMargin,
    String? currency,
  }) {
    return CompanyProfile(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      managerName: managerName ?? this.managerName,
      position: position ?? this.position,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      website: website ?? this.website,
      vatRate: vatRate ?? this.vatRate,
      defaultMargin: defaultMargin ?? this.defaultMargin,
      currency: currency ?? this.currency,
    );
  }

  // Статический метод для получения профиля по умолчанию
  static CompanyProfile defaultProfile() {
    return CompanyProfile(
      companyName: 'PotolokForLife',
      managerName: '',
      position: 'Менеджер',
      phone: '8(977)5311099',
      email: 'potolokforlife@yandex.ru',
      address: 'Пушкино',
      website: '',
      vatRate: 0.0,
      defaultMargin: 0.0,
      currency: '₽',
    );
  }
}
