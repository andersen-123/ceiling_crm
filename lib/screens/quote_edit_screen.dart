import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/services/database_helper.dart';
import 'package:ceiling_crm/screens/proposal_detail_screen.dart';

class QuoteEditScreen extends StatefulWidget {
  final int? quoteId;

  const QuoteEditScreen({super.key, this.quoteId});

  @override
  State<QuoteEditScreen> createState() => _QuoteEditScreenState();
}

class _QuoteEditScreenState extends State<QuoteEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late Quote _quote;
  bool _isLoading = true;
  bool _isNew = true;

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
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.quoteId != null && widget.quoteId! > 0) {
        final dbHelper = DatabaseHelper.instance;
        final quote = await dbHelper.getQuote(widget.quoteId!);
        
        if (quote != null) {
          _quote = quote;
          _isNew = false;
          _clientNameController.text = quote.clientName;
          _clientAddressController.text = quote.clientAddress;
          _clientPhoneController.text = quote.clientPhone;
          _clientEmailController.text = quote.clientEmail;
          _notesController.text = quote.notes;
        } else {
          _createNewQuote();
        }
      } else {
        _createNewQuote();
      }
    } catch (e) {
      print('Ошибка загрузки КП: $e');
      _createNewQuote();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createNewQuote() {
    _quote = Quote(
      id: 0,
      clientName: '',
      clientAddress: '',
      clientPhone: '',
      clientEmail: '',
      notes: '',
      items: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _isNew = true;
  }

  Future<void> _saveQuote() async {
    if (_formKey.currentState!.validate()) {
      final updatedQuote = Quote(
        id: _isNew ? 0 : _quote.id,
        clientName: _clientNameController.text.trim(),
        clientAddress: _clientAddressController.text.trim(),
        clientPhone: _clientPhoneController.text.trim(),
        clientEmail: _clientEmailController.text.trim(),
        notes: _notesController.text.trim(),
        items: _quote.items,
        createdAt: _isNew ? DateTime.now() : _quote.createdAt,
        updatedAt: DateTime.now(),
      );

      try {
        final dbHelper = DatabaseHelper.instance;
        
        if (_isNew) {
          final newId = await dbHelper.insertQuote(updatedQuote);
          _quote = updatedQuote.copyWith(id: newId);
          _isNew = false;
        } else {
          await dbHelper.updateQuote(updatedQuote);
          _quote = updatedQuote;
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isNew ? 'КП создано' : 'КП обновлено'),
              backgroundColor: Colors.green,
            ),
          );
          
          // После сохранения можно перейти к добавлению позиций
          _navigateToProposalDetail();
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

  void _navigateToProposalDetail() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProposalDetailScreen(quote: _quote),
      ),
    );
  }

  void _managePositions() {
    if (!_isNew && _quote.id > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProposalDetailScreen(quote: _quote),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала сохраните КП'),
          backgroundColor: Colors.orange,
        ),
      );
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
        title: Text(_isNew ? 'Новое КП' : 'Редактировать КП'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: _managePositions,
              tooltip: 'Управление позициями',
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                      
                      if (!_isNew) ...[
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Создано: ${_quote.createdAt.day}.${_quote.createdAt.month}.${_quote.createdAt.year}',
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
                              'Обновлено: ${_quote.updatedAt.day}.${_quote.updatedAt.month}.${_quote.updatedAt.year}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        Row(
                          children: [
                            const Icon(Icons.list, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Позиций: ${_quote.items.length}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        ElevatedButton.icon(
                          onPressed: _managePositions,
                          icon: const Icon(Icons.add_circle),
                          label: const Text('Добавить/редактировать позиции'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
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
                          'После сохранения вы сможете добавить позиции',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        
                        ElevatedButton.icon(
                          onPressed: _saveQuote,
                          icon: const Icon(Icons.save),
                          label: const Text('Сохранить и перейти к позициям'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 48),
                          ),
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
                        _isNew ? 'Создать КП' : 'Сохранить изменения',
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
