import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../data/database_helper.dart';
import '../services/pdf_service.dart';

class QuoteEditScreen extends StatefulWidget {
  final Quote? quote;
  
  const QuoteEditScreen({super.key, this.quote});
  
  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PdfService _pdfService = PdfService.instance;
  
  late TextEditingController _clientNameController;
  late TextEditingController _clientAddressController;
  late TextEditingController _clientPhoneController;
  late TextEditingController _clientEmailController;
  
  // Динамические контроллеры для позиций
  final List<GlobalKey<FormState>> _itemFormKeys = [];
  final List<Map<String, TextEditingController>> _itemControllers = [];
  
  List<LineItem> _items = [];
  bool _isLoading = true;
  double _totalAmount = 0.0;
  
  @override
  void initState() {
    super.initState();
    _clientNameController = TextEditingController();
    _clientAddressController = TextEditingController();
    _clientPhoneController = TextEditingController();
    _clientEmailController = TextEditingController();
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.quote != null) {
        // Редактирование существующего КП
        final quote = widget.quote!;
        _clientNameController.text = quote.clientName;
        _clientAddressController.text = quote.clientAddress;
        _clientPhoneController.text = quote.clientPhone;
        _clientEmailController.text = quote.clientEmail;
        _items = quote.items;
        _totalAmount = quote.totalAmount;
      } else {
        // Новое КП - одна пустая позиция
        _items = [LineItem(
          quoteId: 0,
          name: 'Новая позиция',
          description: '',
          quantity: 1.0,
          unit: 'м²',
          price: 0.0,
        )];
      }
      
