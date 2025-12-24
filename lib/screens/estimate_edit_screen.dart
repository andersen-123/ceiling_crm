import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/estimate.dart';
import '../models/estimate_item.dart';
import '../providers/estimate_provider.dart';
import '../data/estimate_templates.dart';

class EstimateEditScreen extends StatefulWidget {
  final Estimate? estimate;

  const EstimateEditScreen({Key? key, this.estimate}) : super(key: key);

  @override
  State<EstimateEditScreen> createState() => _EstimateEditScreenState();
}

class _EstimateEditScreenState extends State<EstimateEditScreen> {
  late Estimate _currentEstimate;
  final _formKey = GlobalKey<FormState>();
  
  final _clientNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _perimeterController = TextEditingController();
  final _pricePerMeterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentEstimate = widget.estimate ?? Estimate(
      clientName: '',
      address: '',
      area: 0.0,
      perimeter: 0.0,
      pricePerMeter: 0.0,
      totalPrice: 0.0,
      createdDate: DateTime.now(),
      items: [],
    );
    
    _clientNameController.text = _currentEstimate.clientName;
    _addressController.text = _currentEstimate.address;
    _areaController.text = _currentEstimate.area.toString();
    _perimeterController.text = _currentEstimate.perimeter.toString();
    _pricePerMeterController.text = _currentEstimate.pricePerMeter.toString();
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _perimeterController.dispose();
    _pricePerMeterController.dispose();
    super.dispose();
  }

  void _showQuantityDialog(EstimateItem template) {
    final quantityController = TextEditingController(text: '1');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить: ${template.name}'),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Количество',
            border: OutlineInputBorder(),
          ),
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
                _currentEstimate = _currentEstimate.addFromTemplate(
                  template,
                  quantity: quantity,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showTemplateSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TemplateSelector(
        onTemplateSelected: _showQuantityDialog,
      ),
    );
  }

  void _saveEstimate() async {
    if (_formKey.currentState!.validate()) {
      final updatedEstimate = _currentEstimate.copyWith(
        clientName: _clientNameController.text,
        address: _addressController.text,
        area: double.tryParse(_areaController.text) ?? 0.0,
        perimeter: double.tryParse(_perimeterController.text) ?? 0.0,
        pricePerMeter: double.tryParse(_pricePerMeterController.text) ?? 0.0,
        totalPrice: _currentEstimate.total,
      );

      final provider = Provider.of<EstimateProvider>(context, listen: false);
      
      if (widget.estimate == null) {
        await provider.addEstimate(updatedEstimate);
      } else {
        await provider.updateEstimate(updatedEstimate);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.estimate == null ? 'Новая смета' : 'Редактировать смету'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEstimate,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _clientNameController,
              decoration: const InputDecoration(
                labelText: 'Имя клиента',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите имя клиента';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Адрес',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Площадь (м²)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _perimeterController,
                    decoration: const InputDecoration(
                      labelText: 'Периметр (м)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pricePerMeterController,
              decoration: const InputDecoration(
                labelText: 'Цена за м²',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Элементы сметы',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _showTemplateSelector,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_currentEstimate.items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Нет элементов в смете'),
                ),
              )
            else
              ..._currentEstimate.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.quantity} ${item.unit} × ${item.price} руб. = ${item.total} руб.',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showEditItemDialog(index, item);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _currentEstimate = _currentEstimate.removeItem(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Итого:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_currentEstimate.total.toStringAsFixed(2)} руб.',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditItemDialog(int index, EstimateItem item) {
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(text: item.quantity.toString());
    final priceController = TextEditingController(text: item.price.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать элемент'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Количество',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Цена',
                border: OutlineInputBorder(),
              ),
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
              final updatedItem = item.copyWith(
                name: nameController.text,
                quantity: double.tryParse(quantityController.text) ?? item.quantity,
                price: double.tryParse(priceController.text) ?? item.price,
              );
              setState(() {
                _currentEstimate = _currentEstimate.updateItem(index, updatedItem);
              });
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

class TemplateSelector extends StatefulWidget {
  final Function(EstimateItem) onTemplateSelected;

  const TemplateSelector({Key? key, required this.onTemplateSelected}) : super(key: key);

  @override
  State<TemplateSelector> createState() => _TemplateSelectorState();
}

class _TemplateSelectorState extends State<TemplateSelector> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final templates = _searchQuery.isEmpty
        ? EstimateTemplates.groupedTemplates
        : {'Результаты поиска': EstimateTemplates.searchTemplates(_searchQuery)};

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Поиск',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: templates.entries.map((entry) {
                return ExpansionTile(
                  title: Text(entry.key),
                  children: entry.value.map((template) {
                    return ListTile(
                      title: Text(template.name),
                      subtitle: Text(
                        '${template.price} руб./${template.unit}',
                      ),
                      onTap: () {
                        widget.onTemplateSelected(template);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemEditDialog extends StatefulWidget {
  final EstimateItem item;
  final Function(EstimateItem) onSave;

  const ItemEditDialog({
    Key? key,
    required this.item,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ItemEditDialog> createState() => _ItemEditDialogState();
}

class _ItemEditDialogState extends State<ItemEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _priceController = TextEditingController(text: widget.item.price.toString());
    _descriptionController = TextEditingController(text: widget.item.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать элемент'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Количество',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Цена',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
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
              quantity: double.tryParse(_quantityController.text) ?? widget.item.quantity,
              price: double.tryParse(_priceController.text) ?? widget.item.price,
              description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
            );
            widget.onSave(updatedItem);
            Navigator.pop(context);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class ItemCard extends StatelessWidget {
  final EstimateItem item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ItemCard({
    Key? key,
    required this.item,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEdit,
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Категория: ${item.category}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${item.quantity} ${item.unit} × ${item.price} руб.'),
                Text(
                  '${item.total.toStringAsFixed(2)} руб.',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
