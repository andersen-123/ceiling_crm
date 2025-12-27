import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/screens/edit_position_modal.dart';

class QuickAddScreen extends StatefulWidget {
  final Function(List<LineItem>) onItemsSelected;
  final List<LineItem> existingItems;

  const QuickAddScreen({
    Key? key,
    required this.onItemsSelected,
    required this.existingItems,
  }) : super(key: key);

  @override
  _QuickAddScreenState createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  List<LineItem> _selectedItems = [];
  List<LineItem> _standardPositions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStandardPositions();
  }

  Future<void> _loadStandardPositions() async {
    try {
      final positions = await Quote.loadStandardPositions();
      setState(() {
        _standardPositions = positions;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки позиций: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleItemSelection(LineItem item) {
    setState(() {
      final existingIndex = _selectedItems.indexWhere(
        (selected) => selected.name == item.name && selected.unit == item.unit
      );

      if (existingIndex != -1) {
        _selectedItems.removeAt(existingIndex);
      } else {
        final newItem = LineItem(
          id: 0,
          name: item.name,
          quantity: item.quantity,
          unit: item.unit,
          price: item.price,
          note: item.note,
        );
        _selectedItems.add(newItem);
      }
    });
  }

  void _editItem(LineItem item) async {
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
        final index = _selectedItems.indexOf(item);
        if (index != -1) {
          _selectedItems[index] = editedItem;
        }
      });
    }
  }

  void _addCustomItem() async {
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
        _selectedItems.add(newItem);
      });
    }
  }

  void _saveAndReturn() {
    widget.onItemsSelected(_selectedItems);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Быстрое добавление позиций'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addCustomItem,
            tooltip: 'Добавить свою позицию',
          ),
          IconButton(
            icon: Icon(Icons.done),
            onPressed: _selectedItems.isNotEmpty ? _saveAndReturn : null,
            tooltip: 'Добавить выбранные',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Выбрано позиций: ${_selectedItems.length}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      if (_selectedItems.isNotEmpty)
                        Text(
                          'Итого: ${_calculateTotal()} ₽',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
                        ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _saveAndReturn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Добавить выбранные позиции'),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: _standardPositions.length,
                    itemBuilder: (context, index) {
                      final item = _standardPositions[index];
                      final isSelected = _selectedItems.any(
                        (selected) => selected.name == item.name && selected.unit == item.unit
                      );
                      
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: isSelected ? Colors.green[50] : null,
                        elevation: 2,
                        child: ListTile(
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.green[800] : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${item.price} ₽',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '/ ${item.unit}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              if (item.note.isNotEmpty) 
                                Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.note,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleItemSelection(item),
                              ),
                              if (isSelected)
                                IconButton(
                                  icon: Icon(Icons.edit, size: 20, color: Colors.blue),
                                  onPressed: () => _editItem(item),
                                ),
                            ],
                          ),
                          onTap: () => _toggleItemSelection(item),
                          onLongPress: () => _editItem(item),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String _calculateTotal() {
    final total = _selectedItems.fold(
      0.0, 
      (sum, item) => sum + (item.quantity * item.price)
    );
    return total.toStringAsFixed(2);
  }
}
