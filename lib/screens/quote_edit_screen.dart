// lib/screens/quote_edit_screen.dart

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

  // 9. Сохранение позиций (пока заглушка)
  Future<void> _saveLineItems(int quoteId) async {
    // TODO: Реализовать в следующем задании
  }

  // 10. Добавление новой позиции (пока заглушка)
  void _addNewLineItem() {
    // TODO: Реализовать в следующем задании
  }

  // 11. Удаление позиции (пока заглушка)
  void _deleteLineItem(int index) {
    // TODO: Реализовать в следующем задании
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
            prefixIcon: Icon(Icons.status),
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

  // 15. Секция позиций КП (пока заглушка)
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
        // TODO: Заменить на список позиций
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'Список позиций будет здесь\n(Задание 3.2)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  // 16. Секция итогов
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

  // 17. Секция примечаний
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

  // 18. Очистка контроллеров
  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
