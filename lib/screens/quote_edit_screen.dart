// Часть 2: Добавляем динамические списки работ и оборудования
// Вставьте этот код в класс QuoteEditScreenState вместо комментария TODO

import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../data/database_helper.dart';

// Обновляем класс QuoteEditScreenState

// Добавляем новые переменные в класс
class QuoteEditScreenState extends State<QuoteEditScreen> {
  // ... существующие контроллеры и переменные ...

  // Списки позиций работ и оборудования
  List<LineItem> _workItems = [];
  List<LineItem> _equipmentItems = [];
  
  // Суммы
  double _subtotalWork = 0.0;
  double _subtotalEquipment = 0.0;
  double _totalAmount = 0.0;

  // Единицы измерения для выпадающего списка
  final List<String> _units = ['m²', 'm.p.', 'шт.', 'пог. м', 'компл.', 'усл.'];
  
  // Шаблоны для автозаполнения
  final List<Map<String, dynamic>> _workTemplates = [
    {'description': 'Монтаж натяжного потолка', 'unit': 'm²', 'price': 0.0},
    {'description': 'Обход трубы', 'unit': 'шт.', 'price': 0.0},
    {'description': 'Установка люстры/светильника', 'unit': 'шт.', 'price': 0.0},
    {'description': 'Установка карниза', 'unit': 'м.п.', 'price': 0.0},
  ];

  @override
  void initState() {
    super.initState();
    // ... существующий код инициализации ...
    
    // Загружаем позиции если редактируем существующее КП
    if (widget.quote != null && widget.quote!.id != null) {
      _loadLineItems();
      _subtotalWork = widget.quote!.subtotalWork;
      _subtotalEquipment = widget.quote!.subtotalEquipment;
      _totalAmount = widget.quote!.totalAmount;
    }
  }

