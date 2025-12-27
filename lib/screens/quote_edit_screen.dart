import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/services/database_helper.dart';

class QuoteEditScreen extends StatefulWidget {
  final int? quoteId;

  const QuoteEditScreen({super.key, this.quoteId});

  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late Quote? _initialQuote;
  bool _isLoading = true;

  final _clientNameController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    if (widget.quoteId != null) {
      final dbHelper = DatabaseHelper.instance;
      final quote = await dbHelper.getQuote(widget.quoteId!);
      
      if (quote != null) {
        setState(() {
          _initialQuote = quote;
          _clientNameController.text = quote.clientName;
          _clientAddressController.text = quote.clientAddress;
          _clientPhoneController.text = quote.clientPhone;
          _clientEmailController.text = quote.clientEmail;
          _notesController.text = quote.notes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _initialQuote = null;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _initialQuote = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveQuote() async {
    if (_formKey.currentState!.validate()) {
      final quote = Quote(
        id: widget.quoteId ?? 0,
        clientName: _clientNameController.text.trim(),
        clientAddress: _clientAddressController.text.trim(),
        clientPhone: _clientPhoneController.text.trim(),
        clientEmail: _clientEmailController.text.trim(),
        notes: _notesController.text.trim(),
        items: _initialQuote?.items ?? [],
        createdAt: widget.quoteId == null 
            ? DateTime.now() 
            : (_initialQuote?.createdAt ?? DateTime.now()),
        updatedAt: DateTime.now(),
      );

      try {
        final dbHelper = DatabaseHelper.instance;
        
        if (widget.quoteId == null) {
          await dbHelper.insertQuote(quote);
        } else {
          await dbHelper.updateQuote(quote);
        }
        
        if (mounted) {
          Navigator.of(context).pop(true);
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
      }
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientAddressController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Загрузка...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quoteId == null ? 'Новое КП' : 'Редактировать КП'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveQuote,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Информация о клиенте',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Имя клиента *',
                          border: OutlineInputBorder(),
                          hintText: 'Иван Иванов',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите имя клиента';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        controller: _clientAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Адрес *',
                          border: OutlineInputBorder(),
                          hintText: 'Москва, ул. Примерная, д. 1',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите адрес';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _clientPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Телефон *',
                                border: OutlineInputBorder(),
                                hintText: '+7 (999) 123-45-67',
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Введите телефон';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _clientEmailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                                hintText: 'client@example.com',
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Примечания',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Дополнительная информация',
                          border: OutlineInputBorder(),
                          hintText: 'Особые пожелания, условия монтажа и т.д.',
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Информация о предложении',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      if (_initialQuote != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Создано: ${_initialQuote!.createdAt.day}.${_initialQuote!.createdAt.month}.${_initialQuote!.createdAt.year}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        Row(
                          children: [
                            const Icon(Icons.update, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Обновлено: ${_initialQuote!.updatedAt.day}.${_initialQuote!.updatedAt.month}.${_initialQuote!.updatedAt.year}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        if (_initialQuote!.items.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.list, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Позиций: ${_initialQuote!.items.length}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                      ] else ...[
                        Row(
                          children: [
                            const Icon(Icons.add_circle, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text(
                              'Новое коммерческое предложение',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        const Text(
                          'После сохранения вы сможете добавить позиции в деталях КП',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Отмена', style: TextStyle(color: Colors.black87)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveQuote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.quoteId == null ? 'Создать КП' : 'Сохранить изменения',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
