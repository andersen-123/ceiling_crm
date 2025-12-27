// lib/screens/quote_edit_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/services/database_helper.dart';
import 'package:ceiling_crm/screens/proposal_detail_screen.dart';

class QuoteEditScreen extends StatefulWidget {
  final Quote? quoteToEdit;

  const QuoteEditScreen({
    super.key,
    this.quoteToEdit,
  });

  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Поля формы
  String _clientName = '';
  String _address = '';
  String _phone = '';
  String _email = '';
  String _notes = '';
  
  // Позиции
  List<LineItem> _positions = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // Если редактируем существующий КП, загружаем данные
    if (widget.quoteToEdit != null) {
      _clientName = widget.quoteToEdit!.clientName;
      _address = widget.quoteToEdit!.address;
      _phone = widget.quoteToEdit!.phone;
      _email = widget.quoteToEdit!.email;
      _notes = widget.quoteToEdit!.notes;
      _positions = List.from(widget.quoteToEdit!.positions);
    }
  }

  // Валидация и сохранение
  Future<void> _saveQuote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    _formKey.currentState!.save();
    
    setState(() {
      _isSaving = true;
    });

    try {
      // Создаем объект Quote
      final quote = Quote(
        id: widget.quoteToEdit?.id,
        clientName: _clientName,
        address: _address,
        phone: _phone,
        email: _email,
        notes: _notes,
        positions: _positions,
        totalAmount: _calculateTotal(),
        createdAt: widget.quoteToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Сохраняем в базу данных
      final savedQuote = await _dbHelper.saveQuote(quote);

      // Переходим на экран детализации
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProposalDetailScreen(
              quote: savedQuote.toMap(),
            ),
          ),
        );
      }

    } catch (e) {
      print('Ошибка сохранения: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Добавление новой позиции
  void _addPosition() {
    final newPosition = LineItem(
      id: DateTime.now().millisecondsSinceEpoch,
      name: 'Новая позиция',
      quantity: 1.0,
      unit: 'шт.',
      price: 0.0,
    );

    setState(() {
      _positions.add(newPosition);
    });
  }

  // Удаление позиции
  void _removePosition(int index) {
    setState(() {
      _positions.removeAt(index);
    });
  }

  // Расчет общей суммы
  double _calculateTotal() {
    return _positions.fold(0.0, (sum, item) => sum + item.total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quoteToEdit != null ? 'Редактирование КП' : 'Новое КП'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveQuote,
              tooltip: 'Сохранить',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Информация о клиенте
              _buildClientInfoForm(),
              
              const SizedBox(height: 24),
              
              // Быстрое добавление стандартных позиций
              _buildQuickAddPanel(),
              
              const SizedBox(height: 24),
              
              // Позиции
              _buildPositionsList(),
              
              const SizedBox(height: 24),
              
              // Итоговая сумма
              _buildTotalPanel(),
              
              const SizedBox(height: 32),
              
              // Кнопки
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientInfoForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
            
            // Имя клиента
            TextFormField(
              initialValue: _clientName,
              decoration: const InputDecoration(
                labelText: 'Имя клиента *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите имя клиента';
                }
                return null;
              },
              onSaved: (value) => _clientName = value!.trim(),
            ),
            
            const SizedBox(height: 16),
            
            // Адрес
            TextFormField(
              initialValue: _address,
              decoration: const InputDecoration(
                labelText: 'Адрес объекта *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите адрес';
                }
                return null;
              },
              onSaved: (value) => _address = value!.trim(),
            ),
            
            const SizedBox(height: 16),
            
            // Телефон
            TextFormField(
              initialValue: _phone,
              decoration: const InputDecoration(
                labelText: 'Телефон',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              onSaved: (value) => _phone = value?.trim() ?? '',
            ),
            
            const SizedBox(height: 16),
            
            // Email
            TextFormField(
              initialValue: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              onSaved: (value) => _email = value?.trim() ?? '',
            ),
            
            const SizedBox(height: 16),
            
            // Примечания
            TextFormField(
              initialValue: _notes,
              decoration: const InputDecoration(
                labelText: 'Примечания',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              onSaved: (value) => _notes = value?.trim() ?? '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddPanel() {
    final standardItems = [
      {'name': 'Полотно MSD Premium', 'unit': 'м²', 'price': 650.0},
      {'name': 'Профиль гарпунный', 'unit': 'м.п.', 'price': 310.0},
      {'name': 'Вставка гарпунная', 'unit': 'м.п.', 'price': 220.0},
      {'name': 'Монтаж светильника', 'unit': 'шт.', 'price': 780.0},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Быстрое добавление',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: standardItems.map((item) {
                return ActionChip(
                  label: Text('${item['name']}\n${item['price']} ₽'),
                  onPressed: () {
                    setState(() {
                      _positions.add(LineItem(
                        id: DateTime.now().millisecondsSinceEpoch,
                        name: item['name'] as String,
                        quantity: 1.0,
                        unit: item['unit'] as String,
                        price: item['price'] as double,
                      ));
                    });
                  },
                  backgroundColor: Colors.blue.shade50,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                Text(
                  '${_positions.length} шт.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_positions.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Позиции не добавлены',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ..._positions.asMap().entries.map((entry) {
                final index = entry.key;
                final position = entry.value;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.grey.shade50,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        (index + 1).toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    title: Text(position.name),
                    subtitle: Text(
                      '${position.quantity} ${position.unit} × ${position.price} ₽',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${position.total.toStringAsFixed(2)} ₽',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removePosition(index),
                          tooltip: 'Удалить',
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            
            const SizedBox(height: 16),
            
            Center(
              child: OutlinedButton.icon(
                onPressed: _addPosition,
                icon: const Icon(Icons.add),
                label: const Text('Добавить позицию'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalPanel() {
    final total = _calculateTotal();
    
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Итого:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${total.toStringAsFixed(2)} ₽',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Отмена'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveQuote,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Сохранить КП'),
          ),
        ),
      ],
    );
  }
}
