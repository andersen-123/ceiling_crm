import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../data/database_helper.dart';
import '../services/pdf_service.dart';
import '../services/template_service.dart';

class QuoteEditScreen extends StatefulWidget {
  final Quote? quote;

  const QuoteEditScreen({super.key, this.quote});

  @override
  QuoteEditScreenState createState() => QuoteEditScreenState();
}

class QuoteEditScreenState extends State<QuoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final PdfService _pdfService = PdfService();
  final TemplateService _templateService = TemplateService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Контроллеры для полей ввода
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _customerEmailController = TextEditingController();
  final TextEditingController _objectNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _areaSController = TextEditingController();
  final TextEditingController _perimeterPController = TextEditingController();
  final TextEditingController _heightHController = TextEditingController();
  final TextEditingController _ceilingSystemController = TextEditingController();
  final TextEditingController _paymentTermsController = TextEditingController();
  final TextEditingController _installationTermsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Списки позиций работ и оборудования
  List<LineItem> _workItems = [];
  List<LineItem> _equipmentItems = [];
  
  // Суммы
  double _subtotalWork = 0.0;
  double _subtotalEquipment = 0.0;
  double _totalAmount = 0.0;

  // Единицы измерения для выпадающего списка
  final List<String> _units = ['m²', 'm.p.', 'шт.', 'пог. м', 'компл.', 'усл.'];
  
  // Шаблоны для автозаполнения
  final List<Map<String, dynamic>> _workTemplates = [
    {'description': 'Монтаж натяжного потолка', 'unit': 'm²', 'price': 0.0},
    {'description': 'Обход трубы', 'unit': 'шт.', 'price': 0.0},
    {'description': 'Установка люстры/светильника', 'unit': 'шт.', 'price': 0.0},
    {'description': 'Установка карниза', 'unit': 'м.п.', 'price': 0.0},
  ];

  // Данные шаблонов
  List<Map<String, dynamic>> _paymentTemplates = [];
  List<Map<String, dynamic>> _workTemplateList = [];

  @override
  void initState() {
    super.initState();
    
    // Если редактируем существующее КП, заполняем поля
    if (widget.quote != null) {
      final quote = widget.quote!;
      _customerNameController.text = quote.customerName;
      _customerPhoneController.text = quote.customerPhone ?? '';
      _customerEmailController.text = quote.customerEmail ?? '';
      _objectNameController.text = quote.objectName;
      _addressController.text = quote.address ?? '';
      _areaSController.text = quote.areaS?.toString() ?? '';
      _perimeterPController.text = quote.perimeterP?.toString() ?? '';
      _heightHController.text = quote.heightH?.toString() ?? '';
      _ceilingSystemController.text = quote.ceilingSystem ?? '';
      _paymentTermsController.text = quote.paymentTerms ?? '';
      _installationTermsController.text = quote.installationTerms ?? '';
      _notesController.text = quote.notes ?? '';
      
      _subtotalWork = quote.subtotalWork;
      _subtotalEquipment = quote.subtotalEquipment;
      _totalAmount = quote.totalAmount;
      
      // Загружаем позиции если редактируем существующее КП
      if (quote.id != null) {
        _loadLineItems();
      }
    }
    
    // Загружаем шаблоны
    _loadTemplates();
  }

  // Загрузка позиций из базы данных
  Future<void> _loadLineItems() async {
    if (widget.quote == null || widget.quote!.id == null) return;
    
    try {
      final items = await _dbHelper.getLineItemsForQuote(widget.quote!.id!);
      
      setState(() {
        _workItems = items.where((item) => item.section == 'work').toList();
        _equipmentItems = items.where((item) => item.section == 'equipment').toList();
        _recalculateTotals();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки позиций: $error'), backgroundColor: Colors.red),
      );
    }
  }

  // Загрузка шаблонов
  Future<void> _loadTemplates() async {
    try {
      await _templateService.initializeTemplates();
      _paymentTemplates = await _templateService.getTemplatesByType(TemplateService.typePayment);
      _workTemplateList = await _templateService.getTemplatesByType(TemplateService.typeWork);
    } catch (error) {
      // Не критично, можно работать без шаблонов
      print('Ошибка загрузки шаблонов: $error');
    }
  }

  // Метод для выбора шаблона условий оплаты
  Future<void> _selectPaymentTemplate() async {
    if (_paymentTemplates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет доступных шаблонов условий оплаты'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedTemplate = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите шаблон условий оплаты'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _paymentTemplates.length,
            itemBuilder: (context, index) {
              final template = _paymentTemplates[index];
              return ListTile(
                title: Text(template['title'] as String),
                subtitle: Text(
                  (template['content'] as String).length > 50
                      ? '${(template['content'] as String).substring(0, 50)}...'
                      : template['content'] as String,
                ),
                onTap: () => Navigator.pop(context, template),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (selectedTemplate != null) {
      setState(() {
        _paymentTermsController.text = selectedTemplate['content'] as String;
      });
    }
  }

  // Метод для быстрого добавления работы из шаблона
  Future<void> _addWorkFromTemplate() async {
    if (_workTemplateList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет доступных шаблонов работ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedTemplate = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите шаблон работы'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _workTemplateList.length,
            itemBuilder: (context, index) {
              final template = _workTemplateList[index];
              return ListTile(
                title: Text(template['title'] as String),
                subtitle: Text(
                  template['content'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(context, template),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (selectedTemplate != null) {
      setState(() {
        final newItem = LineItem(
          quoteId: widget.quote?.id ?? 0,
          position: _workItems.length + 1,
          section: 'work',
          description: selectedTemplate['content'] as String,
          unit: 'шт.',
          quantity: 1,
          price: 0,
        );
        _workItems.add(newItem);
        _recalculateTotals();
      });
    }
  }

  // Обновляем метод _saveQuote для сохранения позиций
  Future<void> _saveQuote() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Создаем или обновляем Quote
        final quote = Quote(
          id: widget.quote?.id,
          customerName: _customerNameController.text,
          customerPhone: _customerPhoneController.text.isNotEmpty ? _customerPhoneController.text : null,
          customerEmail: _customerEmailController.text.isNotEmpty ? _customerEmailController.text : null,
          objectName: _objectNameController.text,
          address: _addressController.text.isNotEmpty ? _addressController.text : null,
          areaS: double.tryParse(_areaSController.text.replaceAll(',', '.')),
          perimeterP: double.tryParse(_perimeterPController.text.replaceAll(',', '.')),
          heightH: double.tryParse(_heightHController.text.replaceAll(',', '.')),
          ceilingSystem: _ceilingSystemController.text.isNotEmpty ? _ceilingSystemController.text : null,
          status: widget.quote?.status ?? 'draft',
          currencyCode: widget.quote?.currencyCode ?? 'RUB',
          subtotalWork: _subtotalWork,
          subtotalEquipment: _subtotalEquipment,
          totalAmount: _totalAmount,
          paymentTerms: _paymentTermsController.text.isNotEmpty ? _paymentTermsController.text : null,
          installationTerms: _installationTermsController.text.isNotEmpty ? _installationTermsController.text : null,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        );

        int quoteId;
        if (quote.id == null) {
          quoteId = await _dbHelper.insertQuote(quote);
        } else {
          await _dbHelper.updateQuote(quote);
          quoteId = quote.id!;
          
          // Удаляем старые позиции перед сохранением новых
          final oldItems = await _dbHelper.getLineItemsForQuote(quoteId);
          for (final item in oldItems) {
            await _dbHelper.deleteLineItem(item.id!);
          }
        }

        // Сохраняем все позиции
        int position = 1;
        for (final item in _workItems) {
          await _dbHelper.insertLineItem(item.copyWith(
            quoteId: quoteId,
            position: position++,
          ));
        }
        
        for (final item in _equipmentItems) {
          await _dbHelper.insertLineItem(item.copyWith(
            quoteId: quoteId,
            position: position++,
          ));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.quote == null 
                ? 'КП успешно создано' 
                : 'КП успешно обновлено'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true); // Возвращаем true для обновления списка
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Метод для экспорта в PDF
  Future<void> _exportToPdf() async {
    // Проверяем, сохранено ли КП
    if (widget.quote == null || widget.quote!.id == null) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Сначала сохраните КП'),
          content: const Text('Для экспорта в PDF необходимо сначала сохранить коммерческое предложение.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Сохранить и экспортировать'),
            ),
          ],
        ),
      );

      if (shouldSave == true) {
        await _saveQuote();
        if (widget.quote?.id != null) {
          _performPdfExport();
        }
      }
    } else {
      _performPdfExport();
    }
  }

  // Метод для выполнения экспорта в PDF
  Future<void> _performPdfExport() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Генерация PDF...'),
            ],
          ),
        ),
      );

      final dbHelper = DatabaseHelper();
      final quote = await dbHelper.getQuoteById(widget.quote!.id!);
      
      if (quote == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось найти КП для экспорта'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final pdfBytes = await _pdfService.generateQuotePdf(quote);
      Navigator.pop(context);

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF готов'),
          content: const Text('Выберите действие с документом:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _previewPdf(pdfBytes);
              },
              child: const Text('Предпросмотр'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _sharePdf(pdfBytes, quote);
              },
              child: const Text('Поделиться'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _savePdfToFile(pdfBytes, quote);
              },
              child: const Text('Сохранить в файл'),
            ),
          ],
        ),
      );
    } catch (error) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка генерации PDF: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Метод для предпросмотра PDF
  Future<void> _previewPdf(Uint8List pdfBytes) async {
    try {
      await _pdfService.previewPdf(context, widget.quote!);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка предпросмотра: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Метод для шаринга PDF
  Future<void> _sharePdf(Uint8List pdfBytes, Quote quote) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/КП_${quote.id}_${quote.customerName}.pdf');
      await file.writeAsBytes(pdfBytes);

      final uri = Uri(
        scheme: 'file',
        path: file.path,
      );

      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка шаринга: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Метод для сохранения PDF в файл
  Future<void> _savePdfToFile(Uint8List pdfBytes, Quote quote) async {
    try {
      final directory = await getDownloadsDirectory() ?? await getTemporaryDirectory();
      final fileName = 'КП_${quote.id}_${quote.customerName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(pdfBytes);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF сохранен: ${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Добавление новой позиции в раздел
  void _addLineItem(String section) {
    setState(() {
      final newItem = LineItem(
        quoteId: widget.quote?.id ?? 0,
        position: section == 'work' ? _workItems.length + 1 : _equipmentItems.length + 1,
        section: section,
        description: '',
        unit: 'm²',
        quantity: 0,
        price: 0,
      );
      
      if (section == 'work') {
        _workItems.add(newItem);
      } else {
        _equipmentItems.add(newItem);
      }
    });
  }

  // Удаление позиции
  void _removeLineItem(String section, int index) {
    setState(() {
      if (section == 'work') {
        _workItems.removeAt(index);
        for (int i = 0; i < _workItems.length; i++) {
          _workItems[i] = _workItems[i].copyWith(position: i + 1);
        }
      } else {
        _equipmentItems.removeAt(index);
        for (int i = 0; i < _equipmentItems.length; i++) {
          _equipmentItems[i] = _equipmentItems[i].copyWith(position: i + 1);
        }
      }
      _recalculateTotals();
    });
  }

  // Обновление позиции
  void _updateLineItem(String section, int index, LineItem updatedItem) {
    setState(() {
      if (section == 'work') {
        _workItems[index] = updatedItem;
      } else {
        _equipmentItems[index] = updatedItem;
      }
      _recalculateTotals();
    });
  }

  // Пересчет итогов
  void _recalculateTotals() {
    double workTotal = 0.0;
    double equipmentTotal = 0.0;
    
    for (final item in _workItems) {
      workTotal += item.amount;
    }
    
    for (final item in _equipmentItems) {
      equipmentTotal += item.amount;
    }
    
    setState(() {
      _subtotalWork = workTotal;
      _subtotalEquipment = equipmentTotal;
      _totalAmount = workTotal + equipmentTotal;
    });
  }

  // Метод для быстрого добавления из шаблона
  void _addFromTemplate(Map<String, dynamic> template, String section) {
    setState(() {
      final newItem = LineItem(
        quoteId: widget.quote?.id ?? 0,
        position: section == 'work' ? _workItems.length + 1 : _equipmentItems.length + 1,
        section: section,
        description: template['description'],
        unit: template['unit'],
        quantity: 1,
        price: template['price'],
      );
      
      if (section == 'work') {
        _workItems.add(newItem);
      } else {
        _equipmentItems.add(newItem);
      }
      _recalculateTotals();
    });
  }

  // Вспомогательный метод для создания текстовых полей
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Это поле обязательно для заполнения';
          }
          return null;
        },
      ),
    );
  }

  // Поле условий оплаты с выбором шаблона
  Widget _buildPaymentTermsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextFormField(
          controller: _paymentTermsController,
          labelText: 'Условия оплаты',
          maxLines: 3,
          suffixIcon: _paymentTemplates.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.format_quote),
                  onPressed: _selectPaymentTemplate,
                  tooltip: 'Выбрать из шаблонов',
                )
              : null,
        ),
        if (_paymentTemplates.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              'Доступно шаблонов: ${_paymentTemplates.length}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  // Вспомогательный метод для создания заголовков секций
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildLineItemsSection() {
    return Column(
      children: [
        // Раздел: Работы
        _buildSectionHeader('Работы'),
        _buildLineItemsList('work', _workItems),
        _buildAddButton('work'),
        
        // Итого по работам
        if (_workItems.isNotEmpty)
          _buildSubtotalRow('Работы:', _subtotalWork),
        
        const SizedBox(height: 16),
        
        // Раздел: Оборудование
        _buildSectionHeader('Оборудование'),
        _buildLineItemsList('equipment', _equipmentItems),
        _buildAddButton('equipment'),
        
        // Итого по оборудованию
        if (_equipmentItems.isNotEmpty)
          _buildSubtotalRow('Оборудование:', _subtotalEquipment),
        
        const SizedBox(height: 16),
        
        // Общий итог
        if (_workItems.isNotEmpty || _equipmentItems.isNotEmpty)
          _buildTotalRow(),
      ],
    );
  }

  // Виджет списка позиций
  Widget _buildLineItemsList(String section, List<LineItem> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          section == 'work' ? 'Нет работ' : 'Нет оборудования',
          style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildLineItemCard(section, index, items[index]);
      },
    );
  }

  // Карточка одной позиции
  Widget _buildLineItemCard(String section, int index, LineItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '${index + 1}.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.description,
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onChanged: (value) {
                      _updateLineItem(section, index, item.copyWith(description: value));
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                // Единица измерения
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: item.unit,
                    decoration: const InputDecoration(
                      labelText: 'Ед. изм.',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      _updateLineItem(section, index, item.copyWith(unit: value!));
                    },
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Количество
                Expanded(
                  child: TextFormField(
                    initialValue: item.quantity.toStringAsFixed(2),
                    decoration: const InputDecoration(
                      labelText: 'Кол-во',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final quantity = double.tryParse(value.replaceAll(',', '.')) ?? 0;
                      _updateLineItem(section, index, item.copyWith(quantity: quantity));
                    },
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Цена
                Expanded(
                  child: TextFormField(
                    initialValue: item.price.toStringAsFixed(2),
                    decoration: const InputDecoration(
                      labelText: 'Цена',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final price = double.tryParse(value.replaceAll(',', '.')) ?? 0;
                      _updateLineItem(section, index, item.copyWith(price: price));
                    },
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Сумма (только для отображения)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${item.amount.toStringAsFixed(2)} ₽',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Кнопка удаления
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeLineItem(section, index),
                  tooltip: 'Удалить позицию',
                ),
              ],
            ),
            
            // Поле для примечания
            const SizedBox(height: 8),
            TextFormField(
              initialValue: item.note,
              decoration: const InputDecoration(
                labelText: 'Примечание (опционально)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              maxLines: 1,
              onChanged: (value) {
                _updateLineItem(section, index, item.copyWith(note: value.isNotEmpty ? value : null));
              },
            ),
          ],
        ),
      ),
    );
  }

  // Кнопка добавления новой позиции
  Widget _buildAddButton(String section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () => _addLineItem(section),
            icon: const Icon(Icons.add),
            label: Text('Добавить ${section == 'work' ? 'работу' : 'оборудование'}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: section == 'work' ? Colors.blue.shade50 : Colors.green.shade50,
              foregroundColor: section == 'work' ? Colors.blue : Colors.green,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Кнопка быстрого добавления из шаблонов (только для работ)
          if (section == 'work')
            ElevatedButton.icon(
              onPressed: _addWorkFromTemplate,
              icon: const Icon(Icons.format_quote),
              label: const Text('Из шаблона'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade50,
                foregroundColor: Colors.purple,
              ),
            ),
        ],
      ),
    );
  }

  // Строка с промежуточным итогом
  Widget _buildSubtotalRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ₽',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  // Строка с общим итогом
  Widget _buildTotalRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'ИТОГО:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Text(
            '${_totalAmount.toStringAsFixed(2)} ₽',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quote == null ? 'Создание КП' : 'Редактирование КП'),
        actions: [
          if (widget.quote != null && widget.quote!.id != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _exportToPdf,
              tooltip: 'Экспорт в PDF',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveQuote,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Блок: Данные клиента
            _buildSectionHeader('Данные клиента'),
            _buildTextFormField(
              controller: _customerNameController,
              labelText: 'ФИО клиента *',
              isRequired: true,
            ),
            _buildTextFormField(
              controller: _customerPhoneController,
              labelText: 'Телефон',
              keyboardType: TextInputType.phone,
            ),
            _buildTextFormField(
              controller: _customerEmailController,
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),

            // Блок: Данные объекта
            _buildSectionHeader('Данные объекта'),
            _buildTextFormField(
              controller: _objectNameController,
              labelText: 'Название объекта *',
              hintText: 'Квартира, Дом, Офис...',
              isRequired: true,
            ),
            _buildTextFormField(
              controller: _addressController,
              labelText: 'Адрес',
              hintText: 'Город, улица, дом, квартира',
            ),

            // Блок: Параметры помещения
            _buildSectionHeader('Параметры помещения'),
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: _areaSController,
                    labelText: 'Площадь (м²)',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextFormField(
                    controller: _perimeterPController,
                    labelText: 'Периметр (м.п.)',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextFormField(
                    controller: _heightHController,
                    labelText: 'Высота (м)',
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            _buildTextFormField(
              controller: _ceilingSystemController,
              labelText: 'Тип потолочной системы',
              hintText: 'гарпун, теневой, парящий...',
            ),

            // Блок: Условия и примечания
            _buildSectionHeader('Условия и примечания'),
            _buildPaymentTermsField(),
            _buildTextFormField(
              controller: _installationTermsController,
              labelText: 'Условия и даты монтажа',
              maxLines: 3,
            ),
            _buildTextFormField(
              controller: _notesController,
              labelText: 'Прочие примечания',
              maxLines: 3,
            ),

            // Добавляем блоки работ и оборудования
            _buildLineItemsSection(),

            const SizedBox(height: 32),
            // Кнопка сохранения
            ElevatedButton.icon(
              onPressed: _saveQuote,
              icon: const Icon(Icons.save),
              label: const Text('Сохранить коммерческое предложение'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
