import '../models/estimate.dart';

class EstimateTemplates {
  // Категории как в Excel
  static const List<String> categories = [
    'Материалы',
    'Работы',
    'Оборудование',
    'Доп. работы',
    'Расходы',
    'Прочее',
  ];

  // Единицы измерения как в Excel
  static const List<String> units = [
    'м²',
    'м.п.',
    'шт.',
    'компл.',
    'руб.',
    'час',
  ];

  // Шаблоны позиций для натяжных потолков (как в вашем Excel)
  static final List<EstimateItem> defaultTemplates = [
    // === МАТЕРИАЛЫ ===
    EstimateItem.template(
      name: 'Полотно MSD Premium белое матовое с установкой',
      category: 'Материалы',
      unit: 'м²',
      price: 610.0,
    ),
    EstimateItem.template(
      name: 'Профиль стеновой/потолочный гарпунный с установкой',
      category: 'Материалы',
      unit: 'м.п.',
      price: 310.0,
    ),
    EstimateItem.template(
      name: 'Вставка по периметру гарпунная',
      category: 'Материалы',
      unit: 'м.п.',
      price: 220.0,
    ),

    // === РАБОТЫ ===
    EstimateItem.template(
      name: 'Монтаж закладных под световое оборудование, установка светильников',
      category: 'Работы',
      unit: 'шт.',
      price: 780.0,
    ),
    EstimateItem.template(
      name: 'Монтаж закладных под сдвоенное световое оборудование',
      category: 'Работы',
      unit: 'шт.',
      price: 1350.0,
    ),
    EstimateItem.template(
      name: 'Монтаж закладных под люстру',
      category: 'Работы',
      unit: 'шт.',
      price: 1100.0,
    ),
    EstimateItem.template(
      name: 'Монтаж закладной и установка вентилятора',
      category: 'Работы',
      unit: 'шт.',
      price: 1300.0,
    ),
    EstimateItem.template(
      name: 'Установка потолочного карниза',
      category: 'Работы',
      unit: 'м.п.',
      price: 270.0,
    ),

    // === ДОПОЛНИТЕЛЬНЫЕ РАБОТЫ ===
    EstimateItem.template(
      name: 'Работы по керамической плитке/керамограниту',
      category: 'Доп. работы',
      unit: 'м.п.',
      price: 400.0,
    ),
    EstimateItem.template(
      name: 'Монтаж "парящего" потолка, установка светодиодной ленты',
      category: 'Доп. работы',
      unit: 'м.п.',
      price: 1600.0,
    ),
    EstimateItem.template(
      name: 'Монтаж световых линий, установка светодиодной ленты',
      category: 'Доп. работы',
      unit: 'м.п.',
      price: 3400.0,
    ),
    EstimateItem.template(
      name: 'Монтаж перехода уровня',
      category: 'Доп. работы',
      unit: 'м.п.',
      price: 3700.0,
    ),

    // === ОБОРУДОВАНИЕ ===
    EstimateItem.template(
      name: 'Светильник встраиваемый',
      category: 'Оборудование',
      unit: 'шт.',
      price: 600.0,
    ),
    EstimateItem.template(
      name: 'Вентилятор теневой',
      category: 'Оборудование',
      unit: 'шт.',
      price: 600.0,
    ),

    // === РАСХОДЫ ===
    EstimateItem.template(
      name: 'Бензин',
      category: 'Расходы',
      unit: 'руб.',
      price: 0.0, // Цена будет вводиться вручную
    ),
    EstimateItem.template(
      name: 'Амортизация автомобиля',
      category: 'Расходы',
      unit: 'руб.',
      price: 0.0,
    ),
  ];

  /// Группированные шаблоны по категориям
  static Map<String, List<EstimateItem>> get groupedTemplates {
    final grouped = <String, List<EstimateItem>>{};
    
    for (final template in defaultTemplates) {
      grouped.putIfAbsent(template.category, () => []).add(template);
    }
    
    return grouped;
  }

  /// Поиск шаблонов по названию
  static List<EstimateItem> searchTemplates(String query) {
    if (query.isEmpty) return defaultTemplates;
    
    return defaultTemplates.where((template) {
      return template.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Создаёт новую смету из шаблона
  static Estimate createEstimateFromTemplate({
    required String title,
    int? clientId,
  }) {
    return Estimate(
      clientId: clientId,
      title: title,
      items: [],
      createdAt: DateTime.now(),
    );
  }

  /// Добавляет несколько шаблонов в смету
  static void addTemplatesToEstimate({
    required Estimate estimate,
    required List<EstimateItem> templates,
    Map<EstimateItem, double>? quantities,
  }) {
    for (final template in templates) {
      final quantity = quantities?[template] ?? 1.0;
      estimate.addFromTemplate(template, quantity: quantity);
    }
  }
}
