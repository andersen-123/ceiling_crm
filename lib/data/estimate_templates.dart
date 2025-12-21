import 'package:flutter/material.dart';

class EstimateTemplate {
  final int id;
  final String name;
  final String category;
  final String unit;
  final double price;
  final double? basePrice; // Базовая цена (столбец M)
  final String? description;
  final double minQuantity;
  final bool isRequired;
  final int sortOrder;
  final bool isActive;
  final String? code;
  final String? materialType;

  const EstimateTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    this.basePrice,
    this.description,
    this.minQuantity = 0.0,
    this.isRequired = false,
    this.sortOrder = 0,
    this.isActive = true,
    this.code,
    this.materialType,
  });

  // Метод для расчета с учетом базовой цены и наценки
  double calculateTotal(double quantity, {double markup = 1.1}) {
    final base = basePrice ?? price;
    final finalPrice = base * markup;
    return finalPrice * quantity;
  }

  // Преобразование в Map для БД
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'price': price,
      'base_price': basePrice,
      'description': description,
      'min_quantity': minQuantity,
      'is_required': isRequired ? 1 : 0,
      'sort_order': sortOrder,
      'is_active': isActive ? 1 : 0,
      'code': code,
      'material_type': materialType,
    };
  }

  // Создание из Map (из БД)
  factory EstimateTemplate.fromMap(Map<String, dynamic> map) {
    return EstimateTemplate(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      unit: map['unit'] as String,
      price: map['price'] as double,
      basePrice: map['base_price'] as double?,
      description: map['description'] as String?,
      minQuantity: map['min_quantity'] as double,
      isRequired: map['is_required'] == 1,
      sortOrder: map['sort_order'] as int,
      isActive: map['is_active'] == 1,
      code: map['code'] as String?,
      materialType: map['material_type'] as String?,
    );
  }

  // Полный список всех шаблонов из Excel "Гарпун"
  static List<EstimateTemplate> get allTemplates => [
        // === МАТЕРИАЛЫ (из раздела 1) ===
        EstimateTemplate(
          id: 1,
          name: 'Полотно MSD Premium белое матовое с установкой',
          category: 'Материалы',
          unit: 'м²',
          price: 610.0,
          basePrice: 550.0, // Базовая цена из столбца M
          description: 'ПВХ полотно матовое, гарпунная система',
          minQuantity: 1.0,
          isRequired: true,
          sortOrder: 1,
          code: 'MSD-MAT',
          materialType: 'полотно',
        ),
        EstimateTemplate(
          id: 2,
          name: 'Профиль стеновой/потолочный гарпунный с установкой',
          category: 'Материалы',
          unit: 'м.п.',
          price: 310.0,
          basePrice: 280.0,
          description: 'Алюминиевый профиль для гарпунной системы',
          minQuantity: 1.0,
          isRequired: true,
          sortOrder: 2,
          code: 'PROF-GARP',
          materialType: 'профиль',
        ),
        EstimateTemplate(
          id: 3,
          name: 'Вставка по периметру гарпунная',
          category: 'Материалы',
          unit: 'м.п.',
          price: 220.0,
          basePrice: 200.0,
          description: 'Декоративная вставка для гарпунной системы',
          minQuantity: 1.0,
          sortOrder: 3,
          code: 'VST-GARP',
          materialType: 'вставка',
        ),

        // === РАБОТЫ ПО МОНТАЖУ (из раздела 1) ===
        EstimateTemplate(
          id: 4,
          name: 'Монтаж закладных под световое оборудование, установка светильников',
          category: 'Работы',
          unit: 'шт.',
          price: 780.0,
          basePrice: 700.0,
          description: 'Установка точечных светильников',
          minQuantity: 0.0,
          sortOrder: 4,
          code: 'WORK-LIGHT',
        ),
        EstimateTemplate(
          id: 5,
          name: 'Монтаж закладных под сдвоенное световое оборудование, установка светильников',
          category: 'Работы',
          unit: 'шт.',
          price: 1350.0,
          basePrice: 1200.0,
          description: 'Установка сдвоенных светильников',
          minQuantity: 0.0,
          sortOrder: 5,
          code: 'WORK-LIGHT2',
        ),
        EstimateTemplate(
          id: 6,
          name: 'Монтаж закладных под люстру',
          category: 'Работы',
          unit: 'шт.',
          price: 1100.0,
          basePrice: 900.0,
          description: 'Монтаж крепления для люстры',
          minQuantity: 0.0,
          sortOrder: 6,
          code: 'WORK-LUSTRA',
        ),
        EstimateTemplate(
          id: 7,
          name: 'Монтаж закладной и установка вентилятора',
          category: 'Работы',
          unit: 'шт.',
          price: 1300.0,
          basePrice: 1200.0,
          description: 'Установка вытяжного вентилятора',
          minQuantity: 0.0,
          sortOrder: 7,
          code: 'WORK-FAN',
        ),
        EstimateTemplate(
          id: 8,
          name: 'Монтаж закладной под потолочный карниз',
          category: 'Работы',
          unit: 'м.п.',
          price: 650.0,
          basePrice: 550.0,
          description: 'Подготовка для потолочного карниза',
          minQuantity: 0.0,
          sortOrder: 8,
          code: 'WORK-CORNICE',
        ),
        EstimateTemplate(
          id: 9,
          name: 'Установка потолочного карниза',
          category: 'Работы',
          unit: 'м.п.',
          price: 270.0,
          basePrice: 220.0,
          description: 'Монтаж потолочного карниза',
          minQuantity: 0.0,
          sortOrder: 9,
          code: 'WORK-CORNICE2',
        ),
        EstimateTemplate(
          id: 10,
          name: 'Установка разделителей',
          category: 'Работы',
          unit: 'м.п.',
          price: 1700.0,
          basePrice: 1500.0,
          description: 'Монтаж разделительных профилей',
          minQuantity: 0.0,
          sortOrder: 10,
          code: 'WORK-DIVIDER',
        ),
        EstimateTemplate(
          id: 11,
          name: 'Монтаж закладных под встраиваемые шкафы',
          category: 'Работы',
          unit: 'м.п.',
          price: 1100.0,
          basePrice: 900.0,
          description: 'Подготовка под встроенную мебель',
          minQuantity: 0.0,
          sortOrder: 11,
          code: 'WORK-CABINET',
        ),
        EstimateTemplate(
          id: 12,
          name: 'Монтаж шторных карнизов (ПК-15) двухрядный',
          category: 'Работы',
          unit: 'м.п.',
          price: 4000.0,
          basePrice: 3600.0,
          description: 'Установка двухрядного шторного карниза',
          minQuantity: 0.0,
          sortOrder: 12,
          code: 'WORK-CURTAIN2',
        ),
        EstimateTemplate(
          id: 13,
          name: 'Монтаж шторных карнизов (ПК-5) трехрядный',
          category: 'Работы',
          unit: 'м.п.',
          price: 4500.0,
          basePrice: 4100.0,
          description: 'Установка трехрядного шторного карниза',
          minQuantity: 0.0,
          sortOrder: 13,
          code: 'WORK-CURTAIN3',
        ),
        EstimateTemplate(
          id: 14,
          name: 'Работы по керамической плитке/керамограниту',
          category: 'Работы',
          unit: 'м.п.',
          price: 400.0,
          basePrice: 350.0,
          description: 'Работы на плиточных поверхностях',
          minQuantity: 0.0,
          sortOrder: 14,
          code: 'WORK-TILE',
        ),
        EstimateTemplate(
          id: 15,
          name: 'Установка вентиляционной решетки',
          category: 'Работы',
          unit: 'шт.',
          price: 600.0,
          basePrice: 500.0,
          description: 'Монтаж вентиляционной решетки',
          minQuantity: 0.0,
          sortOrder: 15,
          code: 'WORK-GRILLE',
        ),
        EstimateTemplate(
          id: 16,
          name: 'Монтаж "парящего" потолка, установка светодиодной ленты',
          category: 'Работы',
          unit: 'м.п.',
          price: 1600.0,
          basePrice: 1300.0,
          description: 'Создание эффекта парящего потолка с подсветкой',
          minQuantity: 0.0,
          sortOrder: 16,
          code: 'WORK-FLOATING',
        ),
        EstimateTemplate(
          id: 17,
          name: 'Монтаж потолка системы "EuroKRAAB"',
          category: 'Работы',
          unit: 'м.п.',
          price: 1600.0,
          basePrice: 1300.0,
          description: 'Монтаж системы EuroKRAAB',
          minQuantity: 0.0,
          sortOrder: 17,
          code: 'WORK-EUROKRAAB',
        ),
        EstimateTemplate(
          id: 18,
          name: 'Монтаж световых линий, установка светодиодной ленты',
          category: 'Работы',
          unit: 'м.п.',
          price: 3400.0,
          basePrice: 2800.0,
          description: 'Создание световых линий с LED подсветкой',
          minQuantity: 0.0,
          sortOrder: 18,
          code: 'WORK-LIGHTLINE',
        ),
        EstimateTemplate(
          id: 19,
          name: 'Монтаж открытой ниши',
          category: 'Работы',
          unit: 'м.п.',
          price: 1200.0,
          basePrice: 1000.0,
          description: 'Создание декоративной ниши',
          minQuantity: 0.0,
          sortOrder: 19,
          code: 'WORK-NICHE',
        ),
        EstimateTemplate(
          id: 20,
          name: 'Монтаж ниши с поворотом полотна',
          category: 'Работы',
          unit: 'м.п.',
          price: 3000.0,
          basePrice: 2500.0,
          description: 'Создание ниши с поворотом потолочного полотна',
          minQuantity: 0.0,
          sortOrder: 20,
          code: 'WORK-NICHE-TURN',
        ),
        EstimateTemplate(
          id: 21,
          name: 'Монтаж перехода уровня',
          category: 'Работы',
          unit: 'м.п.',
          price: 3700.0,
          basePrice: 3100.0,
          description: 'Создание многоуровневого потолка',
          minQuantity: 0.0,
          sortOrder: 21,
          code: 'WORK-LEVEL',
        ),
        EstimateTemplate(
          id: 22,
          name: 'Монтаж закладных под трековое освещение (встраиваемые) с установкой',
          category: 'Работы',
          unit: 'м.п.',
          price: 3400.0,
          basePrice: 2800.0,
          description: 'Монтаж трековой системы освещения (встраиваемая)',
          minQuantity: 0.0,
          sortOrder: 22,
          code: 'WORK-TRACK-IN',
        ),
        EstimateTemplate(
          id: 23,
          name: 'Монтаж закладных под трековое освещение (накладные) с установкой',
          category: 'Работы',
          unit: 'м.п.',
          price: 1100.0,
          basePrice: 900.0,
          description: 'Монтаж трековой системы освещения (накладная)',
          minQuantity: 0.0,
          sortOrder: 23,
          code: 'WORK-TRACK-ON',
        ),

        // === ОБОРУДОВАНИЕ (из раздела 2) ===
        EstimateTemplate(
          id: 24,
          name: 'Светильник',
          category: 'Оборудование',
          unit: 'шт.',
          price: 600.0,
          description: 'Точечный светильник',
          minQuantity: 0.0,
          sortOrder: 1,
          code: 'EQUIP-LIGHT',
          materialType: 'светильник',
        ),

        // === ДОПОЛНИТЕЛЬНЫЕ УСЛУГИ ===
        EstimateTemplate(
          id: 25,
          name: 'Доставка материалов',
          category: 'Дополнительно',
          unit: 'рейс',
          price: 1500.0,
          description: 'Доставка материалов на объект',
          minQuantity: 0.0,
          sortOrder: 1,
          code: 'ADD-DELIVERY',
        ),
        EstimateTemplate(
          id: 26,
          name: 'Выезд замерщика',
          category: 'Дополнительно',
          unit: 'выезд',
          price: 0.0,
          description: 'Бесплатный выезд замерщика',
          minQuantity: 0.0,
          sortOrder: 2,
          code: 'ADD-MEASURE',
        ),
        EstimateTemplate(
          id: 27,
          name: 'Уборка после монтажа',
          category: 'Дополнительно',
          unit: 'объект',
          price: 1000.0,
          description: 'Уборка строительного мусора',
          minQuantity: 0.0,
          sortOrder: 3,
          code: 'ADD-CLEANING',
        ),
        EstimateTemplate(
          id: 28,
          name: 'Гарантийное обслуживание',
          category: 'Дополнительно',
          unit: 'год',
          price: 500.0,
          description: 'Расширенная гарантия 3 года',
          minQuantity: 0.0,
          sortOrder: 4,
          code: 'ADD-WARRANTY',
        ),
      ];

  // Группировка по категориям (только активные)
  static Map<String, List<EstimateTemplate>> get groupedByCategory {
    final map = <String, List<EstimateTemplate>>{};
    for (var template in allTemplates.where((t) => t.isActive)) {
      map.putIfAbsent(template.category, () => []).add(template);
    }
    // Сортируем по sortOrder внутри каждой категории
    for (var list in map.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return map;
  }

  // Поиск по имени
  static EstimateTemplate? findByName(String name) {
    return allTemplates.firstWhere(
      (template) => template.name.toLowerCase().contains(name.toLowerCase()),
      orElse: () => allTemplates.firstWhere(
        (t) => t.name.toLowerCase().contains(name.split(' ').first.toLowerCase()),
        orElse: () => allTemplates[0],
      ),
    );
  }

  // Получение обязательных позиций (материалы)
  static List<EstimateTemplate> get requiredTemplates {
    return allTemplates.where((t) => t.isRequired && t.isActive).toList();
  }

  // Фильтрация по категории
  static List<EstimateTemplate> getByCategory(String category) {
    return allTemplates.where((t) => t.category == category && t.isActive).toList();
  }

  // Получение материалов (для автоматического расчета)
  static List<EstimateTemplate> get materialTemplates {
    return allTemplates.where((t) => t.category == 'Материалы' && t.isActive).toList();
  }

  // Получение работ
  static List<EstimateTemplate> get workTemplates {
    return allTemplates.where((t) => t.category == 'Работы' && t.isActive).toList();
  }

  // Получение оборудования
  static List<EstimateTemplate> get equipmentTemplates {
    return allTemplates.where((t) => t.category == 'Оборудование' && t.isActive).toList();
  }

  // Получение дополнительных услуг
  static List<EstimateTemplate> get additionalTemplates {
    return allTemplates.where((t) => t.category == 'Дополнительно' && t.isActive).toList();
  }
}

// Цвета категорий для UI
const Map<String, Color> categoryColors = {
  'Материалы': Color(0xFF4CAF50), // Зеленый
  'Работы': Color(0xFF2196F3),    // Синий
  'Оборудование': Color(0xFFFF9800), // Оранжевый
  'Дополнительно': Color(0xFF9C27B0), // Фиолетовый
};
