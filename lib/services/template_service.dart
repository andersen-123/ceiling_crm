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
          unitPrice: (item['unitPrice'] as num).toDouble(),
          quantity: item['quantity'] ?? 1,
          unit: item['unit'] ?? 'шт.',
        );
      }).toList();
    } catch (e) {
      // Если файла нет, создаем стандартные шаблоны
      _standardTemplates = _getDefaultTemplates();
    }
  }

  List<LineItem> getTemplates() {
    return List.from(_standardTemplates);
  }

  List<LineItem> _getDefaultTemplates() {
    return [
      LineItem(
        quoteId: 0,
        name: 'Натяжной потолок (стандарт)',
        description: 'Монтаж натяжного потолка',
        unitPrice: 1500.0,
        quantity: 1,
        unit: 'м²',
      ),
      LineItem(
        quoteId: 0,
        name: 'Точечный светильник',
        description: 'Установка светильника',
        unitPrice: 800.0,
        quantity: 1,
        unit: 'шт.',
      ),
      LineItem(
        quoteId: 0,
        name: 'Люстра',
        description: 'Установка люстры',
        unitPrice: 1200.0,
        quantity: 1,
        unit: 'шт.',
      ),
      LineItem(
        quoteId: 0,
        name: 'Обвод трубы',
        description: 'Гарпунная технология',
        unitPrice: 500.0,
        quantity: 1,
        unit: 'шт.',
      ),
      LineItem(
        quoteId: 0,
        name: 'Демонтаж старого потолка',
        description: 'Демонтажные работы',
        unitPrice: 200.0,
        quantity: 1,
        unit: 'м²',
      ),
    ];
  }
}
