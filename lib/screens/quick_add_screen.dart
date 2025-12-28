import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class QuickAddScreen extends StatefulWidget {
  final int? quoteId;
  
  QuickAddScreen({this.quoteId});
  
  @override
  _QuickAddScreenState createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  List<Map<String, dynamic>> _standardPositions = [];
  List<bool> _selectedPositions = [];
  bool _isLoading = true;
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, TextEditingController> _priceControllers = {};

  @override
  void initState() {
    super.initState();
    _loadStandardPositions();
  }

  Future<void> _loadStandardPositions() async {
    try {
      final jsonString = await rootBundle.loadString('assets/standard_positions.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      setState(() {
        _standardPositions = List<Map<String, dynamic>>.from(jsonList);
        _selectedPositions = List<bool>.filled(_standardPositions.length, false);
        
        // Создаем контроллеры для редактирования
        for (int i = 0; i < _standardPositions.length; i++) {
          final position = _standardPositions[i];
          _quantityControllers[i] = TextEditingController(
            text: (position['quantity'] ?? 1.0).toString(),
          );
          _priceControllers[i] = TextEditingController(
            text: (position['price'] ?? 0.0).toString(),
          );
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки стандартных позиций: $e');
      
      // Заглушка если файл не найден
      setState(() {
        _standardPositions = [
          {
            'name': 'Монтаж натяжного потолка',
            'description': 'Монтаж потолка стандартной сложности',
            'unit': 'м²',
            'quantity': 1.0,
            'price': 1200.0,
          },
          {
            'name': 'Точечный светильник',
            'description': 'Установка светильника с подготовкой отверстия',
            'unit': 'шт.',
            'quantity': 1.0,
            'price': 800.0,
          },
          {
            'name': 'Люстра',
            'description': 'Монтаж люстры с креплением',
            'unit': 'шт.',
            'quantity': 1.0,
            'price': 1500.0,
          },
        ];
        _selectedPositions = List<bool>.filled(_standardPositions.length, false);
        
        for (int i = 0; i < _standardPositions.length; i++) {
          final position = _standardPositions[i];
          _quantityControllers[i] = TextEditingController(
            text: (position['quantity'] ?? 1.0).toString(),
          );
          _priceControllers[i] = TextEditingController(
            text: (position['price'] ?? 0.0).toString(),
          );
        }
        
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      _selectedPositions[index] = !_selectedPositions[index];
    });
  }

  void _selectAll() {
    setState(() {
      for (int i = 0; i < _selectedPositions.length; i++) {
        _selectedPositions[i] = true;
      }
    });
  }

  void _deselectAll() {
    setState(() {
      for (int i = 0; i < _selectedPositions.length; i++) {
        _selectedPositions[i] = false;
      }
    });
  }

  List<LineItem> _getSelectedItems() {
    final List<LineItem> selectedItems = [];
    
    for (int i = 0; i < _standardPositions.length; i++) {
      if (_selectedPositions[i]) {
        final position = _standardPositions[i];
        
        // Получаем значения из контроллеров
        final quantity = double.tryParse(_quantityControllers[i]!.text) ?? position['quantity'] ?? 1.0;
        final price = double.tryParse(_priceControllers[i]!.text) ?? position['price'] ?? 0.0;
        
        final lineItem = LineItem(
          quoteId: widget.quoteId ?? 0,
          name: position['name'] ?? '',
          description: position['description'],
          quantity: quantity,
          unit: position['unit'] ?? 'шт.',
          price: price,
          total: price * quantity,
          sortOrder: i,
          createdAt: DateTime.now(),
        );
        
        selectedItems.add(lineItem);
      }
    }
    
    return selectedItems;
  }

  int get _selectedCount {
    return _selectedPositions.where((selected) => selected).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Загрузка...'),
          backgroundColor: Colors.blueGrey[800],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Быстрое добавление'),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: Icon(Icons.select_all),
            onPressed: _selectAll,
            tooltip: 'Выбрать все',
          ),
          IconButton(
            icon: Icon(Icons.deselect),
            onPressed: _deselectAll,
            tooltip: 'Снять выделение',
          ),
        ],
      ),
      body: Column(
        children: [
          // Панель информации
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blueGrey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Выбрано: $_selectedCount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                if (_selectedCount > 0)
                  ElevatedButton.icon(
                    onPressed: () {
                      final selectedItems = _getSelectedItems();
                      Navigator.pop(context, selectedItems);
                    },
                    icon: Icon(Icons.check),
                    label: Text('Добавить выбранное'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
              ],
            ),
          ),
          
          // Список позиций
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: _standardPositions.length,
              itemBuilder: (context, index) {
                final position = _standardPositions[index];
                final isSelected = _selectedPositions[index];
                
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                  color: isSelected ? Colors.blueGrey[50] : null,
                  child: InkWell(
                    onTap: () => _toggleSelection(index),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleSelection(index),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  position['name'] ?? 'Без названия',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          if (position['description'] != null)
                            Padding(
                              padding: EdgeInsets.only(left: 40, top: 4),
                              child: Text(
                                position['description']!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          
                          SizedBox(height: 12),
                          
                          // Поля для редактирования количества и цены
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _quantityControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Количество',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.numbers, size: 20),
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) {
                                    // Обновляем состояние при изменении
                                    setState(() {});
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                child: Text(
                                  position['unit'] ?? 'шт.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blueGrey[800],
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _priceControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Цена',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.attach_money, size: 20),
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) {
                                    // Обновляем состояние при изменении
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 8),
                          
                          // Предпросмотр суммы
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Сумма:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${_calculateItemTotal(index)} ₽',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context, []);
            },
            icon: Icon(Icons.close),
            label: Text('Отмена'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              padding: EdgeInsets.symmetric(vertical: 16),
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ),
      ),
    );
  }
  
  String _calculateItemTotal(int index) {
    try {
      final quantity = double.tryParse(_quantityControllers[index]!.text) ?? 
                      _standardPositions[index]['quantity'] ?? 1.0;
      final price = double.tryParse(_priceControllers[index]!.text) ?? 
                   _standardPositions[index]['price'] ?? 0.0;
      final total = quantity * price;
      return total.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }
}