  // Загрузка позиций из базы данных
  Future<void> _loadLineItems() async {
    if (widget.quote == null || widget.quote!.id == null) return;
    
    try {
      final dbHelper = DatabaseHelper();
      final items = await dbHelper.getLineItemsForQuote(widget.quote!.id!);
      
      setState(() {
        _workItems = items.where((item) => item.section == 'work').toList();
        _equipmentItems = items.where((item) => item.section == 'equipment').toList();
        _recalculateTotals();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки позиций: $error'), backgroundColor: Colors.red),
      );
    }
  }

  // Обновляем метод _saveQuote для сохранения позиций
  Future<void> _saveQuote() async {
    if (_formKey.currentState!.validate()) {
      try {
        final dbHelper = DatabaseHelper();
        
        // Создаем или обновляем Quote
        final quote = Quote(
          id: widget.quote?.id,
          customerName: _customerNameController.text,
          // ... остальные поля ...
          subtotalWork: _subtotalWork,
          subtotalEquipment: _subtotalEquipment,
          totalAmount: _totalAmount,
        );

        int quoteId;
        if (quote.id == null) {
          quoteId = await dbHelper.insertQuote(quote);
        } else {
          await dbHelper.updateQuote(quote);
          quoteId = quote.id!;
          
          // Удаляем старые позиции перед сохранением новых
          final oldItems = await dbHelper.getLineItemsForQuote(quoteId);
          for (final item in oldItems) {
            await dbHelper.deleteLineItem(item.id!);
          }
        }

        // Сохраняем все позиции
        int position = 1;
        for (final item in _workItems) {
          await dbHelper.insertLineItem(item.copyWith(
            quoteId: quoteId,
            position: position++,
          ));
        }
        
        for (final item in _equipmentItems) {
          await dbHelper.insertLineItem(item.copyWith(
            quoteId: quoteId,
            position: position++,
          ));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.quote == null 
                ? 'КП успешно создано' 
                : 'КП успешно обновлено'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true); // Возвращаем true для обновления списка
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Добавление новой позиции в раздел
  void _addLineItem(String section) {
    setState(() {
      final newItem = LineItem(
        quoteId: widget.quote?.id ?? 0,
        position: section == 'work' ? _workItems.length + 1 : _equipmentItems.length + 1,
        section: section,
        description: '',
        unit: 'm²',
        quantity: 0,
        price: 0,
      );
      
      if (section == 'work') {
        _workItems.add(newItem);
      } else {
        _equipmentItems.add(newItem);
      }
    });
  }

  // Удаление позиции
  void _removeLineItem(String section, int index) {
    setState(() {
      if (section == 'work') {
        _workItems.removeAt(index);
        // Обновляем позиции
        for (int i = 0; i < _workItems.length; i++) {
          _workItems[i] = _workItems[i].copyWith(position: i + 1);
        }
      } else {
        _equipmentItems.removeAt(index);
        // Обновляем позиции
        for (int i = 0; i < _equipmentItems.length; i++) {
          _equipmentItems[i] = _equipmentItems[i].copyWith(position: i + 1);
        }
      }
      _recalculateTotals();
    });
  }

  // Обновление позиции
  void _updateLineItem(String section, int index, LineItem updatedItem) {
    setState(() {
      if (section == 'work') {
        _workItems[index] = updatedItem;
      } else {
        _equipmentItems[index] = updatedItem;
      }
      _recalculateTotals();
    });
  }

  // Пересчет итогов
  void _recalculateTotals() {
    double workTotal = 0.0;
    double equipmentTotal = 0.0;
    
    for (final item in _workItems) {
      workTotal += item.amount;
    }
    
    for (final item in _equipmentItems) {
      equipmentTotal += item.amount;
    }
    
    setState(() {
      _subtotalWork = workTotal;
      _subtotalEquipment = equipmentTotal;
      _totalAmount = workTotal + equipmentTotal;
    });
  }

  // Метод для быстрого добавления из шаблона
  void _addFromTemplate(Map<String, dynamic> template, String section) {
    setState(() {
      final newItem = LineItem(
        quoteId: widget.quote?.id ?? 0,
        position: section == 'work' ? _workItems.length + 1 : _equipmentItems.length + 1,
        section: section,
        description: template['description'],
        unit: template['unit'],
        quantity: 1,
        price: template['price'],
      );
      
      if (section == 'work') {
        _workItems.add(newItem);
      } else {
        _equipmentItems.add(newItem);
      }
      _recalculateTotals();
    });
  }

  // Вставляем этот виджет в build() после блока "Условия и примечания"
  // Замените комментарий TODO на следующие блоки:

  Widget _buildLineItemsSection() {
    return Column(
      children: [
        // Раздел: Работы
        _buildSectionHeader('Работы'),
        _buildLineItemsList('work', _workItems),
        _buildAddButton('work'),
        
        // Итого по работам
        if (_workItems.isNotEmpty)
          _buildSubtotalRow('Работы:', _subtotalWork),
        
        const SizedBox(height: 16),
        
        // Раздел: Оборудование
        _buildSectionHeader('Оборудование'),
        _buildLineItemsList('equipment', _equipmentItems),
        _buildAddButton('equipment'),
        
        // Итого по оборудованию
        if (_equipmentItems.isNotEmpty)
          _buildSubtotalRow('Оборудование:', _subtotalEquipment),
        
        const SizedBox(height: 16),
        
        // Общий итог
        if (_workItems.isNotEmpty || _equipmentItems.isNotEmpty)
          _buildTotalRow(),
      ],
    );
  }

  // Виджет списка позиций
  Widget _buildLineItemsList(String section, List<LineItem> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          section == 'work' ? 'Нет работ' : 'Нет оборудования',
          style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildLineItemCard(section, index, items[index]);
      },
    );
  }

  // Карточка одной позиции
  Widget _buildLineItemCard(String section, int index, LineItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '${index + 1}.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.description,
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onChanged: (value) {
                      _updateLineItem(section, index, item.copyWith(description: value));
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                // Единица измерения
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: item.unit,
                    decoration: const InputDecoration(
                      labelText: 'Ед. изм.',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      _updateLineItem(section, index, item.copyWith(unit: value!));
                    },
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Количество
                Expanded(
                  child: TextFormField(
                    initialValue: item.quantity.toStringAsFixed(2),
                    decoration: const InputDecoration(
                      labelText: 'Кол-во',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final quantity = double.tryParse(value.replaceAll(',', '.')) ?? 0;
                      _updateLineItem(section, index, item.copyWith(quantity: quantity));
                    },
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Цена
                Expanded(
                  child: TextFormField(
                    initialValue: item.price.toStringAsFixed(2),
                    decoration: const InputDecoration(
                      labelText: 'Цена',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final price = double.tryParse(value.replaceAll(',', '.')) ?? 0;
                      _updateLineItem(section, index, item.copyWith(price: price));
                    },
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Сумма (только для отображения)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${item.amount.toStringAsFixed(2)} ₽',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Кнопка удаления
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeLineItem(section, index),
                  tooltip: 'Удалить позицию',
                ),
              ],
            ),
            
            // Поле для примечания
            if (item.note != null || true) // Всегда показываем
              const SizedBox(height: 8),
              TextFormField(
                initialValue: item.note,
                decoration: const InputDecoration(
                  labelText: 'Примечание (опционально)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                maxLines: 1,
                onChanged: (value) {
                  _updateLineItem(section, index, item.copyWith(note: value.isNotEmpty ? value : null));
                },
              ),
          ],
        ),
      ),
    );
  }

  // Кнопка добавления новой позиции
  Widget _buildAddButton(String section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () => _addLineItem(section),
            icon: const Icon(Icons.add),
            label: Text('Добавить ${section == 'work' ? 'работу' : 'оборудование'}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: section == 'work' ? Colors.blue.shade50 : Colors.green.shade50,
              foregroundColor: section == 'work' ? Colors.blue : Colors.green,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Кнопка быстрого добавления из шаблона (только для работ)
          if (section == 'work')
            PopupMenuButton<Map<String, dynamic>>(
              icon: const Icon(Icons.bolt),
              tooltip: 'Быстрое добавление',
              onSelected: (template) => _addFromTemplate(template, section),
              itemBuilder: (context) => _workTemplates.map((template) {
                return PopupMenuItem(
                  value: template,
                  child: Text(template['description']),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Строка с промежуточным итогом
  Widget _buildSubtotalRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ₽',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  // Строка с общим итогом
  Widget _buildTotalRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'ИТОГО:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Text(
            '${_totalAmount.toStringAsFixed(2)} ₽',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  // Обновляем метод build() - добавляем вызов _buildLineItemsSection()
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quote == null ? 'Создание КП' : 'Редактирование КП'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveQuote,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ... существующие блоки (данные клиента, объекта и т.д.) ...
            
            // Блок: Условия и примечания
            _buildSectionHeader('Условия и примечания'),
            _buildTextFormField(
              controller: _paymentTermsController,
              labelText: 'Условия оплаты',
              maxLines: 3,
            ),
            _buildTextFormField(
              controller: _installationTermsController,
              labelText: 'Условия и даты монтажа',
              maxLines: 3,
            ),
            _buildTextFormField(
              controller: _notesController,
              labelText: 'Прочие примечания',
              maxLines: 3,
            ),

            // Добавляем блоки работ и оборудования
            _buildLineItemsSection(),

            const SizedBox(height: 32),
            // Кнопка сохранения
            ElevatedButton.icon(
              onPressed: _saveQuote,
              icon: const Icon(Icons.save),
              label: const Text('Сохранить коммерческое предложение'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
