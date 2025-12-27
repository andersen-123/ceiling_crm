// lib/screens/quote_edit_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../data/database_helper.dart';
import '../services/pdf_service.dart';

class QuoteEditScreen extends StatefulWidget {
  final Quote? existingQuote;

  const QuoteEditScreen({Key? key, this.existingQuote}) : super(key: key);

  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  // 1. Контроллеры для основных полей формы
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // 2. Контроллеры для ДИНАМИЧЕСКИХ полей позиций
  final List<TextEditingController> _descriptionControllers = [];
  final List<TextEditingController> _quantityControllers = [];
  final List<TextEditingController> _priceControllers = [];

  // 3. Значения выпадающих списков
  String _selectedStatus = 'Черновик';
  final List<String> _statusOptions = [
    'Черновик',
    'Отправлен',
    'В работе',
    'Подписан',
    'Отменён'
  ];

  // 4. Данные КП
  late Quote _currentQuote;
  final List<LineItem> _lineItems = [];

  // 5. Состояние загрузки
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // 6. Инициализация данных
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    if (widget.existingQuote != null) {
      _currentQuote = widget.existingQuote!;
      final items = await DatabaseHelper().getLineItemsForQuote(_currentQuote.id!);
      setState(() => _lineItems.addAll(items));
    } else {
      _currentQuote = Quote(
        customerName: '',
        customerPhone: '',
        address: '',
        quoteDate: DateTime.now(),
        totalAmount: 0.0,
        prepayment: 0.0,
        status: 'Черновик',
        notes: '',
      );
    }

    // Заполняем основные контроллеры
    _customerNameController.text = _currentQuote.customerName;
    _customerPhoneController.text = _currentQuote.customerPhone;
    _addressController.text = _currentQuote.address;
    _notesController.text = _currentQuote.notes;
    _selectedStatus = _currentQuote.status;

    // Инициализируем контроллеры для позиций
    _descriptionControllers.clear();
    _quantityControllers.clear();
    _priceControllers.clear();
    for (final item in _lineItems) {
      _descriptionControllers.add(TextEditingController(text: item.description));
      _quantityControllers.add(TextEditingController(text: item.quantity.toString()));
      _priceControllers.add(TextEditingController(text: item.unitPrice.toStringAsFixed(2)));
    }

