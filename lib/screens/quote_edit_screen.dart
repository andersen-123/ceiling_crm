import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/services/database_helper.dart';

class QuoteEditScreen extends StatefulWidget {
  final int? quoteId;
  
  const QuoteEditScreen({Key? key, this.quoteId}) : super(key: key);

  @override
  _QuoteEditScreenState createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  late Quote _quote;
  bool _isLoading = true;
  bool _isNewQuote = true;

  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _clientAddressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    if (widget.quoteId != null) {
      final existingQuote = await _dbHelper.getQuoteById(widget.quoteId!);
      if (existingQuote != null) {
        _quote = existingQuote;
        _isNewQuote = false;
      } else {
        _createNewQuote();
      }
    } else {
      _createNewQuote();
    }
    
    // Инициализируем контроллеры
    _clientNameController.text = _quote.clientName;
    _clientPhoneController.text = _quote.clientPhone;
    _clientAddressController.text = _quote.clientAddress;
    _notesController.text = _quote.notes;
    
    setState(() => _isLoading = false);
  }

  void _createNewQuote() {
    _quote = Quote(
      clientName: 'Новый клиент',
      clientPhone: '',
      clientAddress: '',
      notes: '',
      totalAmount: 0.0,
      createdAt: DateTime.now(),
      items: [],
    );
    _isNewQuote = true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewQuote ? 'Новое КП' : 'Редактирование КП'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Информация о клиенте
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Информация о клиенте',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Имя клиента *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите имя клиента';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() => _quote.clientName = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _clientPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Телефон',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _quote.clientPhone = value,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _clientAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Адрес',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _quote.clientAddress = value,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Примечания',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        onChanged: (value) => _quote.notes = value,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Список позиций
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Позиции',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить'),
                    onPressed: _addNewItem,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (_quote.items.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.list, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Нет добавленных позиций'),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ..._quote.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildLineItemCard(item, index);
                }).toList(),

              const SizedBox(height: 24),

              // Итоговая сумма
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ИТОГО:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_quote.totalAmount.toStringAsFixed(2)} руб.',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineItemCard(LineItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
            
            if (item.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(item.description),
              ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item.unitPrice.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Цена за единицу',
                      border: OutlineInputBorder(),
                      prefixText: '₽ ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final price = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _quote.items[index] = item.copyWith(unitPrice: price);
                        _quote._calculateTotal();
                      });
                    },
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Количество',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final quantity = int.tryParse(value) ?? 1;
                      setState(() {
                        _quote.items[index] = item.copyWith(quantity: quantity);
                        _quote._calculateTotal();
                      });
                    },
                  ),
                ),
                
                const SizedBox(width: 16),
                
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: item.unit,
                    decoration: const InputDecoration(
                      labelText: 'Ед. изм.',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _quote.items[index] = item.copyWith(unit: value);
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${item.totalPrice.toStringAsFixed(2)} руб.',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewItem() {
    setState(() {
      _quote.addItem(LineItem(
        quoteId: _quote.id ?? 0,
        name: 'Новая позиция',
        unitPrice: 0.0,
        quantity: 1,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _quote.removeItem(index);
    });
  }

  Future<void> _saveQuote() async {
    if (_formKey.currentState!.validate()) {
      try {
        _quote.updatedAt = DateTime.now();
        
        if (_isNewQuote) {
          await _dbHelper.insertQuote(_quote);
        } else {
          await _dbHelper.updateQuote(_quote);
        }
        
        Navigator.pop(context, true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('КП ${_isNewQuote ? 'создано' : 'обновлено'}'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
