import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/services/position_loader_service.dart';

class QuickAddScreen extends StatefulWidget {
  final Function(List<LineItem>) onPositionsSelected;
  final int quoteId;

  const QuickAddScreen({
    Key? key,
    required this.onPositionsSelected,
    required this.quoteId,
  }) : super(key: key);

  @override
  _QuickAddScreenState createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  List<Map<String, dynamic>> _positions = [];
  List<bool> _selectedPositions = [];
  List<TextEditingController> _quantityControllers = [];

  @override
  void initState() {
    super.initState();
    _loadPositions();
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPositions() async {
    try {
      final positions = await PositionLoaderService.loadAllPositions();
      setState(() {
        _positions = positions;
        _selectedPositions = List.filled(positions.length, false);
        _quantityControllers = positions.map((pos) {
          return TextEditingController(text: '1');
        }).toList();
      });
    } catch (e) {
      print('Ошибка загрузки позиций: $e');
      // В случае ошибки показываем пустой список
      setState(() {
        _positions = [];
        _selectedPositions = [];
        _quantityControllers = [];
      });
    }
  }

  List<LineItem> _getSelectedItems() {
    final List<LineItem> selectedItems = [];
    
    for (int i = 0; i < _positions.length; i++) {
      if (_selectedPositions[i]) {
        final position = _positions[i];
        final quantity = double.tryParse(_quantityControllers[i].text) ?? 1.0;
        
        selectedItems.add(LineItem(
          quoteId: widget.quoteId,
          name: position['name'] ?? '',
          unit: position['unit'] ?? 'шт.',
          price: (position['price'] as num?)?.toDouble() ?? 0.0,
          quantity: quantity,
        ));
      }
    }
    
    return selectedItems;
  }

  void _addSelectedItems() {
    final selectedItems = _getSelectedItems();
    if (selectedItems.isNotEmpty) {
      widget.onPositionsSelected(selectedItems);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одну позицию')),
      );
    }
  }

  void _selectAll(bool selected) {
    setState(() {
      _selectedPositions = List.filled(_positions.length, selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Быстрое добавление позиций'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _addSelectedItems,
            tooltip: 'Добавить выбранные',
          ),
        ],
      ),
      body: _positions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Панель управления
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _selectedPositions.every((selected) => selected),
                            onChanged: (value) => _selectAll(value ?? false),
                          ),
                          const Text('Выбрать все'),
                        ],
                      ),
                      Text('Выбрано: ${_selectedPositions.where((s) => s).length}'),
                    ],
                  ),
                ),
                
                // Список позиций
                Expanded(
                  child: ListView.builder(
                    itemCount: _positions.length,
                    itemBuilder: (context, index) {
                      return _buildPositionItem(index);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPositionItem(int index) {
    final position = _positions[index];
    final price = (position['price'] as num?)?.toDouble() ?? 0.0;
    final unit = position['unit'] ?? 'шт.';
    final description = position['description'] ?? '';
    
    final quantity = double.tryParse(_quantityControllers[index].text) ?? 1.0;
    final total = price * quantity;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: Checkbox(
              value: _selectedPositions[index],
              onChanged: (value) {
                setState(() {
                  _selectedPositions[index] = value ?? false;
                });
              },
            ),
            title: Text(
              position['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: description.isNotEmpty ? Text(description) : null,
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Количество',
                      hintText: 'Введите количество',
                      border: const OutlineInputBorder(),
                      suffixText: unit,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      // Обновляем состояние при изменении количества
                      if (value.isNotEmpty) {
                        setState(() {});
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${NumberFormat.currency(locale: 'ru_RU', symbol: '₽').format(price)}/$unit',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(locale: 'ru_RU', symbol: '₽').format(total),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
