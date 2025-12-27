import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/services/database_helper.dart';
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
  bool _isLoading = false;

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
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.updateQuote(updatedQuote);
      
      setState(() {
        _quote = updatedQuote;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Изменения сохранены'),
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
        title: Text('Удалить позицию?'),
        content: Text('Вы уверены, что хотите удалить "${_items[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _items.removeAt(index);
              });
              _saveChanges();
              Navigator.of(context).pop();
            },
            child: Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: Colors.blue),
              title: Text('Добавить новую позицию'),
              subtitle: Text('Создать позицию с нуля'),
              onTap: () {
                Navigator.of(context).pop();
                _addNewItem();
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.library_add, color: Colors.green),
              title: Text('Быстрое добавление из шаблона'),
              subtitle: Text('Выбрать из готовых позиций'),
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

  void _generatePdf() {
    // TODO: Реализовать генерацию PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Генерация PDF в разработке...')),
    );
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
          if (_items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.picture_as_pdf),
              onPressed: _generatePdf,
              tooltip: 'Создать PDF',
            ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(Icons.save),
                  title: Text('Сохранить изменения'),
                ),
                onTap: _saveChanges,
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Поделиться'),
                ),
                onTap: () {
                  // TODO: Реализовать шаринг
                },
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        child: Icon(Icons.add),
        tooltip: 'Добавить позицию',
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Информация о клиенте
                Card(
                  margin: EdgeInsets.all(8),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Клиент: ${_quote.clientName}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('Адрес: ${_quote.clientAddress}'),
                        if (_quote.clientPhone.isNotEmpty)
                          Text('Телефон: ${_quote.clientPhone}'),
                        if (_quote.clientEmail.isNotEmpty)
                          Text('Email: ${_quote.clientEmail}'),
                        if (_quote.notes.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Text(
                            'Примечания:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(_quote.notes),
                        ],
                        Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Итого:',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Позиции (${_items.length})',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Сумма: ${_calculateTotal().toStringAsFixed(2)} ₽',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
                              Icon(Icons.list, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Нет позиций',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Нажмите "+" чтобы добавить позиции',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Card(
                              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                title: Text(
                                  item.name,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '${item.quantity} ${item.unit}',
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                        Text(' × '),
                                        Text(
                                          '${item.price} ₽',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(' = '),
                                        Text(
                                          '${(item.quantity * item.price).toStringAsFixed(2)} ₽',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (item.note.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          item.note,
                                          style: TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, size: 20),
                                      onPressed: () => _editItem(item, index),
                                      tooltip: 'Редактировать',
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, size: 20, color: Colors.red),
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
