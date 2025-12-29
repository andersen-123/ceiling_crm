import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/data/database_helper.dart';
import 'package:ceiling_crm/services/pdf_service.dart';
import 'package:ceiling_crm/screens/quick_add_screen.dart';

class QuoteEditScreen extends StatefulWidget {
  final int? quoteId;
  
  const QuoteEditScreen({Key? key, this.quoteId}) : super(key: key);

  @override
  _QuoteEditScreenState createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final PdfService _pdfService = PdfService();
  
  late Quote _quote;
  bool _isLoading = true;
  bool _isNewQuote = true;
  bool _isGeneratingPdf = false;

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
        actions: _buildAppBarActions(),
      ),
      body: _isGeneratingPdf
          ? _buildPdfGenerationOverlay()
          : _buildMainContent(),
    );
  }

  List<Widget> _buildAppBarActions() {
    final actions = <Widget>[];
    
    // Кнопки PDF только для существующих КП
    if (!_isNewQuote) {
      actions.addAll([
        // Кнопка предпросмотра PDF
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.preview),
              if (_isGeneratingPdf)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: const SizedBox(
                      width: 8,
                      height: 8,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: _isGeneratingPdf ? null : _previewPdf,
          tooltip: 'Предпросмотр PDF',
        ),
        
        // Кнопка шаринга PDF
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _isGeneratingPdf ? null : _sharePdf,
          tooltip: 'Поделиться PDF',
        ),
        
        const SizedBox(width: 8),
      ]);
    }
    
    // Кнопка сохранения
    actions.add(
      IconButton(
        icon: const Icon(Icons.save),
        onPressed: _isGeneratingPdf ? null : _saveQuote,
        tooltip: 'Сохранить',
      ),
    );
    
    return actions;
  }

  Widget _buildPdfGenerationOverlay() {
    return Stack(
      children: [
        Opacity(
          opacity: 0.3,
          child: _buildMainContent(),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Генерация PDF документа',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'КП для "${_quote.clientName}"',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Form(
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
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.bolt, size: 16),
                      label: const Text('Быстрое'),
                      onPressed: _openQuickAdd,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Добавить'),
                      onPressed: _addNewItem,
                    ),
                  ],
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
                        SizedBox(height: 8),
                        Text(
                          'Используйте кнопки выше для добавления позиций',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
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
    );
  }

  Widget _buildLineItemCard(LineItem item, int index) {
    final nameController = TextEditingController(text: item.name);
    final descriptionController = TextEditingController(text: item.description ?? '');
    final priceController = TextEditingController(text: item.price.toString());
    final quantityController = TextEditingController(text: item.quantity.toString());
    final unitController = TextEditingController(text: item.unit);

    return Card(
      key: ValueKey(item.hashCode),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Наименование',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      _updateItemField(index, 'name', value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                  tooltip: 'Удалить позицию',
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 2,
              onChanged: (value) {
                _updateItemField(index, 'description', value);
              },
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Цена за единицу',
                      border: OutlineInputBorder(),
                      prefixText: '₽ ',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final price = double.tryParse(value) ?? 0.0;
                      _updateItemField(index, 'unitPrice', price);
                    },
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Количество',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final quantity = int.tryParse(value) ?? 1;
                      _updateItemField(index, 'quantity', quantity);
                    },
                  ),
                ),
                
                const SizedBox(width: 16),
                
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: 'Ед. изм.',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      _updateItemField(index, 'unit', value);
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Сумма: ${item.totalPrice.toStringAsFixed(2)} руб.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateItemField(int index, String field, dynamic value) {
    setState(() {
      var item = _quote.items[index];
      
      switch (field) {
        case 'name':
          item = item.copyWith(name: value as String);
          break;
        case 'description':
          item = item.copyWith(description: value as String);
          break;
        case 'unitPrice':
        case 'price': // Добавить эту строку
          item = item.copyWith(price: value as double);
          break;
        case 'quantity':
          item = item.copyWith(quantity: value as int);
          break;
      }
      
      _quote.updateItem(index, item);
    });
  }

  void _addNewItem() {
    setState(() {
      _quote.addItem(LineItem(
        quoteId: _quote.id ?? 0,
        name: 'Новая позиция',
        price: 0.0,
        quantity: 1,
        unit: 'шт.',
      ));
    });
  }

  void _removeItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить позицию?'),
        content: Text('Вы уверены, что хотите удалить "${_quote.items[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _quote.removeItem(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _openQuickAdd() async {
    final selectedItems = await Navigator.push<List<LineItem>>(
      context,
      MaterialPageRoute(
        builder: (context) => QuickAddScreen(
          onItemsSelected: (items) => items,
        ),
      ),
    );
    
    if (selectedItems != null && selectedItems.isNotEmpty) {
      setState(() {
        _quote.addItems(selectedItems);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Добавлено ${selectedItems.length} позиций'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
            content: Text('КП для "${_quote.clientName}" ${_isNewQuote ? 'создано' : 'обновлено'}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, заполните обязательные поля'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _previewPdf() async {
    if (_quote.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте хотя бы одну позицию для генерации PDF'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGeneratingPdf = true);
    
    try {
      await _pdfService.previewPdf(_quote);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF сгенерирован и открыт для предпросмотра'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка генерации PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_quote.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте хотя бы одну позицию для генерации PDF'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGeneratingPdf = true);
    
    try {
      await _pdfService.sharePdf(_quote);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF сгенерирован и готов к отправке'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка шаринга PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
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
