// lib/screens/proposal_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/services/database_helper.dart';
import 'package:ceiling_crm/screens/edit_position_modal.dart';
import 'package:ceiling_crm/screens/pdf_preview_screen.dart';

class ProposalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> quote;

  const ProposalDetailScreen({
    super.key,
    required this.quote,
  });

  @override
  State<ProposalDetailScreen> createState() => _ProposalDetailScreenState();
}

class _ProposalDetailScreenState extends State<ProposalDetailScreen> {
  late Map<String, dynamic> _quote;
  bool _isSaving = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _quote = Map<String, dynamic>.from(widget.quote);
    _quote['positions'] ??= [];
  }

  // Преобразуем в объект Quote для сохранения
  Quote _mapToQuote(Map<String, dynamic> map) {
    return Quote(
      id: map['id'],
      clientName: map['clientName'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      notes: map['notes'] ?? '',
      totalAmount: map['totalAmount'] ?? 0.0,
      positions: (map['positions'] as List?)
          ?.map((p) => LineItem.fromMap(p))
          .toList() ??
          [],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Сохранение quote
  Future<void> _saveQuote() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final quote = _mapToQuote(_quote);
      await _dbHelper.saveQuote(quote.toMap());
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('КП сохранено'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сохранения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Методы для работы с позициями (остаются как в предыдущей версии)
  double _calculateTotal() {
    double total = 0;
    for (var position in _quote['positions']) {
      final quantity = position['quantity'] ?? 0;
      final price = position['price'] ?? 0;
      total += quantity * price;
    }
    return total;
  }

  void _addNewPosition() {
    final newPosition = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': 'Новая позиция',
      'description': '',
      'quantity': 1.0,
      'unit': 'шт.',
      'price': 0.0,
    };

    setState(() {
      _quote['positions'].add(newPosition);
    });

    _editPosition(_quote['positions'].length - 1);
  }

  void _editPosition(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPositionModal(
        position: _quote['positions'][index],
        onSave: (updatedPosition) {
          setState(() {
            _quote['positions'][index] = updatedPosition;
          });
          _saveQuote();
        },
      ),
    ).then((value) {
      if (value != null && value['delete'] == true) {
        _deletePosition(index);
      }
    });
  }

  void _deletePosition(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить позицию?'),
        content: const Text('Вы уверены, что хотите удалить эту позицию?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _quote['positions'].removeAt(index);
              });
              Navigator.pop(context);
              _saveQuote();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  // Генерация PDF через ваш pdf_service
  Future<void> _generatePdf() async {
    try {
      // Используем ваш PDF сервис
      final pdfService = PdfService();
      final pdfBytes = await pdfService.generateQuotePdf(_mapToQuote(_quote));
      
      // Переход на экран предпросмотра
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfBytes: pdfBytes,
            fileName: 'КП_${_quote['clientName']}_${DateTime.now().millisecondsSinceEpoch}.pdf',
            quote: _quote,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка генерации PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_quote['clientName'] ?? 'КП'),
            Text(
              '${_calculateTotal().toStringAsFixed(2)} ₽',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdf,
            tooltip: 'Создать PDF',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Информация о клиенте
        _buildClientInfo(),
        
        // Список позиций
        Expanded(
          child: _quote['positions'].isEmpty
              ? _buildEmptyState()
              : _buildPositionsList(),
        ),
        
        // Панель с итогами
        _buildBottomPanel(),
      ],
    );
  }

  Widget _buildClientInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _quote['clientName'] ?? 'Клиент не указан',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_quote['address'] ?? 'Адрес не указан'),
                ),
              ],
            ),
            if (_quote['phone']?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(_quote['phone']),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Позиции не добавлены',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _addNewPosition,
            icon: const Icon(Icons.add),
            label: const Text('Добавить первую позицию'),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _quote['positions'].length,
      itemBuilder: (context, index) {
        final position = _quote['positions'][index];
        final total = (position['quantity'] ?? 0) * (position['price'] ?? 0);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () => _editPosition(index),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: Text(
                (index + 1).toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            title: Text(position['name'] ?? 'Без названия'),
            subtitle: Text(
              '${position['quantity']} ${position['unit']} × ${position['price']} ₽',
            ),
            trailing: Text(
              '${total.toStringAsFixed(2)} ₽',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomPanel() {
    final total = _calculateTotal();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Итого:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addNewPosition,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить позицию'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveQuote,
                  icon: _isSaving
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Сохранение...' : 'Сохранить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
