import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/services/template_service.dart';

class QuickAddScreen extends StatefulWidget {
  final Function(List<LineItem>) onItemsSelected;
  
  const QuickAddScreen({Key? key, required this.onItemsSelected}) : super(key: key);

  @override
  _QuickAddScreenState createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  final TemplateService _templateService = TemplateService();
  List<LineItem> _templates = [];
  List<bool> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    await _templateService.loadTemplates();
    setState(() {
      _templates = _templateService.getTemplates();
      _selectedItems = List.generate(_templates.length, (index) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Быстрое добавление'),
        actions: [
          if (_selectedItems.any((selected) => selected))
            TextButton(
              onPressed: _addSelectedItems,
              child: const Text(
                'Добавить',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _templates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final item = _templates[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: CheckboxListTile(
                    value: _selectedItems[index],
                    onChanged: (value) {
                      setState(() {
                        _selectedItems[index] = value ?? false;
                      });
                    },
                    title: Text(
                      item.name ?? '',  // БЫЛО: item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((item.description ?? '').isNotEmpty)
                          Text(item.description ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          '${item.price} руб. × ${item.quantity} ${item.unit} = ${item.totalPrice} руб.',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    secondary: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editTemplate(item, index),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _editTemplate(LineItem item, int index) async {
    final editedItem = await _showEditDialog(item);
    if (editedItem != null) {
      setState(() {
        _templates[index] = editedItem;
      });
    }
  }

  Future<LineItem?> _showEditDialog(LineItem item) async {
    final nameController = TextEditingController(text: item.name);
    final descriptionController = TextEditingController(text: item.description ?? '');
    final priceController = TextEditingController(text: item.price.toString());
    final quantityController = TextEditingController(text: item.quantity.toString());
    final unitController = TextEditingController(text: item.unit);

    return showDialog<LineItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать шаблон'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Описание'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Цена'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Кол-во'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Единица измерения'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final editedItem = item.copyWith(
                name: nameController.text,
                description: descriptionController.text,
                price: double.tryParse(priceController.text) ?? item.price,
                quantity: double.tryParse(quantityController.text) ?? item.quantity,  // БЫЛО: int.tryParse
                unit: unitController.text,
              );
              Navigator.pop(context, editedItem);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _addSelectedItems() {
    final selectedItems = <LineItem>[];
    for (int i = 0; i < _templates.length; i++) {
      if (_selectedItems[i]) {
        selectedItems.add(_templates[i]);
      }
    }
    
    widget.onItemsSelected(selectedItems);
    Navigator.pop(context);
  }
}
