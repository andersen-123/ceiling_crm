import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class QuickAddScreen extends StatefulWidget {
  final Function(List<LineItem>) onItemsSelected;

  const QuickAddScreen({super.key, required this.onItemsSelected});

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  List<LineItem> _selectedItems = [];
  List<LineItem> _templates = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final jsonString = await rootBundle.loadString('assets/standard_positions.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      setState(() {
        _templates = jsonList.map((json) {
          return LineItem(
            quoteId: 0,
            description: json['description'] ?? '',
            quantity: 1.0,
            price: (json['price'] as num?)?.toDouble() ?? 0.0,
            unit: json['unit'] ?? 'шт',
            name: json['name'] ?? '',
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки шаблонов: $e');
      // Запасные шаблоны на случай ошибки
      _loadDefaultTemplates();
    }
  }

  void _loadDefaultTemplates() {
    _templates = [
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
        description: 'Двухуровневый потолок (основа + 1 уровень)',
        quantity: 1.0,
        price: 1650.0,
        unit: 'м²',
        name: 'Двухуровневый',
      ),
    ];
    setState(() {
      _isLoading = false;
    });
  }

  void _toggleItemSelection(LineItem item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item.copyWith());
      }
    });
  }

  void _addSelectedItems() {
    if (_selectedItems.isNotEmpty) {
      widget.onItemsSelected(_selectedItems);
    }
  }

  List<LineItem> _getFilteredTemplates() {
    if (_searchQuery.isEmpty) {
      return _templates;
    }
    final query = _searchQuery.toLowerCase();
    return _templates.where((item) {
      return item.name?.toLowerCase().contains(query) ?? false ||
             item.description.toLowerCase().contains(query);
    }).toList();
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)} ₽';
  }

  Widget _buildTemplateItem(LineItem item, int index) {
    final isSelected = _selectedItems.contains(item);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (_) => _toggleItemSelection(item),
        ),
        title: Text(
          item.name ?? item.description,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.blue[800] : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.description,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatCurrency(item.price)} / ${item.unit}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => _editItem(item, index),
          tooltip: 'Редактировать перед добавлением',
        ),
        onTap: () => _toggleItemSelection(item),
      ),
    );
  }

  void _editItem(LineItem item, int index) {
    final descriptionController = TextEditingController(text: item.description);
    final priceController = TextEditingController(text: item.price.toStringAsFixed(0));
    final quantityController = TextEditingController(text: item.quantity.toStringAsFixed(0));
    final unitController = TextEditingController(text: item.unit);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Редактировать позицию'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Описание'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        decoration: const InputDecoration(labelText: 'Кол-во'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: const InputDecoration(labelText: 'Ед.изм'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Цена (₽)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final editedItem = item.copyWith(
                  description: descriptionController.text,
                  quantity: double.tryParse(quantityController.text) ?? item.quantity,
                  price: double.tryParse(priceController.text) ?? item.price,
                  unit: unitController.text,
                );
                
                // Обновляем в списке шаблонов
                setState(() {
                  _templates[index] = editedItem;
                });
                
                // Если элемент был выбран, обновляем его в выбранных
                final selectedIndex = _selectedItems.indexOf(item);
                if (selectedIndex != -1) {
                  _selectedItems[selectedIndex] = editedItem;
                }
                
                Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTemplates = _getFilteredTemplates();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Быстрое добавление'),
        actions: [
          if (_selectedItems.isNotEmpty)
            TextButton.icon(
              onPressed: _addSelectedItems,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Добавить (${_selectedItems.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Поиск позиций',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Кнопки быстрого выбора
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _buildQuickFilterButton('Все', ''),
                _buildQuickFilterButton('Потолки', 'потолок'),
                _buildQuickFilterButton('Свет', 'свет'),
                _buildQuickFilterButton('Монтаж', 'монтаж'),
                _buildQuickFilterButton('Демонтаж', 'демонтаж'),
              ],
            ),
          ),

          // Список шаблонов
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTemplates.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Позиции не найдены'),
                            Text(
                              'Попробуйте изменить поисковый запрос',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredTemplates.length,
                        itemBuilder: (context, index) {
                          return _buildTemplateItem(filteredTemplates[index], index);
                        },
                      ),
          ),

          // Кнопки действий
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedItems.clear();
                          });
                        },
                        icon: const Icon(Icons.clear_all, size: 20),
                        label: const Text('Сбросить выбор'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedItems.isNotEmpty ? _addSelectedItems : null,
                        icon: const Icon(Icons.add, size: 20),
                        label: Text('Добавить выбранные (${_selectedItems.length})'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Закрыть'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterButton(String label, String filter) {
    final isActive = _searchQuery == filter;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isActive,
        onSelected: (_) {
          setState(() {
            _searchQuery = isActive ? '' : filter;
          });
        },
      ),
    );
  }
}