      _initItemControllers();
    } catch (e) {
      print('Ошибка загрузки данных: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _initItemControllers() {
    _itemControllers.clear();
    _itemFormKeys.clear();
    
    for (int i = 0; i < _items.length; i++) {
      _itemFormKeys.add(GlobalKey<FormState>());
      _itemControllers.add({
        'name': TextEditingController(text: _items[i].name),
        'description': TextEditingController(text: _items[i].description),
        'quantity': TextEditingController(text: _items[i].quantity.toString()),
        'unit': TextEditingController(text: _items[i].unit),
        'price': TextEditingController(text: _items[i].price.toStringAsFixed(2)),
      });
    }
  }
  
  void _addNewItem() {
    setState(() {
      final newItem = LineItem(
        quoteId: widget.quote?.id ?? 0,
        name: 'Новая позиция',
        description: '',
        quantity: 1.0,
        unit: 'м²',
        price: 0.0,
      );
      _items.add(newItem);
      
      _itemFormKeys.add(GlobalKey<FormState>());
      _itemControllers.add({
        'name': TextEditingController(text: newItem.name),
        'description': TextEditingController(),
        'quantity': TextEditingController(text: '1.0'),
        'unit': TextEditingController(text: 'м²'),
        'price': TextEditingController(text: '0.00'),
      });
      
      _calculateTotal();
    });
  }
  
  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
        _itemControllers.removeAt(index);
        _itemFormKeys.removeAt(index);
        _calculateTotal();
      });
    }
  }
  
  void _updateItem(int index) {
    final controllers = _itemControllers[index];
    final name = controllers['name']!.text.trim();
    final description = controllers['description']!.text;
    final quantityStr = controllers['quantity']!.text;
    final unit = controllers['unit']!.text;
    final priceStr = controllers['price']!.text;
    
    final quantity = double.tryParse(quantityStr) ?? 1.0;
    final price = double.tryParse(priceStr) ?? 0.0;
    
    setState(() {
      _items[index] = _items[index].copyWith(
        name: name.isEmpty ? 'Позиция ${index + 1}' : name,
        description: description,
        quantity: quantity,
        unit: unit,
        price: price,
      );
      _calculateTotal();
    });
  }
  
  void _calculateTotal() {
    _totalAmount = _items.fold(0.0, (sum, item) => sum + item.total);
    if (mounted) setState(() {});
  }
  
  Future<void> _saveQuote() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Валидация всех позиций
    for (int i = 0; i < _itemFormKeys.length; i++) {
      if (!_itemFormKeys[i].currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Проверьте позицию ${i + 1}')),
        );
        return;
      }
      _updateItem(i);
    }
    
    try {
      final quote = widget.quote ?? Quote(
        clientName: _clientNameController.text.trim(),
        projectName: 'Новый проект',
        items: _items,
      );
      
      final updatedQuote = quote.copyWith(
        clientName: _clientNameController.text.trim(),
        clientEmail: _clientEmailController.text.trim(),
        clientPhone: _clientPhoneController.text.trim(),
        clientAddress: _clientAddressController.text.trim(),
        totalAmount: _totalAmount,
        items: _items,
      );
      
      if (widget.quote == null) {
        await _dbHelper.createQuote(updatedQuote);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Новое КП создано')),
          );
        }
      } else {
        await _dbHelper.updateQuoteWithItems(updatedQuote, _items);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ КП обновлено')),
          );
        }
      }
      
      if (mounted) Navigator.pop(context, updatedQuote);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }
  
  Future<void> _generatePdf() async {
    if (widget.quote == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала сохраните КП')),
      );
      return;
    }
    
    try {
      final companyProfile = await _dbHelper.getCompanyProfile();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Экспорт PDF'),
          content: const Text('Функция в разработке'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }
  
  Widget _buildItemRow(int index) {
    final controllers = _itemControllers[index];
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _itemFormKeys[index],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Позиция ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_items.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeItem(index),
                    ),
                ],
              ),
              
              TextFormField(
                controller: controllers['name'],
                decoration: const InputDecoration(
                  labelText: 'Наименование *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _updateItem(index),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите наименование';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 12),
              
              TextFormField(
                controller: controllers['description'],
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => _updateItem(index),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controllers['quantity'],
                      decoration: const InputDecoration(
                        labelText: 'Кол-во *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _updateItem(index),
                      validator: (value) {
                        final qty = double.tryParse(value ?? '');
                        if (qty == null || qty <= 0) return 'Введите > 0';
                        return null;
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: TextFormField(
                      controller: controllers['unit'],
                      decoration: const InputDecoration(
                        labelText: 'Ед.изм.',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _updateItem(index),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: TextFormField(
                      controller: controllers['price'],
                      decoration: const InputDecoration(
                        labelText: 'Цена *',
                        border: OutlineInputBorder(),
                        prefixText: '₽ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _updateItem(index),
                      validator: (value) {
                        final price = double.tryParse(value ?? '');
                        if (price == null || price < 0) return 'Введите ≥ 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_items[index].total.toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        title: Text(widget.quote == null ? 'Новое КП' : 'Редактирование КП'),
        actions: [
          if (widget.quote != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _generatePdf,
              tooltip: 'PDF',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveQuote,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Клиентская информация
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Информация о клиенте',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      
                      TextFormField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Клиент *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите имя клиента';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _clientAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Адрес',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _clientPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Телефон',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _clientEmailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Позиции
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Позиции',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addNewItem,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Добавить'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      ..._items.asMap().entries.map((entry) => _buildItemRow(entry.key)),
                      
                      const SizedBox(height: 24),
                      
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ИТОГО:',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_totalAmount.toStringAsFixed(2)} ₽',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveQuote,
        icon: const Icon(Icons.save),
        label: const Text('Сохранить'),
      ),
    );
  }
  
  @override
  void dispose() {
    _clientNameController.dispose();
    _clientAddressController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    
    for (final controllers in _itemControllers) {
      controllers['name']?.dispose();
      controllers['description']?.dispose();
      controllers['quantity']?.dispose();
      controllers['unit']?.dispose();
      controllers['price']?.dispose();
    }
    
    super.dispose();
  }
}
