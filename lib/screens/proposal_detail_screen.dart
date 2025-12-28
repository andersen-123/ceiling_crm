import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/screens/edit_position_modal.dart';
import 'package:ceiling_crm/services/database_helper.dart';

class ProposalDetailScreen extends StatefulWidget {
  final Quote quote;

  const ProposalDetailScreen({super.key, required this.quote});

  @override
  State<ProposalDetailScreen> createState() => _ProposalDetailScreenState();
}

class _ProposalDetailScreenState extends State<ProposalDetailScreen> {
  late Quote _quote;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _quote = widget.quote;
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    if (_quote.id > 0) {
      final updatedQuote = await _dbHelper.getQuote(_quote.id);
      if (updatedQuote != null && mounted) {
        setState(() {
          _quote = updatedQuote;
        });
      }
    }
  }

  Future<void> _addPosition() async {
    final newItem = await showModalBottomSheet<LineItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditPositionModal(
        onSave: (item) => item,
      ),
    );

    if (newItem != null && mounted) {
      await _savePosition(newItem);
    }
  }

  Future<void> _editPosition(LineItem item) async {
    final editedItem = await showModalBottomSheet<LineItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditPositionModal(
        initialItem: item,
        onSave: (editedItem) => editedItem,
      ),
    );

    if (editedItem != null && mounted) {
      await _savePosition(editedItem, existingItem: item);
    }
  }

  Future<void> _savePosition(LineItem item, {LineItem? existingItem}) async {
    try {
      final updatedItems = List<LineItem>.from(_quote.items);
      
      if (existingItem != null) {
        final index = updatedItems.indexWhere((i) => i.id == existingItem.id);
        if (index != -1) {
          updatedItems[index] = item.copyWith(id: existingItem.id);
        }
      } else {
        // Присваиваем временный ID для новых позиций
        final newId = updatedItems.isNotEmpty 
            ? updatedItems.map((i) => i.id).reduce((a, b) => a > b ? a : b) + 1 
            : 1;
        updatedItems.add(item.copyWith(id: newId));
      }

      final updatedQuote = _quote.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateQuote(updatedQuote);
      
      if (mounted) {
        setState(() {
          _quote = updatedQuote;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Позиция сохранена'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Ошибка сохранения позиции: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePosition(LineItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить позицию?'),
        content: Text('Вы уверены, что хотите удалить "${item.name}"?'),
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

    if (confirmed == true && mounted) {
      try {
        final updatedItems = _quote.items.where((i) => i.id != item.id).toList();
        final updatedQuote = _quote.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );

        await _dbHelper.updateQuote(updatedQuote);
        
        setState(() {
          _quote = updatedQuote;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Позиция удалена'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        print('Ошибка удаления позиции: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('КП №${_quote.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuote,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _quote.clientName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('📍 ${_quote.clientAddress}'),
                  if (_quote.clientPhone.isNotEmpty)
                    Text('📞 ${_quote.clientPhone}'),
                  if (_quote.clientEmail.isNotEmpty)
                    Text('✉️ ${_quote.clientEmail}'),
                  if (_quote.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const Text(
                      'Примечания:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_quote.notes),
                  ],
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Позиции (${_quote.items.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    'Итого: ${_quote.totalAmount.toStringAsFixed(2)} ₽',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.green.shade50,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          Expanded(
            child: _quote.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.list,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Нет позиций',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Добавьте первую позицию в смету',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _addPosition,
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить позицию'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _quote.items.length,
                    itemBuilder: (context, index) {
                      final item = _quote.items[index];
                      final total = item.quantity * item.price;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${item.quantity} ${item.unit}',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '× ${item.price.toStringAsFixed(2)} ₽',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.description,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '${total.toStringAsFixed(2)} ₽',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<int>(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 1,
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Редактировать'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 2,
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Удалить'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 1) {
                                _editPosition(item);
                              } else if (value == 2) {
                                _deletePosition(item);
                              }
                            },
                          ),
                          onTap: () => _editPosition(item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPosition,
        child: const Icon(Icons.add),
        tooltip: 'Добавить позицию',
      ),
    );
  }
}
