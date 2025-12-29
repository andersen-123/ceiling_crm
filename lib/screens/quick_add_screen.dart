import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/line_item.dart';

class QuickAddScreen extends StatefulWidget {
  final Function(List<LineItem>) onItemsSelected;

  const QuickAddScreen({super.key, required this.onItemsSelected});

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  final List<LineItem> _selectedItems = [];
  
  // ПРОСТЫЕ ШАБЛОНЫ
  final List<LineItem> _templates = [
    LineItem(
      quoteId: 0,
      description: 'Натяжной потолок ПВХ глянцевый (Германия)',
      quantity: 1.0,
      price: 610.0,
      unit: 'м²',
      name: 'Потолок глянцевый',
    ),
    LineItem(
      quoteId: 0,
      description: 'Натяжной потолок ПВХ матовый (Германия)',
      quantity: 1.0,
      price: 610.0,
      unit: 'м²',
      name: 'Потолок матовый',
    ),
    LineItem(
      quoteId: 0,
      description: 'Натяжной потолок ПВХ сатиновый (Германия)',
      quantity: 1.0,
      price: 680.0,
      unit: 'м²',
      name: 'Потолок сатиновый',
    ),
    LineItem(
      quoteId: 0,
      description: 'Точечный светильник LED (хром)',
      quantity: 1.0,
      price: 450.0,
      unit: 'шт',
      name: 'Светильник LED',
    ),
    LineItem(
      quoteId: 0,
      description: 'Монтаж светильника (проход через полотно)',
      quantity: 1.0,
      price: 300.0,
      unit: 'шт',
      name: 'Монтаж светильника',
    ),
  ];

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedItems.contains(_templates[index])) {
        _selectedItems.remove(_templates[index]);
      } else {
        _selectedItems.add(_templates[index]);
      }
    });
  }

  void _addSelected() {
    if (_selectedItems.isNotEmpty) {
      widget.onItemsSelected(_selectedItems);
    }
  }

  Widget _buildTemplateItem(int index) {
    final item = _templates[index];
    final isSelected = _selectedItems.contains(item);
    
    return ListTile(
      leading: Checkbox(
        value: isSelected,
        onChanged: (_) => _toggleSelection(index),
      ),
      title: Text(item.name ?? 'Позиция'),
      subtitle: Text('${item.price} ₽ / ${item.unit}'),
      trailing: Text(item.description, style: const TextStyle(fontSize: 12)),
      onTap: () => _toggleSelection(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Быстрое добавление'),
        actions: [
          if (_selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addSelected,
              tooltip: 'Добавить выбранные',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Выберите позиции:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _templates.length,
              itemBuilder: (context, index) => _buildTemplateItem(index),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedItems.isNotEmpty ? _addSelected : null,
                    child: Text('Добавить (${_selectedItems.length})'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
