import 'package:ceiling_crm/models/estimate.dart';
import 'package:ceiling_crm/models/estimate_item.dart';

class EstimateTemplates {
  static final List<EstimateItem> defaultTemplates = [
    EstimateItem.template(
      name: 'Гипсокартон KNAUF 9.5мм',
      category: 'Материалы',
      unit: 'лист',
      price: 350.0,
    ),
    EstimateItem.template(
      name: 'Профиль CD 60x27',
      category: 'Материалы',
      unit: 'м',
      price: 45.0,
    ),
    EstimateItem.template(
      name: 'Профиль UD 28x27',
      category: 'Материалы',
      unit: 'м',
      price: 42.0,
    ),
    EstimateItem.template(
      name: 'Подвес прямой',
      category: 'Крепеж',
      unit: 'шт',
      price: 8.0,
    ),
    EstimateItem.template(
      name: 'Саморезы по металлу 3.5x25',
      category: 'Крепеж',
      unit: 'уп',
      price: 120.0,
    ),
    EstimateItem.template(
      name: 'Дюбель-гвоздь 6x40',
      category: 'Крепеж',
      unit: 'уп',
      price: 180.0,
    ),
    EstimateItem.template(
      name: 'Краб одноуровневый',
      category: 'Крепеж',
      unit: 'шт',
      price: 12.0,
    ),
    EstimateItem.template(
      name: 'Удлинитель профиля',
      category: 'Крепеж',
      unit: 'шт',
      price: 15.0,
    ),
    EstimateItem.template(
      name: 'Грунтовка глубокого проникновения',
      category: 'Отделочные материалы',
      unit: 'л',
      price: 85.0,
    ),
    EstimateItem.template(
      name: 'Шпаклевка финишная',
      category: 'Отделочные материалы',
      unit: 'кг',
      price: 65.0,
    ),
    EstimateItem.template(
      name: 'Лента армирующая',
      category: 'Отделочные материалы',
      unit: 'м',
      price: 8.0,
    ),
    EstimateItem.template(
      name: 'Уголок перфорированный',
      category: 'Отделочные материалы',
      unit: 'м',
      price: 25.0,
    ),
    EstimateItem.template(
      name: 'Монтаж каркаса одноуровневого потолка',
      category: 'Работы',
      unit: 'м²',
      price: 450.0,
    ),
    EstimateItem.template(
      name: 'Обшивка гипсокартоном',
      category: 'Работы',
      unit: 'м²',
      price: 300.0,
    ),
    EstimateItem.template(
      name: 'Вывоз мусора',
      category: 'Дополнительные услуги',
      unit: 'м³',
      price: 500.0,
    ),
    EstimateItem.template(
      name: 'Доставка материалов',
      category: 'Дополнительные услуги',
      unit: 'рейс',
      price: 1500.0,
    ),
  ];

  static Map<String, List<EstimateItem>> get groupedTemplates {
    final grouped = <String, List<EstimateItem>>{};
    for (var template in defaultTemplates) {
      if (!grouped.containsKey(template.category)) {
        grouped[template.category] = [];
      }
      grouped[template.category]!.add(template);
    }
    return grouped;
  }

  static List<EstimateItem> searchTemplates(String query) {
    if (query.isEmpty) return defaultTemplates;
    return defaultTemplates.where((template) {
      return template.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  static Estimate createFromTemplate({
    required String clientName,
    required String address,
    required double area,
    required List<EstimateItem> templates,
    Map<EstimateItem, double>? quantities,
  }) {
    return Estimate(
      clientName: clientName,
      address: address,
      area: area,
      perimeter: 0.0,
      pricePerMeter: 0.0,
      totalPrice: 0.0,
      createdDate: DateTime.now(),
      items: templates.map((template) {
        final quantity = quantities?[template] ?? 1.0;
        return EstimateItem(
          name: template.name,
          category: template.category,
          quantity: quantity,
          unit: template.unit,
          price: template.price,
          description: template.description,
        );
      }).toList(),
    );
  }
}
