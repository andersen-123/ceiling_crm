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
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final PdfService _pdfService = PdfService();
  
  late TextEditingController _clientNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  
  // Ключи для каждого TextField в позициях
  final List<GlobalKey<FormState>> _itemFormKeys = [];
  // Контроллеры для каждой позиции (фиксированные, не пересоздаются)
  final List<Map<String, TextEditingController>> _itemControllers = [];
  
  List<LineItem> _items = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    
    _clientNameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    
    _loadData();
  }
  
  Future<void> _loadData() async {
    if (widget.quote != null) {
      _clientNameController.text = widget.quote!.clientName;
      _addressController.text = widget.quote!.address ?? '';
      _phoneController.text = widget.quote!.phone ?? '';
      _emailController.text = widget.quote!.email ?? '';
      
      final items = await _dbHelper.getLineItemsForQuote(widget.quote!.id!);
      _items = items;
    } else {
      // Новая цитата - добавляем одну пустую позицию
      _items = [LineItem(
        quoteId: 0,
        description: '', 
        quantity: 1, 
        pricePerUnit: 0,
        total: 0,
      )];
    }
    
    // Инициализируем контроллеры и ключи форм для каждой позиции
    _initItemControllers();
    
    setState(() {
      _isLoading = false;
    });
  }
  
  void _initItemControllers() {
    _itemControllers.clear();
    _itemFormKeys.clear();
    
    for (int i = 0; i < _items.length; i++) {
      _itemFormKeys.add(GlobalKey<FormState>());
      _itemControllers.add({
        'description': TextEditingController(text: _items[i].description),
        'quantity': TextEditingController(text: _items[i].quantity.toString()),
        'price': TextEditingController(text: _items[i].pricePerUnit.toString()),
        'unit': TextEditingController(text: _items[i].unit ?? 'шт.'),
      });
    }
  }
  
  void _addNewItem() {
    setState(() {
      _items.add(LineItem(
        quoteId: widget.quote?.id ?? 0,
        name: '',
        description: '',
        quantity: 1,
        unit: 'м²',
        pricePerUnit: 0,
      ));

      _itemFormKeys.add(GlobalKey<FormState>());
      _itemControllers.add({
        'description': TextEditingController(),
        'quantity': TextEditingController(text: '1'),
        'price': TextEditingController(text: '0'),
        'unit': TextEditingController(text: 'шт.'),
      });
    });
  }
  
  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
        _itemFormKeys.removeAt(index);
        _itemControllers.removeAt(index);
      });
    }
  }
  
  void _updateItem(int index) {
    final controllers = _itemControllers[index];
    
    final description = controllers['description']!.text;
    final quantity = int.tryParse(controllers['quantity']!.text) ?? 1;
    final price = double.tryParse(controllers['price']!.text) ?? 0;
    final unit = controllers['unit']!.text;
    
    setState(() {
      _items[index] = LineItem(
        quoteId: _items[index].quoteId,
        description: description,
        quantity: quantity,
        pricePerUnit: price,
        unit: unit,
      );
    });
    
    _calculateTotal();
  }
  
  void _calculateTotal() {
    double total = 0;
    for (final item in _items) {
      total += item.total;
    }
    
    if (widget.quote != null) {
      setState(() {
        widget.quote!.totalAmount = total;
      });
    }
  }
  
  Future<void> _saveQuote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Валидируем все позиции
    for (final key in _itemFormKeys) {
      if (!key.currentState!.validate()) {
        return;
      }
    }
    
    // Обновляем все позиции перед сохранением
    for (int i = 0; i < _items.length; i++) {
      _updateItem(i);
    }
    
    final quote = widget.quote ?? Quote(
      clientName: '',
      date: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    quote.clientName = _clientNameController.text;
    quote.address = _addressController.text.isNotEmpty ? _addressController.text : null;
    quote.phone = _phoneController.text.isNotEmpty ? _phoneController.text : null;
    quote.email = _emailController.text.isNotEmpty ? _emailController.text : null;
    quote.updatedAt = DateTime.now();
    
    try {
      if (widget.quote == null) {
        // Новая цитата
        final id = await _dbHelper.insertQuote(quote);
        quote.id = id;
        await _dbHelper.updateQuoteWithItems(quote, _items);
      } else {
        // Обновление существующей
        await _dbHelper.updateQuoteWithItems(quote, _items);
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
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
      if (companyProfile == null) {
        throw Exception('Профиль компании не найден');
      }
      
      // Показываем диалог выбора действия
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Экспорт PDF'),
          content: const Text('Выберите действие:'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _pdfService.previewPdf(
                  quote: widget.quote!,
                  items: _items,
                  companyProfile: companyProfile,
                );
              },
              child: const Text('Предпросмотр'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _pdfService.sharePdf(
                  quote: widget.quote!,
                  items: _items,
                  companyProfile: companyProfile,
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF готов к отправке. Проверьте консоль для пути к файлу.'),
                    ),
                  );
                }
              },
              child: const Text('Поделиться'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка генерации PDF: $e')),
        );
      }
    }
  }
  
  Widget _buildItemRow(int index) {
    final controllers = _itemControllers[index];
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_items.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeItem(index),
                    ),
                ],
              ),
              
              TextFormField(
                controller: controllers['description'],
                decoration: const InputDecoration(
                  labelText: 'Наименование',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => _updateItem(index),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите описание';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controllers['quantity'],
                      decoration: const InputDecoration(
                        labelText: 'Кол-во',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _updateItem(index),
                      validator: (value) {
                        final quantity = int.tryParse(value ?? '');
                        if (quantity == null || quantity <= 0) {
                          return 'Введите число > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 10),
                  
                  Expanded(
                    child: TextFormField(
                      controller: controllers['unit'],
                      decoration: const InputDecoration(
                        labelText: 'Ед. изм.',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _updateItem(index),
                    ),
                  ),
                  
                  const SizedBox(width: 10),
                  
                  Expanded(
                    child: TextFormField(
                      controller: controllers['price'],
                      decoration: const InputDecoration(
                        labelText: 'Цена',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => _updateItem(index),
                      validator: (value) {
                        final price = double.tryParse(value ?? '');
                        if (price == null || price < 0) {
                          return 'Введите число ≥ 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Сумма: ${_items[index].total.toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
              tooltip: 'Создать PDF',
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
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите имя клиента';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 10),
                      
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Адрес',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Телефон',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      
                      const SizedBox(height: 10),
                      
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _addNewItem,
                            tooltip: 'Добавить позицию',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                      
                      ...List.generate(_items.length, (index) => _buildItemRow(index)),
                      
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                              '${widget.quote?.totalAmount.toStringAsFixed(2) ?? '0.00'} ₽',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
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
      floatingActionButton: FloatingActionButton(
        onPressed: _saveQuote,
        child: const Icon(Icons.save),
      ),
    );
  }
  
  @override
  void dispose() {
    _clientNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    
    // Диспозим все контроллеры позиций
    for (final controllers in _itemControllers) {
      controllers['description']?.dispose();
      controllers['quantity']?.dispose();
      controllers['price']?.dispose();
      controllers['unit']?.dispose();
    }
    
    super.dispose();
  }
}
