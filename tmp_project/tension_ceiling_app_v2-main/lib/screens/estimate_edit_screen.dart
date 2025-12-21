import 'package:flutter/material.dart';
import '../models/estimate.dart';
import '../models/estimate_item.dart';
import '../database/database_helper.dart';
import '../data/estimate_templates.dart';

class EstimateEditScreen extends StatefulWidget {
  final Estimate? existingEstimate;
  const EstimateEditScreen({super.key, this.existingEstimate});

  @override
  State<EstimateEditScreen> createState() => _EstimateEditScreenState();
}

class _EstimateEditScreenState extends State<EstimateEditScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedTemplateName;
  final _newItemQuantityController = TextEditingController(text: '1.0');
  final _newItemUnitController = TextEditingController();
  final _newItemPriceController = TextEditingController();
  List<EstimateItem> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingEstimate != null) {
      final estimate = widget.existingEstimate!;
      _titleController.text = estimate.title;
      _descriptionController.text = estimate.description ?? '';
      
      // Загружаем позиции сметы из базы данных
      _loadEstimateItems(estimate.id!);
    }
  }

  // Загрузка позиций сметы из БД
  Future<void> _loadEstimateItems(int estimateId) async {
    setState(() => _isLoading = true);
    
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Загружаем позиции из таблицы estimate_items
      final List<Map<String, dynamic>> maps = await db.query(
        'estimate_items',
        where: 'estimate_id = ?',
        whereArgs: [estimateId],
        orderBy: 'id ASC',
      );
      
      setState(() {
        _items = List.generate(maps.length, (index) {
          final map = maps[index];
          return EstimateItem(
            name: map['name'] as String,
            unit: map['unit'] as String,
            price: map['price'] as double,
            quantity: map['quantity'] as double,
          );
        });
        _isLoading = false;
      });
      
      print('✅ Загружено ${_items.length} позиций для сметы ID: $estimateId');
      
    } catch (error) {
      setState(() => _isLoading = false);
      print('❌ Ошибка загрузки позиций: $error');
    }
  }

  // Сохранение позиций сметы в БД
  Future<void> _saveEstimateItems(int estimateId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Удаляем старые позиции
      await db.delete(
        'estimate_items',
        where: 'estimate_id = ?',
        whereArgs: [estimateId],
      );
      
      // Сохраняем новые позиции
      for (var item in _items) {
        await db.insert('estimate_items', {
          'estimate_id': estimateId,
          'name': item.name,
          'unit': item.unit,
          'price': item.price,
          'quantity': item.quantity,
        });
      }
      
      print('✅ Сохранено ${_items.length} позиций для сметы ID: $estimateId');
      
    } catch (error) {
      print('❌ Ошибка сохранения позиций: $error');
      rethrow;
    }
  }

  void _updatePriceAndUnit(String? templateName) {
    if (templateName != null && templateName.isNotEmpty) {
      final template = EstimateTemplate.findByName(templateName);
      if (template != null) {
        _newItemUnitController.text = template.unit;
        _newItemPriceController.text = template.price.toStringAsFixed(2);
        setState(() {
          _selectedTemplateName = templateName;
        });
      }
    } else {
      setState(() {
        _selectedTemplateName = null;
        _newItemUnitController.clear();
        _newItemPriceController.clear();
      });
    }
  }

  void _addNewItem() {
    final templateName = _selectedTemplateName;
    final quantityText = _newItemQuantityController.text.replaceAll(',', '.');
    final priceText = _newItemPriceController.text.replaceAll(',', '.');
    
    if (templateName == null || templateName.isEmpty) {
      _showSnackBar('Выберите позицию из списка');
      return;
    }
    
    final template = EstimateTemplate.findByName(templateName);
    if (template == null) {
      _showSnackBar('Ошибка: шаблон не найден');
      return;
    }
    
    final quantity = double.tryParse(quantityText) ?? 1.0;
    final price = double.tryParse(priceText) ?? template.price;
    
    if (quantity <= 0) {
      _showSnackBar('Количество должно быть больше 0');
      return;
    }
    
    if (price <= 0) {
      _showSnackBar('Цена должна быть больше 0');
      return;
    }
    
    setState(() {
      _items.add(EstimateItem(
        name: template.name,
        unit: template.unit,
        price: price,
        quantity: quantity,
      ));
    });
    
    // Сбрасываем поля формы
    setState(() {
      _selectedTemplateName = null;
    });
    _newItemQuantityController.text = '1.0';
    _newItemUnitController.clear();
    _newItemPriceController.clear();
    
    // Прячем клавиатуру
    FocusScope.of(context).unfocus();
    
    _showSnackBar('Позиция "${template.name}" добавлена');
  }

  void _removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      final itemName = _items[index].name;
      setState(() {
        _items.removeAt(index);
      });
      _showSnackBar('Позиция "$itemName" удалена');
    }
  }

  double _calculateTotal() {
    return _items.fold(0.0, (sum, item) => sum + item.total);
  }

  Future<void> _saveEstimate() async {
    final title = _titleController.text.trim();
    
    if (title.isEmpty) {
      _showSnackBar('Введите название сметы', isError: true);
      return;
    }
    
    if (_items.isEmpty) {
      _showSnackBar('Добавьте хотя бы одну позицию', isError: true);
      return;
    }
    
    setState(() => _isLoading = true);
    
    final estimate = Estimate(
      id: widget.existingEstimate?.id,
      title: title,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      totalPrice: _calculateTotal(),
      createdAt: widget.existingEstimate?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    try {
      final db = await DatabaseHelper.instance.database;
      int estimateId;
      
      if (estimate.id == null) {
        // Новая смета
        estimateId = await db.insert('estimates', estimate.toMap());
        print('✅ Создана новая смета ID: $estimateId');
      } else {
        // Обновление существующей
        estimateId = estimate.id!;
        await db.update(
          'estimates',
          estimate.toMap(),
          where: 'id = ?',
          whereArgs: [estimateId],
        );
        print('✅ Обновлена смета ID: $estimateId');
      }
      
      // СОХРАНЯЕМ ПОЗИЦИИ СМЕТЫ
      await _saveEstimateItems(estimateId);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingEstimate != null 
              ? '✅ Смета обновлена' 
              : '✅ Смета сохранена'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Возвращаемся через 2 секунды
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;
      Navigator.pop(context, true);
      
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('❌ Ошибка сохранения: $error', isError: true);
      print('❌ Ошибка сохранения сметы: $error');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEstimate != null 
            ? 'Редактировать смету' 
            : 'Новая смета'),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed: _saveEstimate,
                  icon: const Icon(Icons.save),
                  tooltip: 'Сохранить смету',
                ),
        ],
      ),
      body: _isLoading && widget.existingEstimate != null && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Основные данные сметы
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Основные данные',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Название сметы *',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Описание (необязательно)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Список позиций и итог
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Позиции сметы',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'ИТОГО: ${_calculateTotal().toStringAsFixed(2)} ₽',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Количество позиций: ${_items.length}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 12),

                        // Список добавленных позиций
                        Expanded(
                          child: _items.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.list_alt, size: 64, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'Позиций пока нет',
                                        style: TextStyle(fontSize: 18, color: Colors.grey),
                                      ),
                                      Text(
                                        'Добавьте первую позицию ниже',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _items.length,
                                  itemBuilder: (context, index) {
                                    final item = _items[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        title: Text(
                                          item.name,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              '${item.quantity} ${item.unit} × ${item.price} ₽',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${item.total.toStringAsFixed(2)} ₽',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _removeItem(index),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Форма добавления новой позиции
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Добавить новую позицию',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          
                          // Выпадающий список
                          DropdownButtonFormField<String>(
                            value: _selectedTemplateName,
                            decoration: const InputDecoration(
                              labelText: 'Выберите позицию *',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, size: 24),
                            itemHeight: 60,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('-- Выберите позицию --', style: TextStyle(fontSize: 14)),
                              ),
                              for (var template in EstimateTemplate.allTemplates)
                                DropdownMenuItem(
                                  value: template.name,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        template.name,
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${template.price} ₽/${template.unit}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                _updatePriceAndUnit(value);
                              } else {
                                setState(() {
                                  _selectedTemplateName = null;
                                  _newItemUnitController.clear();
                                  _newItemPriceController.clear();
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 12),

                          // Поля ввода
                          Row(
                            children: [
                              // Количество
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _newItemQuantityController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Кол-во',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    labelStyle: TextStyle(fontSize: 13),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              // Единица измерения
                              SizedBox(
                                width: 60,
                                child: TextField(
                                  controller: _newItemUnitController,
                                  enabled: false,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    labelText: 'Ед.',
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    labelStyle: const TextStyle(fontSize: 12),
                                  ),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              // Цена
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _newItemPriceController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Цена',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    prefixText: '₽ ',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    labelStyle: TextStyle(fontSize: 13),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              // Кнопка добавить
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _addNewItem,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Icon(Icons.add, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
