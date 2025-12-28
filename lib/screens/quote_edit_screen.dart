import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/repositories/quote_repository.dart';
import 'package:ceiling_crm/screens/quick_add_screen.dart';
import 'package:ceiling_crm/screens/edit_position_modal.dart';
import 'package:intl/intl.dart';

class QuoteEditScreen extends StatefulWidget {
  final Quote? quote;
  
  QuoteEditScreen({this.quote});
  
  @override
  _QuoteEditScreenState createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final QuoteRepository _quoteRepo = QuoteRepository();
  
  // Контроллеры для формы
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _objectAddressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // Данные КП
  Quote? _currentQuote;
  List<LineItem> _lineItems = [];
  bool _isLoading = true;
  bool _isSaving = false;
  double _quoteTotal = 0.0;
  double _vatRate = 20.0;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      if (widget.quote != null) {
        // Редактирование существующего КП
        _currentQuote = widget.quote;
        _lineItems = await _quoteRepo.getLineItems(_currentQuote!.id!);
        _vatRate = _currentQuote!.vatRate;
        
        // Заполняем контроллеры
        _clientNameController.text = _currentQuote!.clientName;
        _clientPhoneController.text = _currentQuote!.clientPhone;
        _objectAddressController.text = _currentQuote!.objectAddress;
        _notesController.text = _currentQuote!.notes ?? '';
        
        // Рассчитываем итог
        _calculateTotal();
      } else {
        // Создание нового КП
        _currentQuote = null;
        _lineItems = [];
        _quoteTotal = 0.0;
      }
    } catch (e) {
      print('Ошибка загрузки данных: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки данных: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _calculateTotal() {
    double total = 0;
    for (var item in _lineItems) {
      total += item.total;
    }
    setState(() {
      _quoteTotal = total;
    });
  }
  
  Future<void> _saveQuote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      if (_currentQuote == null) {
        // Создаем новый КП
        final quoteId = await _quoteRepo.createQuote(
          clientName: _clientNameController.text.trim(),
          clientPhone: _clientPhoneController.text.trim(),
          objectAddress: _objectAddressController.text.trim(),
          notes: _notesController.text.trim(),
          vatRate: _vatRate,
        );
        
        // Добавляем позиции если есть
        if (_lineItems.isNotEmpty) {
          for (var item in _lineItems) {
            await _quoteRepo.addLineItem(
              quoteId: quoteId,
              name: item.name,
              description: item.description,
              quantity: item.quantity,
              unit: item.unit,
              price: item.price,
            );
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('КП успешно создано'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Обновляем существующий КП
        final updatedQuote = _currentQuote!.copyWith(
          clientName: _clientNameController.text.trim(),
          clientPhone: _clientPhoneController.text.trim(),
          objectAddress: _objectAddressController.text.trim(),
          notes: _notesController.text.trim(),
          vatRate: _vatRate,
          total: _quoteTotal,
          updatedAt: DateTime.now(),
        );
        
        await _quoteRepo.updateQuote(updatedQuote);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('КП успешно обновлено'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Возвращаемся на предыдущий экран
      Navigator.pop(context, true);
      
    } catch (e) {
      print('Ошибка сохранения: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  Future<void> _addPosition() async {
    final result = await showModalBottomSheet<LineItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditPositionModal(
        onSave: (item) {
          // Обратный вызов при сохранении
        },
      ),
    );
    
    if (result != null) {
      setState(() {
        _lineItems.add(result);
      });
      _calculateTotal();
    }
  }
  
  Future<void> _editPosition(int index) async {
    final item = _lineItems[index];
    
    final result = await showModalBottomSheet<LineItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditPositionModal(
        initialItem: item,
        onSave: (updatedItem) {
          // Обратный вызов при обновлении
        },
      ),
    );
    
    if (result != null) {
      setState(() {
        _lineItems[index] = result;
      });
      _calculateTotal();
    }
  }
  
  Future<void> _deletePosition(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить позицию?'),
        content: Text('Вы уверены, что хотите удалить "${_lineItems[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Удалить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _lineItems.removeAt(index);
      });
      _calculateTotal();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Позиция удалена'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  Future<void> _quickAddPositions() async {
    final result = await Navigator.push<List<LineItem>>(
      context,
      MaterialPageRoute(
        builder: (context) => QuickAddScreen(
          quoteId: _currentQuote?.id,
        ),
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() {
        _lineItems.addAll(result);
      });
      _calculateTotal();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Добавлено ${result.length} позиций'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  Widget _buildPositionCard(LineItem item, int index) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blueGrey[100],
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Colors.blueGrey[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null && item.description!.isNotEmpty)
              Text(
                item.description!,
                style: TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${item.quantity} ${item.unit}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(width: 8),
                Text(
                  '×',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(width: 8),
                Text(
                  NumberFormat.currency(locale: 'ru_RU', symbol: '₽').format(item.price),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberFormat.currency(locale: 'ru_RU', symbol: '₽').format(item.total),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: 18),
                  onPressed: () => _editPosition(index),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _deletePosition(index),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _editPosition(index),
      ),
    );
  }
  
  Widget _buildTotalSection() {
    final vatAmount = _quoteTotal * (_vatRate / 100);
    final totalWithVat = _quoteTotal + vatAmount;
    
    return Card(
      color: Colors.blueGrey[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Итого без НДС:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  NumberFormat.currency(locale: 'ru_RU', symbol: '₽').format(_quoteTotal),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'НДС ${_vatRate}%:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  NumberFormat.currency(locale: 'ru_RU', symbol: '₽').format(vatAmount),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ИТОГО:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blueGrey[800],
                  ),
                ),
                Text(
                  NumberFormat.currency(locale: 'ru_RU', symbol: '₽').format(totalWithVat),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        title: Text(_currentQuote == null ? 'Новое КП' : 'Редактирование КП'),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: Icon(_isSaving ? Icons.hourglass_top : Icons.save),
            onPressed: _isSaving ? null : _saveQuote,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Секция с основными данными
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Данные клиента',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _clientNameController,
                        decoration: InputDecoration(
                          labelText: 'Имя клиента *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите имя клиента';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      
                      TextFormField(
                        controller: _clientPhoneController,
                        decoration: InputDecoration(
                          labelText: 'Телефон *',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите телефон клиента';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      
                      TextFormField(
                        controller: _objectAddressController,
                        decoration: InputDecoration(
                          labelText: 'Адрес объекта *',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите адрес объекта';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Примечания',
                          prefixIcon: Icon(Icons.note),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Секция с позициями
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Позиции',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[800],
                            ),
                          ),
                          Text(
                            '${_lineItems.length} шт.',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // Кнопки добавления
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _quickAddPositions,
                              icon: Icon(Icons.bolt),
                              label: Text('Быстрое добавление'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _addPosition,
                              icon: Icon(Icons.add),
                              label: Text('Добавить позицию'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Список позиций
                      if (_lineItems.isEmpty)
                        Container(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.list_alt,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Нет добавленных позиций',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Нажмите "Добавить позицию" или "Быстрое добавление"',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: [
                            ...List.generate(_lineItems.length, (index) {
                              return _buildPositionCard(_lineItems[index], index);
                            }),
                            SizedBox(height: 16),
                            _buildTotalSection(),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              Spacer(),
              
              // Кнопка сохранения
              Container(
                padding: EdgeInsets.only(top: 16, bottom: 8),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveQuote,
                  child: _isSaving
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(width: 12),
                            Text('Сохранение...'),
                          ],
                        )
                      : Text('СОХРАНИТЬ КП'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
