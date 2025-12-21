import 'package:flutter/material.dart';
import '../models/estimate.dart';
import '../models/estimate_item.dart';
import '../database/database_helper.dart';
import '../data/estimate_templates.dart';
import 'estimate_edit_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _lengthController = TextEditingController(text: '4.0');
  final TextEditingController _widthController = TextEditingController(text: '3.0');
  final TextEditingController _heightController = TextEditingController(text: '2.5');

  int _lightCount = 0;
  int _doubleLightCount = 0;
  int _chandelierCount = 0;
  int _fanCount = 0;

  bool _hasInsert = true;
  bool _hasFloatingCeiling = false;
  bool _hasLightLine = false;
  bool _hasCornice = false;
  double _corniceLength = 0.0;
  bool _hasDelivery = true;
  bool _hasCleaning = false;

  EstimateTemplate _findTemplate(List<EstimateTemplate> list, int id) {
    return list.firstWhere(
      (t) => t.id == id,
      orElse: () => _getDefaultTemplate(id),
    );
  }

  EstimateTemplate _getDefaultTemplate(int id) {
    final defaults = {
      1: EstimateTemplate(id: 1, name: 'Полотно MSD Premium белое матовое с установкой', category: 'Материалы', unit: 'м²', price: 610),
      2: EstimateTemplate(id: 2, name: 'Профиль гарпунный с установкой', category: 'Материалы', unit: 'м.п.', price: 310),
      3: EstimateTemplate(id: 3, name: 'Вставка по периметру гарпунная', category: 'Материалы', unit: 'м.п.', price: 220),
      4: EstimateTemplate(id: 4, name: 'Монтаж светильников', category: 'Работы', unit: 'шт.', price: 780),
      5: EstimateTemplate(id: 5, name: 'Монтаж сдвоенных светильников', category: 'Работы', unit: 'шт.', price: 1350),
      6: EstimateTemplate(id: 6, name: 'Монтаж люстры', category: 'Работы', unit: 'шт.', price: 1100),
      7: EstimateTemplate(id: 7, name: 'Монтаж вентилятора', category: 'Работы', unit: 'шт.', price: 1300),
      8: EstimateTemplate(id: 8, name: 'Монтаж потолочного карниза', category: 'Работы', unit: 'м.п.', price: 650),
      16: EstimateTemplate(id: 16, name: 'Парящий потолок с LED', category: 'Работы', unit: 'м.п.', price: 1600),
      18: EstimateTemplate(id: 18, name: 'Световые линии с LED', category: 'Работы', unit: 'м.п.', price: 3400),
      24: EstimateTemplate(id: 24, name: 'Светильник', category: 'Оборудование', unit: 'шт.', price: 600),
      25: EstimateTemplate(id: 25, name: 'Доставка материалов', category: 'Дополнительно', unit: 'рейс', price: 1500),
      27: EstimateTemplate(id: 27, name: 'Уборка после монтажа', category: 'Дополнительно', unit: 'объект', price: 1000),
    };

    return defaults[id] ??
        EstimateTemplate(id: id, name: 'Шаблон $id', category: 'Другое', unit: 'шт.', price: 0);
  }

  double get _area {
    final l = double.tryParse(_lengthController.text.replaceAll(',', '.')) ?? 0.0;
    final w = double.tryParse(_widthController.text.replaceAll(',', '.')) ?? 0.0;
    return l * w;
  }

  double get _perimeter {
    final l = double.tryParse(_lengthController.text.replaceAll(',', '.')) ?? 0.0;
    final w = double.tryParse(_widthController.text.replaceAll(',', '.')) ?? 0.0;
    return 2 * (l + w);
  }

  List<EstimateItem> get _selectedItems {
    final items = <EstimateItem>[];

    items.add(EstimateItem(name: 'Полотно MSD Premium', unit: 'м²', price: 610, quantity: _area));
    items.add(EstimateItem(name: 'Профиль гарпунный', unit: 'м.п.', price: 310, quantity: _perimeter));

    if (_hasInsert) {
      items.add(EstimateItem(name: 'Вставка по периметру', unit: 'м.п.', price: 220, quantity: _perimeter));
    }

    if (_lightCount > 0) {
      items.add(EstimateItem(name: 'Монтаж светильников', unit: 'шт.', price: 780, quantity: _lightCount.toDouble()));
      items.add(EstimateItem(name: 'Светильники', unit: 'шт.', price: 600, quantity: _lightCount.toDouble()));
    }

    if (_doubleLightCount > 0) {
      items.add(EstimateItem(name: 'Монтаж сдвоенных светильников', unit: 'шт.', price: 1350, quantity: _doubleLightCount.toDouble()));
    }

    if (_chandelierCount > 0) {
      items.add(EstimateItem(name: 'Монтаж люстр', unit: 'шт.', price: 1100, quantity: _chandelierCount.toDouble()));
    }

    if (_fanCount > 0) {
      items.add(EstimateItem(name: 'Монтаж вентиляторов', unit: 'шт.', price: 1300, quantity: _fanCount.toDouble()));
    }

    if (_hasFloatingCeiling) {
      items.add(EstimateItem(name: 'Парящий потолок', unit: 'м.п.', price: 1600, quantity: _perimeter));
    }

    if (_hasLightLine) {
      items.add(EstimateItem(name: 'Световые линии', unit: 'м.п.', price: 3400, quantity: _perimeter));
    }

    if (_hasCornice && _corniceLength > 0) {
      items.add(EstimateItem(name: 'Карниз', unit: 'м.п.', price: 650, quantity: _corniceLength));
    }

    if (_hasDelivery) {
      items.add(EstimateItem(name: 'Доставка', unit: 'рейс', price: 1500, quantity: 1));
    }

    if (_hasCleaning) {
      items.add(EstimateItem(name: 'Уборка', unit: 'объект', price: 1000, quantity: 1));
    }

    return items;
  }

  double get _totalCost =>
      _selectedItems.fold(0.0, (sum, item) => sum + item.total);

  @override
  Widget build(BuildContext context) {
    final pricePerM2 = _area > 0 ? _totalCost / _area : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Калькулятор натяжного потолка')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow('Площадь:', '${_area.toStringAsFixed(2)} м²'),
            _buildInfoRow('Периметр:', '${_perimeter.toStringAsFixed(2)} м.п.'),
            _buildInfoRow('Итого:', '${_totalCost.toStringAsFixed(2)} ₽'),
            _buildInfoRow('Цена за м²:', '${pricePerM2.toStringAsFixed(2)} ₽'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Сохранить смету'),
              onPressed: _saveEstimate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _saveEstimate() async {
    if (_area <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректные размеры')),
      );
      return;
    }

    final estimate = Estimate(
      id: null,
      title: 'Потолок ${_area.toStringAsFixed(1)} м²',
      description: 'Расчёт из калькулятора',
      totalPrice: _totalCost,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final db = await DatabaseHelper.instance.database;
    final estimateId = await db.insert('estimates', estimate.toMap());

    for (final item in _selectedItems) {
      await db.insert('estimate_items', {
        'estimate_id': estimateId,
        'name': item.name,
        'unit': item.unit,
        'price': item.price,
        'quantity': item.quantity,
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EstimateEditScreen(
          existingEstimate: Estimate(
            id: estimateId,
            title: estimate.title,
            description: estimate.description,
            totalPrice: estimate.totalPrice,
            createdAt: estimate.createdAt,
            updatedAt: estimate.updatedAt,
          ),
        ),
      ),
    );
  }
}
