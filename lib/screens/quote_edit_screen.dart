import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/repositories/quote_repository.dart';
import 'package:ceiling_crm/screens/edit_position_modal.dart';
import 'package:ceiling_crm/services/pdf_service.dart';

class QuoteEditScreen extends StatefulWidget {
  final int quoteId;

  const QuoteEditScreen({Key? key, required this.quoteId}) : super(key: key);

  @override
  _QuoteEditScreenState createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  final QuoteRepository _quoteRepo = QuoteRepository();
  final _formKey = GlobalKey<FormState>();
  
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _objectAddressController = TextEditingController();
  
  Quote? _currentQuote;
  List<LineItem> _lineItems = [];
  double _vatRate = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _objectAddressController.dispose();
    super.dispose();
  }
  
  Future<void> _exportToPdf() async {
    if (_currentQuote == null) return;
  
    try {
      // Показываем индикатор загрузки
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Генерируем PDF...'),
          duration: Duration(seconds: 2),
        ),
      );
    
      // Создаем обновленный quote с актуальными данными
      final updatedQuote = _currentQuote!.copyWith(
        total: _calculateTotal(),
        vatAmount: _calculateVatAmount(),
        totalWithVat: _calculateTotalWithVat(),
        vatRate: _vatRate,
      );
    
      // Генерируем и делимся PDF
      await PdfService.generateAndShareQuote(
        quote: updatedQuote,
        lineItems: _lineItems,
        context: context,
      );
    
    } catch (e) {
      print('❌ Ошибка PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при создании PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _loadQuote() async {
    final quote = await _quoteRepo.getQuoteById(widget.quoteId);
    if (quote != null) {
      setState(() {
        _currentQuote = quote;
        _clientNameController.text = quote.clientName;
        _clientPhoneController.text = quote.clientPhone ?? '';
        _objectAddressController.text = quote.objectAddress ?? '';
        _vatRate = quote.vatRate ?? 0.0;
      });
      
      // Загружаем позиции
      final items = await _quoteRepo.getLineItems(widget.quoteId);
      setState(() {
        _lineItems = items;
      });
    }
  }

  Future<void> _saveQuote() async {
    if (_formKey.currentState!.validate()) {
      final updatedQuote = Quote(
        id: _currentQuote!.id,
        clientName: _clientNameController.text.trim(),
        clientPhone: _clientPhoneController.text.trim().isNotEmpty 
            ? _clientPhoneController.text.trim() 
            : null,
        objectAddress: _objectAddressController.text.trim().isNotEmpty
            ? _objectAddressController.text.trim()
            : null,
        status: _currentQuote?.status ?? 'draft',
        createdAt: _currentQuote!.createdAt,
        total: _calculateTotal(),
        vatRate: _vatRate,
        vatAmount: _calculateVatAmount(),
        totalWithVat: _calculateTotalWithVat(),
      );

      try {
        await _quoteRepo.updateQuote(updatedQuote);
        
        setState(() {
          _currentQuote = updatedQuote;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('КП сохранено')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  Future<void> _updateQuoteStatus(String status) async {
    if (_currentQuote != null) {
      final updatedQuote = _currentQuote!.copyWith(status: status);
      await _quoteRepo.updateQuote(updatedQuote);
      setState(() {
        _currentQuote = updatedQuote;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Статус изменен на: ${_getStatusText(status)}')),
      );
    }
  }

  Future<void> _addNewPosition() async {
    final newItem = LineItem(
      quoteId: widget.quoteId,
      name: 'Новая позиция',
      unit: 'шт.',
      price: 0.0,
      quantity: 1.0,
    );
    
    final id = await _quoteRepo.addLineItem(newItem);
    setState(() {
      _lineItems.add(newItem.copyWith(id: id));
    });
  }

  Future<void> _editPosition(int index) async {
    final item = _lineItems[index];
    final result = await showDialog<LineItem>(
      context: context,
      builder: (context) => EditPositionModal(
        initialItem: item,
      ),
    );
    
    if (result != null) {
      final updatedItem = result.copyWith(id: item.id, quoteId: item.quoteId);
      await _quoteRepo.updateLineItem(updatedItem);
      
      setState(() {
        _lineItems[index] = updatedItem;
      });
    }
  }

  Future<void> _deletePosition(int index) async {
    final item = _lineItems[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить позицию'),
        content: Text('Вы уверены, что хотите удалить "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && item.id != null) {
      await _quoteRepo.deleteLineItem(item.id!);
      setState(() {
        _lineItems.removeAt(index);
      });
    }
  }

  double _calculateTotal() {
    double total = 0;
    for (final item in _lineItems) {
      total += item.price * item.quantity;
    }
    return total;
  }

  double _calculateVatAmount() {
    return _calculateTotal() * (_vatRate / 100);
  }

  double _calculateTotalWithVat() {
    return _calculateTotal() + _calculateVatAmount();
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted': return 'Принят';
      case 'rejected': return 'Отклонен';
      case 'pending': return 'На рассмотрении';
      default: return 'Черновик';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQuote == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('КП #${_currentQuote!.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveQuote,
            tooltip: 'Сохранить',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
            tooltip: 'Экспорт в PDF',
          ),
          PopupMenuButton<String>(
            onSelected: _updateQuoteStatus,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'draft',
                child: Text('Черновик'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('На рассмотрении'),
              ),
              const PopupMenuItem(
                value: 'accepted',
                child: Text('Принят'),
              ),
              const PopupMenuItem(
                value: 'rejected',
                child: Text('Отклонен'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Форма редактирования КП
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Информация о клиенте
                    _buildSectionHeader('Информация о клиенте'),
                    _buildTextField(
                      controller: _clientNameController,
                      label: 'Имя клиента *',
                      icon: Icons.person,
                      required: true,
                    ),
                    _buildTextField(
                      controller: _clientPhoneController,
                      label: 'Телефон',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      controller: _objectAddressController,
                      label: 'Адрес объекта',
                      icon: Icons.location_on,
                    ),

                    // Позиции
                    _buildSectionHeader('Позиции'),
                    ..._lineItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildPositionCard(item, index);
                    }).toList(),

                    // Кнопка добавления позиции
                    OutlinedButton.icon(
                      onPressed: _addNewPosition,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить позицию'),
                    ),

                    // Итоги
                    _buildSectionHeader('Итоги'),
                    _buildTotalCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'Это поле обязательно';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPositionCard(LineItem item, int index) {
    final total = item.price * item.quantity;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.quantity} ${item.unit} × ${NumberFormat.currency(locale: 'ru_RU', symbol: '₽').format(item.price)}'),
            Text(
              'Итого: ${NumberFormat.currency(locale: 'ru_RU', symbol: '₽').format(total)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _editPosition(index),
              tooltip: 'Редактировать',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deletePosition(index),
              tooltip: 'Удалить',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    final total = _calculateTotal();
    final vatAmount = _calculateVatAmount();
    final totalWithVat = _calculateTotalWithVat();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('Сумма:', total),
            _buildTotalRow('НДС (${_vatRate}%):', vatAmount),
            const Divider(),
            _buildTotalRow('ИТОГО с НДС:', totalWithVat, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            NumberFormat.currency(locale: 'ru_RU', symbol: '₽').format(amount),
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
