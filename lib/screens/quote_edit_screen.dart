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

  // 2. Контроллеры для ДИНАМИЧЕСКИХ полей позиций (КЛЮЧЕВОЕ ИСПРАВЛЕНИЕ)
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

    // ИНИЦИАЛИЗИРУЕМ КОНТРОЛЛЕРЫ ДЛЯ ПОЗИЦИЙ (важно!)
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
      // СОЗДАЁМ КОНТРОЛЛЕРЫ ДЛЯ НОВОЙ ПОЗИЦИИ
      _descriptionControllers.add(TextEditingController(text: 'Новая позиция'));
      _quantityControllers.add(TextEditingController(text: '1'));
      _priceControllers.add(TextEditingController(text: '0'));
    });
  }

  // 11. Удаление позиции
  void _deleteLineItem(int index) {
    setState(() {
      // УНИЧТОЖАЕМ КОНТРОЛЛЕРЫ УДАЛЯЕМОЙ ПОЗИЦИИ
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

  // 13. Экспорт в PDF
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

  // 14. Сохранение данных перед экспортом
  Future<void> _saveQuoteDataLocally() async {
    _currentQuote = _currentQuote.copyWith(totalAmount: _calculateTotal());
    if (_currentQuote.id != null) {
      final dbHelper = DatabaseHelper();
      await dbHelper.updateQuote(_currentQuote);
    }
  }

  // 15. Диалог экспорта
  Future<void> _showExportDialog(File pdfFile) async {
    final result = await showDialog<ExportOption>(
      context: context,
      builder: (context) => ExportDialog(pdfFile: pdfFile),
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

  // 16. Просмотр PDF
  Future<void> _previewPdf(File pdfFile) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Просмотр PDF будет доступен позже')),
    );
  }

  // 17. Поделиться PDF
  Future<void> _sharePdf(File pdfFile) async {
    final uri = Uri.file(pdfFile.path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть диалог шаринга')),
      );
    }
  }

  // 18. Сохранить PDF в папку загрузок
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
        SnackBar(content: Text('PDF сохранён: $fileName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  // 19. Построение UI (ОБЯЗАТЕЛЬНЫЙ МЕТОД ДЛЯ State)
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

  // 20. Основное содержимое
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

  // 21. Секция информации о клиенте
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

  // 22. Секция позиций КП
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

  // 23. Карточка позиции
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
                      '${index + 1}. ${item.description}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${item.total.toStringAsFixed(2)} ₽',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildLineItemFields(index, item),
            ],
          ),
        ),
      ),
    );
  }

  // 24. Поля редактирования позиции (ИСПРАВЛЕННАЯ ВЕРСИЯ)
  Widget _buildLineItemFields(int index, LineItem item) {
    return Column(
      children: [
        // Раздел
        DropdownButtonFormField<String>(
          value: item.section,
          decoration: const InputDecoration(
            labelText: 'Раздел',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const ['Работы', 'Материалы', 'Оборудование', 'Прочее']
              .map((section) {
            return DropdownMenuItem(
              value: section,
              child: Text(section),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _lineItems[index] = item.copyWith(section: value!);
            });
          },
        ),
        const SizedBox(height: 8),

        // Описание (используем сохранённый контроллер)
        TextField(
          controller: _descriptionControllers[index],
          decoration: const InputDecoration(
            labelText: 'Описание',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          maxLines: 2,
          onChanged: (value) {
            setState(() {
              _lineItems[index] = item.copyWith(description: value);
            });
          },
        ),
        const SizedBox(height: 8),

        // Количество, цена и единица измерения
        Row(
          children: [
            // Количество (используем сохранённый контроллер)
            Expanded(
              child: TextField(
                controller: _quantityControllers[index],
                decoration: const InputDecoration(
                  labelText: 'Кол-во',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final qty = double.tryParse(value) ?? 0;
                  setState(() {
                    _lineItems[index] = item.copyWith(quantity: qty);
                    _recalculateQuoteTotal();
                  });
                },
              ),
            ),
            const SizedBox(width: 8),

            // Единица измерения
            Expanded(
              child: DropdownButtonFormField<String>(
                value: item.unit,
                decoration: const InputDecoration(
                  labelText: 'Ед.',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const ['шт.', 'м²', 'п.м.', 'компл.', 'час']
                    .map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _lineItems[index] = item.copyWith(unit: value!);
                  });
                },
              ),
            ),
            const SizedBox(width: 8),

            // Цена за единицу (используем сохранённый контроллер)
            Expanded(
              child: TextField(
                controller: _priceControllers[index],
                decoration: const InputDecoration(
                  labelText: 'Цена',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  prefixText: '₽ ',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value) ?? 0;
                  setState(() {
                    _lineItems[index] = item.copyWith(unitPrice: price);
                    _recalculateQuoteTotal();
                  });
                },
              ),
            ),
          ],
        ),
      ],
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
