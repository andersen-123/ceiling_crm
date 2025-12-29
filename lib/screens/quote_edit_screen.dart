import 'package:flutter/material.dart';
import 'package:ceiling_crm/data/database_helper.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/services/pdf_service.dart';
import 'package:ceiling_crm/screens/quick_add_screen.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class QuoteEditScreen extends StatefulWidget {
  final int? quoteId;

  const QuoteEditScreen({super.key, this.quoteId});

  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  late Quote _quote;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final PdfService _pdfService = PdfService();
  
  // Контроллеры для формы
  late TextEditingController _clientNameController;
  late TextEditingController _clientEmailController;
  late TextEditingController _clientPhoneController;
  late TextEditingController _clientAddressController;
  late TextEditingController _projectNameController;
  late TextEditingController _projectDescriptionController;
  late TextEditingController _notesController;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // Инициализация контроллеров
    _clientNameController = TextEditingController();
    _clientEmailController = TextEditingController();
    _clientPhoneController = TextEditingController();
    _clientAddressController = TextEditingController();
    _projectNameController = TextEditingController();
    _projectDescriptionController = TextEditingController();
    _notesController = TextEditingController();
    
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    if (widget.quoteId != null) {
      final existingQuote = await _dbHelper.getQuote(widget.quoteId!);
      if (existingQuote != null) {
        _quote = existingQuote;
        // Загружаем позиции из базы данных
        final lineItems = await _dbHelper.getLineItemsForQuote(widget.quoteId!);
        _quote.items = lineItems;
        _updateControllers();
      } else {
        _createNewQuote();
      }
    } else {
      _createNewQuote();
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  void _createNewQuote() {
    _quote = Quote(
      clientName: '',
      clientEmail: '',
      clientPhone: '',
      clientAddress: '',
      projectName: '',
      projectDescription: '',
      totalAmount: 0.0,
      status: 'черновик',
      notes: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _updateControllers() {
    _clientNameController.text = _quote.clientName;
    _clientEmailController.text = _quote.clientEmail;
    _clientPhoneController.text = _quote.clientPhone;
    _clientAddressController.text = _quote.clientAddress;
    _projectNameController.text = _quote.projectName;
    _projectDescriptionController.text = _quote.projectDescription;
    _notesController.text = _quote.notes;
  }

  Future<void> _saveQuote() async {
    if (_clientNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите имя клиента'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Обновляем данные цитаты из контроллеров
      _quote.clientName = _clientNameController.text;
      _quote.clientEmail = _clientEmailController.text;
      _quote.clientPhone = _clientPhoneController.text;
      _quote.clientAddress = _clientAddressController.text;
      _quote.projectName = _projectNameController.text;
      _quote.projectDescription = _projectDescriptionController.text;
      _quote.notes = _notesController.text;
      _quote.updatedAt = DateTime.now();

      if (_quote.id == null) {
        // Новая цитата
        final id = await _dbHelper.insertQuote(_quote);
        _quote.id = id;
        
        // Сохраняем позиции
        for (final item in _quote.items) {
          item.quoteId = id;
          await _dbHelper.insertLineItem(item);
        }
      } else {
        // Обновление существующей цитаты
        await _dbHelper.updateQuote(_quote);
        
        // Обновляем позиции
        final existingItems = await _dbHelper.getLineItemsForQuote(_quote.id!);
        
        // Удаляем старые позиции
        for (final item in existingItems) {
          await _dbHelper.deleteLineItem(item.id!);
        }
        
        // Добавляем новые позиции
        for (final item in _quote.items) {
          item.quoteId = _quote.id!;
          await _dbHelper.insertLineItem(item);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('КП сохранено'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
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

  void _addNewItem() {
    final newItem = LineItem(
      quoteId: _quote.id ?? 0,
      description: 'Новая позиция',
      quantity: 1.0,
      price: 0.0,
      unit: 'шт',
      name: 'Новая позиция',
    );
    
    setState(() {
      _quote.addItem(newItem);
    });
  }

  void _editItem(int index) {
    final item = _quote.items[index];
    
    showDialog(
      context: context,
      builder: (context) {
        final descriptionController = TextEditingController(text: item.description);
        final quantityController = TextEditingController(text: item.quantity.toString());
        final priceController = TextEditingController(text: item.price.toString());
        final unitController = TextEditingController(text: item.unit);
        
        return AlertDialog(
          title: const Text('Редактировать позицию'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Описание'),
                ),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Количество'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Цена'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(labelText: 'Единица измерения'),
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
                final updatedItem = item.copyWith(
                  description: descriptionController.text,
                  quantity: double.tryParse(quantityController.text) ?? item.quantity,
                  price: double.tryParse(priceController.text) ?? item.price,
                  unit: unitController.text,
                );
                
                setState(() {
                  _quote.updateItem(index, updatedItem);
                });
                
                Navigator.pop(context);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(int index) {
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

  void _showQuickAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: QuickAddScreen(
          onItemsSelected: (selectedItems) {
            setState(() {
              _quote.addItems(selectedItems);
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _previewPdf() async {
    if (_quote.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте хотя бы одну позицию'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final lineItems = _quote.items;
      final pdfBytes = await _pdfService.generateQuotePdf(_quote, lineItems);
      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка генерации PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sharePdf() async {
    if (_quote.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте хотя бы одну позицию'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Шаринг PDF будет реализован в следующем обновлении'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 2,
    ).format(amount);
  }

  Widget _buildItemCard(int index) {
    final item = _quote.items[index];
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(item.description),
        subtitle: Text('${item.quantity} ${item.unit} × ${_formatCurrency(item.price)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatCurrency(item.totalPrice),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editItem(index),
              tooltip: 'Редактировать',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
              onPressed: () => _deleteItem(index),
              tooltip: 'Удалить',
            ),
          ],
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
        title: Text(widget.quoteId == null ? 'Новое КП' : 'Редактирование КП'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _previewPdf,
            tooltip: 'Предпросмотр PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePdf,
            tooltip: 'Поделиться',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveQuote,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Основная информация о клиенте
            const Text(
              'Информация о клиенте',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _clientNameController,
              decoration: const InputDecoration(
                labelText: 'Имя клиента *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _clientEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _clientPhoneController,
              decoration: const InputDecoration(
                labelText: 'Телефон',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _clientAddressController,
              decoration: const InputDecoration(
                labelText: 'Адрес',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            
            // Информация о проекте
            const Text(
              'Информация о проекте',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _projectNameController,
              decoration: const InputDecoration(
                labelText: 'Название проекта',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _projectDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание работ',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Позиции
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Позиции',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showQuickAdd,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Быстрое добавление', style: TextStyle(fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addNewItem,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Добавить позицию', style: TextStyle(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_quote.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.list, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Нет добавленных позиций',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Добавьте позиции, используя кнопки выше',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  ..._quote.items.asMap().entries.map((entry) => _buildItemCard(entry.key)),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ИТОГО:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatCurrency(_quote.totalAmount),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 24),
            
            // Примечания
            const Text(
              'Примечания',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Дополнительные заметки',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            
            // Кнопка сохранения
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveQuote,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Сохранение...' : 'Сохранить КП'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
