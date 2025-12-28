import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:ceiling_crm/models/line_item.dart';

class TemplateService {
  static final TemplateService _instance = TemplateService._internal();
  factory TemplateService() => _instance;
  TemplateService._internal();

  List<LineItem> _standardTemplates = [];

  Future<void> loadTemplates() async {
    try {
      final jsonString = await rootBundle.loadString('assets/standard_positions.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      _standardTemplates = jsonList.map((item) {
        return LineItem(
          quoteId: 0, // Будет установлено при добавлении
          name: item['name'] ?? 'Без названия',
          description: item['description'] ?? '',
          unitPrice: (item['price'] as num).toDouble(),
          quantity: 1,
          unit: item['unit'] ?? 'шт.',
        );
      }).toList();
    } catch (e) {
      print('Ошибка загрузки шаблонов из JSON: $e');
      // Если файла нет, загружаем все позиции из кода
      _standardTemplates = _getAllTemplates();
    }
  }

  List<LineItem> getTemplates() {
    if (_standardTemplates.isEmpty) {
      return _getAllTemplates();
    }
    return List.from(_standardTemplates);
  }

  List<LineItem> _getAllTemplates() {
    return [
      LineItem(
        quoteId: 0,
        name: "Полотно MSD Premium белое матовое с установкой",
        description: "Стандартная установка",
        unitPrice: 610.0,
        quantity: 1,
        unit: "м²",
      ),
      LineItem(
        quoteId: 0,
        name: "Профиль стеновой/потолочный гарпунный с установкой",
        description: "Монтаж профиля по периметру",
        unitPrice: 310.0,
        quantity: 1,
        unit: "м.п.",
      ),
      LineItem(
        quoteId: 0,
        name: "Вставка по периметру гарпунная",
        description: "Установка гарпунной вставки",
        unitPrice: 220.0,
        quantity: 1,
        unit: "м.п.",
      ),
      LineItem(
        quoteId: 0,
        name: "Монтаж закладных под световое оборудование, установка светильников",
        description: "Подготовка и установка светильников",
        unitPrice: 780.0,
        quantity: 1,
        unit: "шт.",
      ),
      LineItem(
        quoteId: 0,
        name: "Монтаж закладных под сдвоенное световое оборудование, установка светильников",
        description: "Монтаж двойных светильников",
        unitPrice: 1350.0,
        quantity: 1,
        unit: "шт.",
      ),
      LineItem(
        quoteId: 0,
        name: "Монтаж закладных под люстру",
        description: "Подготовка основания для люстры",
        unitPrice: 1100.0,
        quantity: 1,
        unit: "шт.",
      ),
      LineItem(
        quoteId: 0,
        name: "Монтаж закладной и установка вентелятора",
        description: "Установка вентиляционной системы",
        unitPrice: 1300.0,
        quantity: 1,
        unit: "шт.",
      ),
      LineItem(
        quoteId: 0,
        name: "Монтаж закладной под потолочный карниз",
        description: "Подготовка под карниз",
        unitPrice: 650.0,
        quantity: 1,
        unit: "м.п.",
      ),
      LineItem(
        quoteId: 0,
        name: "Установка потолочного карниза",
        description: "Монтаж карниза",
        unitPrice: 270.0,
        quantity: 1,
        unit: "м.п.",
      ),
      LineItem(
        quoteId: 0,
        name: "Установка разделителей",
        description: "Монтаж разделительных планок",
        unitPrice: 1700.0,
        quantity: 1,
        unit: "м.п.",
      ),
      LineItem(
        quoteId: 0,
        name: "Монтаж закладных под встраеваемые шкафы",
        description: "Подготовка под встроенную мебель",
        unitPrice: 1100.0,
        quantity: 1,
        unit: "м.п.",
      ),
      LineItem(
        quoteId: 0,
        name: "Монтаж шторных карнизов (ПК-15) двухрядный",
        description: "Установка двухрядного карниза",
        unitPrice: 4000.0,
        quantity: 1,
        unit: "м.п.",
      ),
      LineItem(
        quoteId: 0,
        name: "Монтаж шторных карнизов (ПК-5) трехрядный",
        description: "Установка трехрядного карниза",
        unitPrice: 4500.0,
        quantity: 1,
        unit: "м.п.",
      ),
      LineItem(
        quoteId: 0,
        name: "Работы по керамической плитке/керамограниту",
        description: "Работы по плиточным поверхностям",
        unitPrice: 400.0,
        quantity: 1,
        unit: "м.п.",
      ),
      LineItem(
        quoteId: 0,
        name: "Установка вентиляционной решетки",
        description: "Монтаж вентиляционной решетки",
        unitPrice: 600.0,
        quantity: 1,
        unit: "шт.",
      ),
      LineItem(
        quoteId: 0,
        name: "Монтаж \"парящего\" потолка, установка светодиодной ленты",
        description: "Создание парящего потолка с подсветкой",
        unitPrice: 1600.0,
        quantity: 1,
        unit: "м.п.",
      ),
      LineItem(
        quoteId: 0,
        name: "Монтаж потолка системы \"EuroKRAAB\"",
        description: "Установка системы EuroKRAAB",
        unitPrice: 1600.0,
        quantity: 1,
        unit: "м.п.",
      ),
      LineItem(
        quoteId: 0,
        name: "Монтаж световых линий, установка светодиодной ленты",
        description: "Создание световых линий",
        unitPrice: 3400.0,
        quantity: 1,
        unit: "м.п.",
      ),
      LineItem(
        quoteId: 0,
        name: "Монтаж открытой ниши",
        description: "Создание открытой ниши",
        unitPrice: 1200.0,
        quantity: 1,
        unit: "м.п.",
      ),
      LineItem(
        quoteId: 0,
        name: "Монтаж ниши с поворотом полотна",
        description: "Создание ниши с поворотом",
        unitPrice: 3000.0,
        quantity: 1,
        unit: "м.п.",
      ),
      LineItem(
        quoteId: 0,
        name: "Монтаж перехода уровня",
        description: "Оформление перехода между уровнями",
        unitPrice: 3700.0,
        quantity: 1,
        unit: "м.п.",
      ),
      LineItem(
        quoteId: 0,
        name: "Монтаж закладных под трековое освещение (встраиваемые) с установкой",
        description: "Установка встраиваемого трекового освещения",
        unitPrice: 3400.0,
        quantity: 1,
        unit: "м.п.",
      ),
      LineItem(
        quoteId: 0,
        name: "Монтаж закладных под трековое освещение (накладные) с установкой",
        description: "Установка накладного трекового освещения",
        unitPrice: 1100.0,
        quantity: 1,
        unit: "м.п.",
      ),
    ];
  }

  // Метод для поиска шаблонов по названию или описанию
  List<LineItem> searchTemplates(String query) {
    final allTemplates = getTemplates();
    if (query.isEmpty) return allTemplates;
    
    final lowerQuery = query.toLowerCase();
    return allTemplates.where((template) {
      return template.name.toLowerCase().contains(lowerQuery) ||
             template.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Метод для получения шаблонов по категории
  Map<String, List<LineItem>> getTemplatesByCategory() {
    final allTemplates = getTemplates();
    final categories = <String, List<LineItem>>{};
    
    for (var template in allTemplates) {
      final category = _determineCategory(template);
      if (!categories.containsKey(category)) {
        categories[category] = [];
      }
      categories[category]!.add(template);
    }
    
    return categories;
  }

  String _determineCategory(LineItem item) {
    final name = item.name.toLowerCase();
    final description = item.description.toLowerCase();
    
    if (name.contains('полотно') || name.contains('потолок')) {
      return 'Основные работы';
    } else if (name.contains('профиль') || name.contains('вставка')) {
      return 'Профили и крепления';
    } else if (name.contains('свет') || name.contains('люстр') || name.contains('освещени')) {
      return 'Освещение';
    } else if (name.contains('карниз') || name.contains('штора')) {
      return 'Карнизы';
    } else if (name.contains('вентиля') || name.contains('решетк')) {
      return 'Вентиляция';
    } else if (name.contains('ниш') || name.contains('переход') || name.contains('уровен')) {
      return 'Сложные конструкции';
    } else if (name.contains('шкаф') || name.contains('мебель')) {
      return 'Встроенная мебель';
    } else if (name.contains('плитк') || name.contains('керам')) {
      return 'Работы по плитке';
    } else {
      return 'Прочие работы';
    }
  }

  // Метод для получения шаблона по ID
  LineItem? getTemplateById(int index) {
    final templates = getTemplates();
    if (index >= 0 && index < templates.length) {
      return templates[index];
    }
    return null;
  }

  // Метод для обновления шаблона
  void updateTemplate(int index, LineItem newTemplate) {
    final templates = getTemplates();
    if (index >= 0 && index < templates.length) {
      _standardTemplates[index] = newTemplate;
    }
  }

  // Метод для добавления нового шаблона
  void addTemplate(LineItem template) {
    _standardTemplates.add(template);
  }

  // Метод для удаления шаблона
  void removeTemplate(int index) {
    if (index >= 0 && index < _standardTemplates.length) {
      _standardTemplates.removeAt(index);
    }
  }

  // Метод для сброса к стандартным шаблонам
  void resetToDefaults() {
    _standardTemplates = _getAllTemplates();
  }

  // Метод для получения статистики
  Map<String, dynamic> getStatistics() {
    final templates = getTemplates();
    return {
      'totalTemplates': templates.length,
      'averagePrice': _calculateAveragePrice(templates),
      'categories': getTemplatesByCategory().keys.toList(),
    };
  }

  double _calculateAveragePrice(List<LineItem> templates) {
    if (templates.isEmpty) return 0.0;
    final total = templates.fold(0.0, (sum, item) => sum + item.unitPrice);
    return total / templates.length;
  }
}
