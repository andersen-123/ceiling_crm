import 'dart:developer';
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
  
  // Контроллеры
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
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.quoteId != null) {
        final existingQuote = await _dbHelper.getQuote(widget.quoteId!);
        if (existingQuote != null) {
          _quote = existingQuote;
          // Загружаем позиции
          final lineItems = await _dbHelper.getLineItemsForQuote(widget.quoteId!);
          _quote.items = lineItems;
          _updateControllers();
        } else {
          _createNewQuote();
        }
      } else {
        _createNewQuote();
      }
    } catch (e) {
      print('Ошибка загрузки: $e');
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
    // Валидация
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
      print('💾 Начинаю сохранение КП...');
    
      // 1. Обновляем объект Quote из контроллеров
      _quote.clientName = _clientNameController.text;
      _quote.clientEmail = _clientEmailController.text;
      _quote.clientPhone = _clientPhoneController.text;
      _quote.clientAddress = _clientAddressController.text;
      _quote.projectName = _projectNameController.text;
      _quote.projectDescription = _projectDescriptionController.text;
      _quote.notes = _notesController.text;
      _quote.updatedAt = DateTime.now();

      // 2. Рассчитываем общую сумму
      _quote.totalAmount = _quote.items.fold(0.0, (sum, item) {
        return sum + (item.quantity * item.price);
      });
    
      print('📊 Данные КП подготовлены: ${_quote.clientName}, сумма: ${_quote.totalAmount}');

      if (_quote.id == null) {
        // СОЗДАНИЕ НОВОГО КП
        print('🆕 Создаю новое КП...');
        final quoteId = await _dbHelper.insertQuote(_quote);
        _quote.id = quoteId;
        print('✅ КП создано с ID: $quoteId');

        // Сохраняем позиции
        print('📦 Сохраняю позиции...');
        for (final item in _quote.items) {
          item.quoteId = quoteId;
          final itemId = await _dbHelper.insertLineItem(item);
          item.id = itemId;
          print('  ✅ Позиция: ${item.description} (ID: $itemId)');
        }
      } else {
        // ОБНОВЛЕНИЕ СУЩЕСТВУЮЩЕГО КП
        print('✏️ Обновляю существующее КП ID: ${_quote.id}');
        await _dbHelper.updateQuote(_quote);
      
        // Удаляем старые позиции
        print('🗑️ Удаляю старые позиции...');
        await _dbHelper.deleteLineItemsForQuote(_quote.id!);
      
        // Добавляем новые позиции
        print('📦 Добавляю новые позиции...');
        for (final item in _quote.items) {
          item.quoteId = _quote.id!;
          final itemId = await _dbHelper.insertLineItem(item);
          item.id = itemId;
          print('  ✅ Позиция: ${item.description}');
        }
      }

      print('🎉 КП успешно сохранено!');
    
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ КП успешно сохранено'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Возвращаемся назад через секунду
      await Future.delayed(const Duration(seconds: 1));
    
      if (mounted) {
        Navigator.pop(context, true);
      }

    } catch (e) {
      print('❌ ОШИБКА СОХРАНЕНИЯ: $e');
      log('Ошибка сохранения', error: e, stackTrace: StackTrace.current);
    
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка сохранения: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
      _quote.items.add(newItem);
    });
  }

  void _editItem(int index) {
    if (index >= _quote.items.length) return;
    
    final item = _quote.items[index];
    final descriptionController = TextEditingController(text: item.description);
    final quantityController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(text: item.price.toString());
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
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Количество'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Цена'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
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
                final updatedItem = LineItem(
                  id: item.id,
                  quoteId: item.quoteId,
                  description: descriptionController.text,
                  quantity: double.tryParse(quantityController.text) ?? 1.0,
                  price: double.tryParse(priceController.text) ?? 0.0,
                  unit: unitController.text,
                  name: item.name,
                );
                
                setState(() {
                  _quote.items[index] = updatedItem;
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
    if (index >= _quote.items.length) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить позицию?'),
        content: Text('Удалить "${_quote.items[index].description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _quote.items.removeAt(index);
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
              for (final item in selectedItems) {
                _quote.items.add(LineItem(
                  quoteId: _quote.id ?? 0,
                  description: item.description,
                  quantity: item.quantity,
                  price: item.price,
                  unit: item.unit,
                  name: item.name,
                ));
              }
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _previewPdf() async {
    if (_quote.items.isEmpty) {
      _showError('Добавьте хотя бы одну позицию');
      return;
    }

    try {
      final pdfBytes = await _pdfService.generateQuotePdf(_quote, _quote.items);
      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
    } catch (e) {
      _showError('Ошибка PDF: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 0,
    ).format(amount);
  }

  Widget _buildItemCard(int index) {
    if (index >= _quote.items.length) return const SizedBox();
    
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
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => _editItem(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => _deleteItem(index),
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
            tooltip: 'PDF',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveQuote,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Кнопки действий - ГОРИЗОНТАЛЬНЫЙ СКРОЛЛ
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showQuickAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Быстрое добавление', style: TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _addNewItem,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Добавить позицию', style: TextStyle(fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_quote.items.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => setState(() { _quote.items.clear(); }),
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Очистить все', style: TextStyle(fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Информация о клиенте
                    const Text('Клиент:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _clientNameController,
                      decoration: const InputDecoration(
                        labelText: 'Имя клиента *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _clientEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _clientPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Телефон',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _clientAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Адрес',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    
                    // Информация о проекте
                    const Text('Проект:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _projectNameController,
                      decoration: const InputDecoration(
                        labelText: 'Название проекта',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _projectDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Описание работ',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    
                    // Позиции
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Позиции:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_quote.items.length} позиций'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (_quote.items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.list, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Нет позиций', style: TextStyle(color: Colors.grey)),
                              Text('Добавьте позиции кнопками выше', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          ...List.generate(_quote.items.length, (index) => _buildItemCard(index)),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ИТОГО:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  _formatCurrency(_quote.totalAmount),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Примечания
                    const Text('Примечания:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Дополнительные заметки',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    
                    // Кнопка сохранения
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveQuote,
                        icon: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Сохранение...' : 'Сохранить КП'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