    setState(() => _isLoading = false);
  }

  // 7. Рассчитать общую сумму
  double _calculateTotal() {
    return _lineItems.fold(0.0, (sum, item) => sum + item.total);
  }

  // 8. Сохранение КП
  Future<void> _saveQuote() async {
    if (_customerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя клиента')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      _currentQuote = _currentQuote.copyWith(
        customerName: _customerNameController.text,
        customerPhone: _customerPhoneController.text,
        address: _addressController.text,
        totalAmount: _calculateTotal(),
        prepayment: _currentQuote.prepayment,
        status: _selectedStatus,
        notes: _notesController.text,
      );

      final dbHelper = DatabaseHelper();
      int quoteId;

      if (_currentQuote.id == null) {
        quoteId = await dbHelper.insertQuote(_currentQuote);
        _currentQuote = _currentQuote.copyWith(id: quoteId);
      } else {
        await dbHelper.updateQuote(_currentQuote);
        quoteId = _currentQuote.id!;
      }

      await _saveLineItems(quoteId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_currentQuote.id == null ? 'КП создан' : 'КП обновлён')),
      );

      Navigator.pop(context, true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // 9. Сохранение позиций
  Future<void> _saveLineItems(int quoteId) async {
    final dbHelper = DatabaseHelper();
    final existingItems = await dbHelper.getLineItemsForQuote(quoteId);

    for (final existingItem in existingItems) {
      if (!_lineItems.any((item) => item.id == existingItem.id)) {
        await dbHelper.deleteLineItem(existingItem.id!);
      }
    }

    for (final item in _lineItems) {
      if (item.id == null) {
        await dbHelper.insertLineItem(item.copyWith(quoteId: quoteId));
      } else {
        await dbHelper.updateLineItem(item);
      }
    }
  }

  // 10. Добавление новой позиции
  void _addNewLineItem() {
    setState(() {
      _lineItems.add(LineItem(
        quoteId: _currentQuote.id ?? 0,
        section: 'Работы',
        description: 'Новая позиция',
        unit: 'шт.',
        quantity: 1,
        unitPrice: 0,
      ));
      // Создаём контроллеры для новой позиции
      _descriptionControllers.add(TextEditingController(text: 'Новая позиция'));
      _quantityControllers.add(TextEditingController(text: '1'));
      _priceControllers.add(TextEditingController(text: '0'));
    });
  }

  // 11. Удаление позиции
  void _deleteLineItem(int index) {
    setState(() {
      // Уничтожаем контроллеры удаляемой позиции
      _descriptionControllers[index].dispose();
      _quantityControllers[index].dispose();
      _priceControllers[index].dispose();

      _descriptionControllers.removeAt(index);
      _quantityControllers.removeAt(index);
      _priceControllers.removeAt(index);

      _lineItems.removeAt(index);
      _recalculateQuoteTotal();
    });
  }

  // 12. Пересчитать общую сумму КП
  void _recalculateQuoteTotal() {
    final newTotal = _calculateTotal();
    setState(() {
      _currentQuote = _currentQuote.copyWith(totalAmount: newTotal);
    });
  }

  // 13. Редактирование позиции в диалоге
  void _editLineItemDialog(int index, LineItem item) {
    final descriptionController = TextEditingController(text: item.description);
    final quantityController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(text: item.unitPrice.toStringAsFixed(2));
    String selectedSection = item.section;
    String selectedUnit = item.unit;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Редактировать позицию'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Раздел
                  DropdownButtonFormField<String>(
                    value: selectedSection,
                    decoration: const InputDecoration(
                      labelText: 'Раздел',
                      border: OutlineInputBorder(),
                    ),
                    items: const ['Работы', 'Материалы', 'Оборудование', 'Прочее']
                        .map((section) {
                      return DropdownMenuItem(
                        value: section,
                        child: Text(section),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() => selectedSection = value!);
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Описание
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  
                  // Количество и единица измерения
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          decoration: const InputDecoration(
                            labelText: 'Кол-во',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Ед.',
                            border: OutlineInputBorder(),
                          ),
                          items: const ['шт.', 'м²', 'п.м.', 'компл.', 'час']
                              .map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setStateDialog(() => selectedUnit = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Цена
                  TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Цена за единицу',
                      border: OutlineInputBorder(),
                      prefixText: '₽ ',
                    ),
                    keyboardType: TextInputType.number,
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
                  setState(() {
                    _lineItems[index] = item.copyWith(
                      section: selectedSection,
                      description: descriptionController.text,
                      unit: selectedUnit,
                      quantity: double.tryParse(quantityController.text) ?? 0,
                      unitPrice: double.tryParse(priceController.text) ?? 0,
                    );
                    _recalculateQuoteTotal();
                    
                    // Обновляем контроллеры
                    _descriptionControllers[index].text = descriptionController.text;
                    _quantityControllers[index].text = quantityController.text;
                    _priceControllers[index].text = priceController.text;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Позиция обновлена')),
                  );
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  // 14. Экспорт в PDF
  Future<void> _exportToPdf() async {
    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы одну позицию для экспорта')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _saveQuoteDataLocally();
      final pdfService = PdfService();
      final pdfFile = await pdfService.generateQuotePdf(_currentQuote, _lineItems);
      await _showExportDialog(pdfFile);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при создании PDF: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // 15. Сохранение данных перед экспортом
  Future<void> _saveQuoteDataLocally() async {
    _currentQuote = _currentQuote.copyWith(totalAmount: _calculateTotal());
    if (_currentQuote.id != null) {
      final dbHelper = DatabaseHelper();
      await dbHelper.updateQuote(_currentQuote);
    }
  }

  // 16. Диалог экспорта
  Future<void> _showExportDialog(File pdfFile) async {
    final result = await showDialog<ExportOption>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Экспорт КП'),
        content: const Text('Выберите действие с созданным PDF-документом:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ExportOption.preview),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.preview, size: 20),
                SizedBox(width: 8),
                Text('Просмотреть'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ExportOption.share),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.share, size: 20),
                SizedBox(width: 8),
                Text('Поделиться'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ExportOption.save),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save_alt, size: 20),
                SizedBox(width: 8),
                Text('Сохранить'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (result != null) {
      switch (result) {
        case ExportOption.preview:
          await _previewPdf(pdfFile);
          break;
        case ExportOption.share:
          await _sharePdf(pdfFile);
          break;
        case ExportOption.save:
          await _savePdf(pdfFile);
          break;
      }
    }
  }

  // 17. Просмотр PDF (улучшенная версия)
  Future<void> _previewPdf(File pdfFile) async {
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Предпросмотр PDF'),
        content: const Text('Функция предпросмотра временно недоступна. Хотите сохранить файл в папку "Загрузки"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    
    if (save == true) {
      await _savePdf(pdfFile);
    }
  }

  // 18. Поделиться PDF (исправленная версия)
  Future<void> _sharePdf(File pdfFile) async {
    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Поделиться PDF'),
          content: const Text('Функция "Поделиться" будет доступна в следующем обновлении. Пока вы можете:\n\n1. Сохранить файл (кнопка "Сохранить")\n2. Найти его в папке "Загрузки" на телефоне\n3. Поделиться оттуда через стандартные средства Android'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Для шаринга файлов нужно обновить приложение')),
      );
    }
  }

  // 19. Сохранить PDF в папку загрузок (улучшенная версия)
  Future<void> _savePdf(File pdfFile) async {
    try {
      final downloadsDirectory = await getDownloadsDirectory();
      if (downloadsDirectory == null) {
        throw Exception('Не удалось получить доступ к папке загрузок');
      }
      final fileName = 'КП_${_currentQuote.customerName}_${_currentQuote.id}.pdf'
          .replaceAll(RegExp(r'[^\w\d]'), '_');
      final newPath = '${downloadsDirectory.path}/$fileName';
      await pdfFile.copy(newPath);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✅ PDF успешно сохранён', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Файл: $fileName', style: const TextStyle(fontSize: 12)),
              Text('Папка: Загрузки', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'ОК',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  // 20. Построение UI
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingQuote == null ? 'Новое КП' : 'Редактирование КП'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isSaving ? null : _exportToPdf,
            tooltip: 'Экспорт в PDF',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveQuote,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  // 21. Основное содержимое
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClientInfoSection(),
          const SizedBox(height: 24),
          _buildLineItemsSection(),
          const SizedBox(height: 24),
          _buildTotalsSection(),
          const SizedBox(height: 24),
          _buildNotesSection(),
        ],
      ),
    );
  }

  // 22. Секция информации о клиенте
  Widget _buildClientInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Информация о клиенте',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _customerNameController,
          decoration: const InputDecoration(
            labelText: 'Имя клиента *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _customerPhoneController,
          decoration: const InputDecoration(
            labelText: 'Телефон',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Адрес',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedStatus,
          decoration: const InputDecoration(
            labelText: 'Статус',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.label_important),
          ),
          items: _statusOptions.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(status),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedStatus = value!);
          },
        ),
      ],
    );
  }

  // 23. Секция позиций КП (с упрощённым редактированием)
  Widget _buildLineItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Позиции КП',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _addNewLineItem,
              icon: const Icon(Icons.add),
              label: const Text('Добавить позицию'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_lineItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.list, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Нет добавленных позиций',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Нажмите "Добавить позицию"',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _lineItems.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) => _buildLineItemCard(index),
          ),
      ],
    );
  }

  // 24. Карточка позиции (с возможностью нажатия для редактирования)
  Widget _buildLineItemCard(int index) {
    final item = _lineItems[index];

    return Dismissible(
      key: Key('line_item_${item.id ?? index}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Удалить позицию?'),
            content: const Text('Позиция будет удалена из КП.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Удалить', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _deleteLineItem(index),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          onTap: () => _editLineItemDialog(index, item),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}. ${item.description}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.section,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${item.quantity} ${item.unit} × ${item.unitPrice} ₽',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.total.toStringAsFixed(2)} ₽',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Нажмите для редактирования',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 25. Секция итогов
  Widget _buildTotalsSection() {
    final total = _calculateTotal();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Итоги',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Общая сумма:', style: TextStyle(fontSize: 16)),
              Text(
                '${total.toStringAsFixed(2)} ₽',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Поле аванса
          TextFormField(
            initialValue: _currentQuote.prepayment.toStringAsFixed(2),
            decoration: const InputDecoration(
              labelText: 'Аванс',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.payment),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final prepayment = double.tryParse(value) ?? 0.0;
              setState(() {
                _currentQuote = _currentQuote.copyWith(prepayment: prepayment);
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Остаток к оплате:', style: TextStyle(fontSize: 16)),
              Text(
                '${(total - _currentQuote.prepayment).toStringAsFixed(2)} ₽',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 26. Секция примечаний
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Примечания',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Дополнительная информация',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  // 27. Очистка контроллеров
  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();

    // Уничтожаем все контроллеры для динамических полей
    for (final controller in _descriptionControllers) {
      controller.dispose();
    }
    for (final controller in _quantityControllers) {
      controller.dispose();
    }
    for (final controller in _priceControllers) {
      controller.dispose();
    }

    super.dispose();
  }
}

// ================ ВНЕ КЛАССА _QuoteEditScreenState ================

enum ExportOption { preview, share, save }

class ExportDialog extends StatelessWidget {
  final File pdfFile;

  const ExportDialog({Key? key, required this.pdfFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Экспорт КП'),
      content: const Text('Выберите действие с созданным PDF-документом:'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ExportOption.preview),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.preview, size: 20),
              SizedBox(width: 8),
              Text('Просмотреть'),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ExportOption.share),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.share, size: 20),
              SizedBox(width: 8),
              Text('Поделиться'),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ExportOption.save),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.save_alt, size: 20),
              SizedBox(width: 8),
              Text('Сохранить'),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
      ],
    );
  }
}
