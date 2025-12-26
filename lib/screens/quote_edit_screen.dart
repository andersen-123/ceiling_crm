// lib/screens/quote_edit_screen.dart
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../services/pdf_service.dart';
import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../data/database_helper.dart';

class QuoteEditScreen extends StatefulWidget {
  final Quote? existingQuote; // Если null — создание нового КП

  const QuoteEditScreen({Key? key, this.existingQuote}) : super(key: key);

  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  // 1. Контроллеры для полей формы
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // 2. Значения выпадающих списков
  String _selectedStatus = 'Черновик';
  final List<String> _statusOptions = [
    'Черновик',
    'Отправлен',
    'В работе',
    'Подписан',
    'Отменён'
  ];

  // 3. Данные КП
  late Quote _currentQuote;
  final List<LineItem> _lineItems = [];
  
  // 4. Состояние загрузки
bool _isLoading = true;
bool _isSaving = false;

// 5. Контроллеры для полей позиций (ДОБАВЬТЕ ЭТО)
final List<TextEditingController> _descriptionControllers = [];
final List<TextEditingController> _quantityControllers = [];
final List<TextEditingController> _priceControllers = [];

  // 5. Инициализация
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // 6. Инициализация данных
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    if (widget.existingQuote != null) {
      // Редактирование существующего КП
      _currentQuote = widget.existingQuote!;
      
      // Загружаем позиции из БД
      final items = await DatabaseHelper().getLineItemsForQuote(_currentQuote.id!);
      setState(() => _lineItems.addAll(items));

      // ИНИЦИАЛИЗАЦИЯ КОНТРОЛЛЕРОВ (ДОБАВЬТЕ ЭТОТ БЛОК)
      _descriptionControllers.clear();
      _quantityControllers.clear();
      _priceControllers.clear();

      for (final item in _lineItems) {
        _descriptionControllers.add(TextEditingController(text: item.description));
        _quantityControllers.add(TextEditingController(text: item.quantity.toString()));
        _priceControllers.add(TextEditingController(text: item.unitPrice.toStringAsFixed(2)));
      }
    } else {
      // Создание нового КП
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
    
    // Заполняем контроллеры
    _customerNameController.text = _currentQuote.customerName;
    _customerPhoneController.text = _currentQuote.customerPhone;
    _addressController.text = _currentQuote.address;
    _notesController.text = _currentQuote.notes;
    _selectedStatus = _currentQuote.status;
    
    setState(() => _isLoading = false);
  }

  // 7. Рассчитать общую сумму
  double _calculateTotal() {
    return _lineItems.fold(0.0, (sum, item) => sum + item.total);
  }

  // 8. Сохранение КП
  Future<void> _saveQuote() async {
    // Валидация
    if (_customerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя клиента')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Обновляем данные КП
      _currentQuote = _currentQuote.copyWith(
        customerName: _customerNameController.text,
        customerPhone: _customerPhoneController.text,
        address: _addressController.text,
        totalAmount: _calculateTotal(),
        prepayment: _currentQuote.prepayment,
        status: _selectedStatus,
        notes: _notesController.text,
      );

      // Сохраняем в БД
      final dbHelper = DatabaseHelper();
      int quoteId;

      if (_currentQuote.id == null) {
        // Новый КП
        quoteId = await dbHelper.insertQuote(_currentQuote);
        _currentQuote = _currentQuote.copyWith(id: quoteId);
      } else {
        // Обновление существующего
        await dbHelper.updateQuote(_currentQuote);
        quoteId = _currentQuote.id!;
      }

      // Сохраняем позиции
      await _saveLineItems(quoteId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_currentQuote.id == null 
          ? 'КП создан' 
          : 'КП обновлён')),
      );

      Navigator.pop(context, true); // Возвращаемся с флагом успеха

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
  
  // Получаем текущие позиции из БД
  final existingItems = await dbHelper.getLineItemsForQuote(quoteId);
  
  // Удаляем старые позиции, которых нет в новом списке
  for (final existingItem in existingItems) {
    if (!_lineItems.any((item) => item.id == existingItem.id)) {
      await dbHelper.deleteLineItem(existingItem.id!);
    }
  }
  
  // Сохраняем или обновляем позиции
  for (final item in _lineItems) {
    if (item.id == null) {
      // Новая позиция
      await dbHelper.insertLineItem(item.copyWith(quoteId: quoteId));
    } else {
      // Обновление существующей
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
    
      // ДОБАВЬТЕ ЭТИ ТРИ СТРОКИ:
      _descriptionControllers.add(TextEditingController(text: 'Новая позиция'));
      _quantityControllers.add(TextEditingController(text: '1'));
      _priceControllers.add(TextEditingController(text: '0'));
    });
  }
    });
  }
  // 11. Удаление позиции
  void _deleteLineItem(int index) {
    setState(() {
      _lineItems.removeAt(index);
      _recalculateQuoteTotal(); // Обновляем итоговую сумму
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
      // Сохраняем текущие изменения
      await _saveQuoteDataLocally();
    
      // Генерируем PDF
      final pdfService = PdfService();
      final pdfFile = await pdfService.generateQuotePdf(_currentQuote, _lineItems);
    
      // Показываем диалог с опциями
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
    // Обновляем итоговую сумму
    _currentQuote = _currentQuote.copyWith(totalAmount: _calculateTotal());
  
    // Если КП уже сохранён в БД, обновляем его
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
    // TODO: Реализовать просмотр через пакет printing
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
  // 12. Построение UI
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingQuote == null 
          ? 'Новое КП' 
          : 'Редактирование КП'),
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

  // 13. Основное содержимое
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Блок информации о клиенте
          _buildClientInfoSection(),
          const SizedBox(height: 24),
          
          // Блок позиций КП
          _buildLineItemsSection(),
          const SizedBox(height: 24),
          
          // Блок итогов
          _buildTotalsSection(),
          const SizedBox(height: 24),
          
          // Блок примечаний
          _buildNotesSection(),
        ],
      ),
    );
  }

  // 14. Секция информации о клиенте
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
            prefixIcon: const Icon(Icons.label_important),
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

  // 15. Секция позиций КП
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

  // 16. Карточка позиции
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

  // 17. Поля редактирования позиции
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
      
        // Описание
        TextField(
          controller: TextEditingController(text: item.description),
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
            // Количество
            Expanded(
              child: TextField(
                controller: TextEditingController(text: item.quantity.toString()),
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
          
            // Цена за единицу
            Expanded(
              child: TextField(
                controller: TextEditingController(text: item.unitPrice.toStringAsFixed(2)),
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
  
  // 24. Секция итогов
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

  // 25. Секция примечаний
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

  // 26. Очистка контроллеров
  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

// ================ ВНЕ КЛАССА ================

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
