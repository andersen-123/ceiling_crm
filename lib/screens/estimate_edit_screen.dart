import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/estimate.dart';
import 'package:ceiling_crm/data/estimate_templates.dart';

class EstimateEditScreen extends StatefulWidget {
  final Estimate estimate;
  final int? projectId;

  const EstimateEditScreen({
    super.key,
    required this.estimate,
    this.projectId,
  });

  @override
  State<EstimateEditScreen> createState() => _EstimateEditScreenState();
}

class _EstimateEditScreenState extends State<EstimateEditScreen> {
  late Estimate _estimate;

  @override
  void initState() {
    super.initState();
    _estimate = widget.estimate;
    if (_estimate.items.isEmpty) {
      _addSampleItems();
    }
  }

  void _addSampleItems() {
    setState(() {
      // Добавляем несколько примеров из шаблонов
      final templates = EstimateTemplates.defaultTemplates.take(3).toList();
      for (var template in templates) {
        _estimate.addFromTemplate(template, quantity: 1.0);
      }
    });
  }

  void _showAddTemplateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return TemplateSelectionSheet(
          onTemplateSelected: (template) {
            Navigator.pop(context);
            _showQuantityDialog(template);
          },
        );
      },
    );
  }

  void _showQuantityDialog(EstimateItem template) {
    final quantityController = TextEditingController(text: '1');
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Добавить: ${template.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Количество',
                  suffixText: template.unit,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Цена: ${template.price} руб./${template.unit}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final quantity = double.tryParse(quantityController.text) ?? 1.0;
                setState(() {
                  _estimate.addFromTemplate(template, quantity: quantity);
                });
                Navigator.pop(context);
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  void _editItem(int index) {
    final item = _estimate.items[index];
    
    showDialog(
      context: context,
      builder: (context) {
        return EditItemDialog(
          item: item,
          onSave: (updatedItem) {
            setState(() {
              _estimate.updateItem(index, updatedItem);
            });
          },
        );
      },
    );
  }

  void _addCustomItem() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final quantityController = TextEditingController(text: '1');
        final priceController = TextEditingController(text: '0');
        String selectedUnit = 'шт.';
        String selectedCategory = 'Прочее';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Добавить свою позицию'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Наименование',
                        hintText: 'Например: Доставка материалов',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Количество',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
                            items: EstimateTemplates.units.map((unit) {
                              return DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => selectedUnit = value!);
                            },
                            decoration: const InputDecoration(
                              labelText: 'Ед. изм.',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Цена за единицу',
                        suffixText: 'руб.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: EstimateTemplates.categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedCategory = value!);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Категория',
                      ),
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
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    setState(() {
                      _estimate.addCustomItem(
                        name: name,
                        quantity: double.tryParse(quantityController.text) ?? 1.0,
                        unit: selectedUnit,
                        price: double.tryParse(priceController.text) ?? 0.0,
                        category: selectedCategory,
                      );
                    });
                    
                    Navigator.pop(context);
                  },
                  child: const Text('Добавить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsByCategory = _estimate.itemsByCategory;

    return Scaffold(
      appBar: AppBar(
        title: Text(_estimate.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // TODO: Сохранение сметы
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Итоговая сумма
          Card(
            margin: const EdgeInsets.all(8),
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ИТОГО ПО СМЕТЕ:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_estimate.total.toStringAsFixed(2)} руб.',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Список позиций по категориям
          Expanded(
            child: _estimate.items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list_alt, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Смета пуста',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          'Добавьте позиции из шаблонов или создайте свои',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      ...itemsByCategory.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            ...entry.value.asMap().entries.map((itemEntry) {
                              final index = _estimate.items.indexOf(itemEntry.value);
                              return EstimateItemCard(
                                item: itemEntry.value,
                                index: index,
                                onEdit: () => _editItem(index),
                                onDelete: () {
                                  setState(() {
                                    _estimate.removeItem(index);
                                  });
                                },
                              );
                            }).toList(),
                            const Divider(height: 1),
                          ],
                        );
                      }).toList(),
                      const SizedBox(height: 80), // Для FAB
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'custom',
            onPressed: _addCustomItem,
            child: const Icon(Icons.add),
            tooltip: 'Своя позиция',
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'template',
            onPressed: _showAddTemplateDialog,
            child: const Icon(Icons.list_alt),
            tooltip: 'Из шаблона',
          ),
        ],
      ),
    );
  }
}

// =============== Вспомогательные виджеты ===============

class TemplateSelectionSheet extends StatelessWidget {
  final Function(EstimateItem) onTemplateSelected;

  const TemplateSelectionSheet({
    super.key,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = EstimateTemplates.groupedTemplates;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          AppBar(
            title: const Text('Выберите позицию из шаблона'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    ...entry.value.map((template) {
                      return ListTile(
                        leading: const Icon(Icons.description, color: Colors.grey),
                        title: Text(template.name),
                        subtitle: Text(
                          '${template.price} руб./${template.unit}',
                          style: const TextStyle(color: Colors.green),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.blue),
                          onPressed: () => onTemplateSelected(template),
                        ),
                        onTap: () => onTemplateSelected(template),
                      );
                    }),
                    const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class EditItemDialog extends StatefulWidget {
  final EstimateItem item;
  final Function(EstimateItem) onSave;

  const EditItemDialog({
    super.key,
    required this.item,
    required this.onSave,
  });

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  late String _selectedUnit;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _priceController = TextEditingController(text: widget.item.price.toString());
    _notesController = TextEditingController(text: widget.item.notes ?? '');
    _selectedUnit = widget.item.unit;
    _selectedCategory = widget.item.category;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать позицию'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Наименование'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Количество',
                      suffixText: _selectedUnit,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    items: EstimateTemplates.units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedUnit = value!);
                    },
                    decoration: const InputDecoration(labelText: 'Ед. изм.'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Цена за единицу',
                suffixText: 'руб.',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: EstimateTemplates.categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
              decoration: const InputDecoration(labelText: 'Категория'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Примечание (необязательно)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Сумма: ${(double.tryParse(_quantityController.text) ?? 0) * (double.tryParse(_priceController.text) ?? 0)} руб.',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
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
            final updatedItem = widget.item.copyWith(
              name: _nameController.text,
              quantity: double.tryParse(_quantityController.text) ?? 0.0,
              unit: _selectedUnit,
              price: double.tryParse(_priceController.text) ?? 0.0,
              category: _selectedCategory,
              notes: _notesController.text.isNotEmpty ? _notesController.text : null,
            );
            widget.onSave(updatedItem);
            Navigator.pop(context);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class EstimateItemCard extends StatelessWidget {
  final EstimateItem item;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EstimateItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            '${item.positionNumber ?? index + 1}',
            style: const TextStyle(color: Colors.blue),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${item.quantity} ${item.unit} × ${item.price} руб.',
              style: const TextStyle(fontSize: 14),
            ),
            if (item.notes != null && item.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Примечание: ${item.notes!}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
        trailing: SizedBox(
          width: 150,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${item.total.toStringAsFixed(2)} руб.',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                onPressed: onEdit,
                tooltip: 'Редактировать',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Удалить',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
