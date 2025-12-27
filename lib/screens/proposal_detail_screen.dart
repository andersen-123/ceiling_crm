import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/services/database_helper.dart';
import 'package:ceiling_crm/services/pdf_service.dart';
import 'package:ceiling_crm/screens/edit_position_modal.dart';
import 'package:ceiling_crm/screens/quick_add_screen.dart';

class ProposalDetailScreen extends StatefulWidget {
  final Quote quote;

  const ProposalDetailScreen({Key? key, required this.quote}) : super(key: key);

  @override
  _ProposalDetailScreenState createState() => _ProposalDetailScreenState();
}

class _ProposalDetailScreenState extends State<ProposalDetailScreen> {
  late Quote _quote;
  late List<LineItem> _items;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PdfService _pdfService = PdfService();
  bool _isLoading = false;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _quote = widget.quote;
    _items = List.from(_quote.items);
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedQuote = _quote.copyWith(items: _items);
      await _dbHelper.updateQuote(updatedQuote);
      
      setState(() {
        _quote = updatedQuote;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Изменения сохранены'),
            backgroundColor: Colors.green,
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addNewItem() async {
    final newItem = await showModalBottomSheet<LineItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditPositionModal(
        onSave: (item) => item,
        isEditing: false,
      ),
    );

    if (newItem != null) {
      setState(() {
        _items.add(newItem);
      });
      await _saveChanges();
    }
  }

  void _quickAddFromTemplate() async {
    final selectedItems = await Navigator.of(context).push<List<LineItem>>(
      MaterialPageRoute(
        builder: (context) => QuickAddScreen(
          onItemsSelected: (items) => items,
          existingItems: _items,
        ),
      ),
    );

    if (selectedItems != null && selectedItems.isNotEmpty) {
      setState(() {
        _items.addAll(selectedItems);
      });
      await _saveChanges();
    }
  }

  void _editItem(LineItem item, int index) async {
    final editedItem = await showModalBottomSheet<LineItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditPositionModal(
        initialItem: item,
        onSave: (editedItem) => editedItem,
        isEditing: true,
      ),
    );

    if (editedItem != null) {
      setState(() {
        _items[index] = editedItem;
      });
      await _saveChanges();
    }
  }

  void _removeItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить позицию?'),
        content: Text('Вы уверены, что хотите удалить "${_items[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _items.removeAt(index);
              });
              _saveChanges();
              Navigator.of(context).pop();
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
              title: const Text('Добавить новую позицию'),
              subtitle: const Text('Создать позицию с нуля'),
              onTap: () {
                Navigator.of(context).pop();
                _addNewItem();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.library_add, color: Colors.green),
              title: const Text('Быстрое добавление из шаблона'),
              subtitle: const Text('Выбрать из готовых позиций'),
              onTap: () {
                Navigator.of(context).pop();
                _quickAddFromTemplate();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _generatePdf() async {
    if (_isGeneratingPdf || _items.isEmpty) return;
    
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final updatedQuote = _quote.copyWith(items: _items);
      await _pdfService.previewPdf(context, updatedQuote);
    } catch (e) {
      print('Ошибка генерации PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка генерации PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  double _calculateTotal() {
    return _items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('КП: ${_quote.clientName}'),
        actions: [
          // Кнопка PDF
          if (_items.isNotEmpty)
            IconButton(
              icon: _isGeneratingPdf 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              onPressed: _isGeneratingPdf ? null : _generatePdf,
              tooltip: 'Создать PDF',
            ),
          
          // Меню дополнительных опций
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.save),
                  title: Text('Сохранить изменения'),
                ),
                onTap: _saveChanges,
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Поделиться'),
                ),
                onTap: () {
                  // TODO: Реализовать шаринг
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Шаринг в разработке...')),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        child: const Icon(Icons.add),
        tooltip: 'Добавить позицию',
      ),
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Информация о клиенте
                Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Клиент: ${_quote.clientName}',
                          style: const TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Адрес: ${_quote.clientAddress}'),
                        if (_quote.clientPhone.isNotEmpty)
                          Text('Телефон: ${_quote.clientPhone}'),
                        if (_quote.clientEmail.isNotEmpty)
                          Text('Email: ${_quote.clientEmail}'),
                        if (_quote.notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Примечания:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(_quote.notes),
                        ],
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Итого:',
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            Text(
                              '${_calculateTotal().toStringAsFixed(2)} ₽',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Заголовок списка позиций
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Позиции (${_items.length})',
                        style: const TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      Text(
                        'Сумма: ${_calculateTotal().toStringAsFixed(2)} ₽',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Список позиций
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.list, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'Нет позиций',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Нажмите "+" чтобы добавить позиции',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.library_add),
                                label: const Text('Добавить из шаблона'),
                                onPressed: _quickAddFromTemplate,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final itemTotal = item.quantity * item.price;
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8, 
                                vertical: 4
                              ),
                              child: ListTile(
                                title: Text(
                                  item.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '${item.quantity} ${item.unit}',
                                          style: const TextStyle(color: Colors.blue),
                                        ),
                                        const Text(' × '),
                                        Text(
                                          '${item.price.toStringAsFixed(2)} ₽',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const Text(' = '),
                                        Text(
                                          '${itemTotal.toStringAsFixed(2)} ₽',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (item.note.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          item.note,
                                          style: const TextStyle(
                                            fontSize: 12, 
                                            color: Colors.grey
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _editItem(item, index),
                                      tooltip: 'Редактировать',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete, 
                                        size: 20, 
                                        color: Colors.red
                                      ),
                                      onPressed: () => _removeItem(index),
                                      tooltip: 'Удалить',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
