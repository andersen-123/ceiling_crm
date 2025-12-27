import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/line_item.dart';

class EditPositionModal extends StatefulWidget {
  final LineItem? initialItem;
  final Function(LineItem) onSave;
  final bool isEditing;

  const EditPositionModal({
    super.key,
    this.initialItem,
    required this.onSave,
    this.isEditing = false,
  });

  @override
  State<EditPositionModal> createState() => _EditPositionModalState();
}

class _EditPositionModalState extends State<EditPositionModal> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  final List<String> _units = ['шт.', 'м²', 'м.п.', 'компл.', 'набор'];
  String _selectedUnit = 'шт.';

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(text: widget.initialItem?.name ?? '');
    _quantityController = TextEditingController(
      text: widget.initialItem?.quantity.toStringAsFixed(2) ?? '1.00'
    );
    _unitController = TextEditingController(text: widget.initialItem?.unit ?? 'шт.');
    _priceController = TextEditingController(
      text: widget.initialItem?.price.toStringAsFixed(2) ?? '0.00'
    );
    _descriptionController = TextEditingController(text: widget.initialItem?.description ?? '');
    
    _selectedUnit = widget.initialItem?.unit ?? 'шт.';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _savePosition() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Введите название позиции');
      return;
    }

    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.'));
    if (quantity == null || quantity <= 0) {
      _showError('Введите корректное количество');
      return;
    }

    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (price == null || price < 0) {
      _showError('Введите корректную цену');
      return;
    }

    final description = _descriptionController.text.trim();

    final item = LineItem(
      id: widget.initialItem?.id ?? 0,
      name: name,
      quantity: quantity,
      unit: _selectedUnit,
      price: price,
      description: description,
    );

    widget.onSave(item);
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.isEditing ? 'Редактировать позицию' : 'Добавить позицию',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название позиции *',
                border: OutlineInputBorder(),
                hintText: 'Введите название',
              ),
              textInputAction: TextInputAction.next,
              autofocus: true,
            ),
            const SizedBox(height: 15),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Количество *',
                      border: OutlineInputBorder(),
                      hintText: '1.00',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Единица',
                      border: OutlineInputBorder(),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUnit = value ?? 'шт.';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Цена (руб.) *',
                border: OutlineInputBorder(),
                prefixText: '₽ ',
                hintText: '0.00',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 15),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание (необязательно)',
                border: OutlineInputBorder(),
                hintText: 'Дополнительная информация',
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 25),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Отмена', style: TextStyle(color: Colors.black87)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _savePosition,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(widget.isEditing ? 'Сохранить' : 'Добавить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
