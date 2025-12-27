// lib/screens/proposal_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/services/database_helper.dart';
import 'package:ceiling_crm/screens/edit_position_modal.dart';
import 'package:ceiling_crm/screens/pdf_preview_screen.dart';
import 'package:ceiling_crm/screens/quote_edit_screen.dart';

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
  late Quote _quote;
  bool _isSaving = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    // Преобразуем Map в объект Quote
    _quote = Quote.fromMap(widget.quote);
  }

  // Сохранение изменений
  Future<void> _saveQuote() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Обновляем дату изменения
      _quote = _quote.copyWith(
        updatedAt: DateTime.now(),
        totalAmount: _quote.calculateTotal(),
      );

      // Сохраняем в базу
      await _dbHelper.saveQuote(_quote);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('КП сохранено'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
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
      _quote = _quote.copyWith(
        positions: [..._quote.positions, newPosition],
      );
    });

    _editPosition(_quote.positions.length - 1);
  }

  // Редактирование позиции
  void _editPosition(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPositionModal(
        position: _quote.positions[index].toMap(),
        onSave: (updatedMap) {
          final updatedPosition = LineItem.fromMap(updatedMap);
          final newPositions = List<LineItem>.from(_quote.positions);
          newPositions[index] = updatedPosition;
          
          setState(() {
            _quote = _quote.copyWith(positions: newPositions);
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

  // Удаление позиции
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
              final newPositions = List<LineItem>.from(_quote.positions);
              newPositions.removeAt(index);
              
              setState(() {
                _quote = _quote.copyWith(positions: newPositions);
              });
              
              Navigator.pop(context);
              _saveQuote();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  // Генерация PDF
  Future<void> _generatePdf() async {
    try {
      // Переход на экран PDF
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            quote: _quote.toMap(),
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

  // Редактирование КП (переход в режим редактирования)
  void _editQuote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteEditScreen(
          quoteToEdit: _quote,
        ),
      ),
    );
  }

  // Удаление всего КП
  Future<void> _deleteQuote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить КП?'),
        content: const Text('Вы уверены, что хотите удалить это коммерческое предложение?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteProposal(_quote.id!);
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _quote.calculateTotal();
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _quote.clientName,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '${totalAmount.toStringAsFixed(2)} ₽',
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
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editQuote();
              } else if (value == 'pdf') {
                _generatePdf();
              } else if (value == 'delete') {
                _deleteQuote();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Редактировать КП'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 20),
                    SizedBox(width: 8),
                    Text('Создать PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Удалить КП', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Информация о клиенте
          _buildClientInfo(),
          
          // Список позиций
          Expanded(
            child: _quote.positions.isEmpty
                ? _buildEmptyState()
                : _buildPositionsList(),
          ),
          
          // Панель с итогами и кнопками
          _buildBottomPanel(),
        ],
      ),
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
                const Icon(Icons.person, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _quote.clientName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_quote.address),
                ),
              ],
            ),
            if (_quote.phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.purple, size: 20),
                  const SizedBox(width: 8),
                  Text(_quote.phone),
                ],
              ),
            ],
            if (_quote.email.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.email, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(_quote.email),
                ],
              ),
            ],
            if (_quote.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Примечания:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_quote.notes),
                    ],
                  ),
                ),
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
          const Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Позиции не добавлены',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _addPosition,
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
      itemCount: _quote.positions.length,
      itemBuilder: (context, index) {
        final position = _quote.positions[index];
        
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
            title: Text(
              position.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${position.quantity} ${position.unit} × ${position.price} ₽',
                ),
                if (position.description.isNotEmpty)
                  Text(
                    position.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${position.total.toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  position.unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomPanel() {
    final totalAmount = _quote.calculateTotal();
    
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${totalAmount.toStringAsFixed(2)} ₽',
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
                  onPressed: _addPosition,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить позицию'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveQuote,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
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
