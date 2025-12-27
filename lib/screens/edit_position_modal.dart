import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/line_item.dart';

class EditPositionModal extends StatefulWidget {
  final LineItem? initialItem;
  final Function(LineItem) onSave;

  const EditPositionModal({
    super.key,
    this.initialItem,
    required this.onSave,
  });

  @override
  State<EditPositionModal> createState() => _EditPositionModalState();
}

class _EditPositionModalState extends State<EditPositionModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  
  final _units = ['шт.', 'м²', 'м.п.', 'компл.', 'набор'];
  String _selectedUnit = 'шт.';
  
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _quantityFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(text: widget.initialItem?.name ?? '');
    _quantityController = TextEditingController(
      text: (widget.initialItem?.quantity ?? 1.0).toStringAsFixed(2)
    );
    _priceController = TextEditingController(
      text: (widget.initialItem?.price ?? 0.0).toStringAsFixed(2)
    );
    _descriptionController = TextEditingController(
      text: widget.initialItem?.description ?? ''
    );
    
    _selectedUnit = widget.initialItem?.unit ?? 'шт.';
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _nameFocus.dispose();
    _quantityFocus.dispose();
    _priceFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  void _savePosition() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Введите название позиции');
      return;
    }

    final quantityText = _quantityController.text.replaceAll(',', '.');
    final quantity = double.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      _showError('Введите корректное количество');
      return;
    }

    final priceText = _priceController.text.replaceAll(',', '.');
    final price = double.tryParse(priceText);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialItem != null && widget.initialItem!.id > 0
                  ? 'Редактировать позицию'
                  : 'Добавить позицию',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _nameController,
              focusNode: _nameFocus,
              decoration: const InputDecoration(
                labelText: 'Название позиции *',
                border: OutlineInputBorder(),
                hintText: 'Введите название',
                alignLabelWithHint: true,
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                _quantityFocus.requestFocus();
              },
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 15),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    focusNode: _quantityFocus,
                    decoration: const InputDecoration(
                      labelText: 'Количество *',
                      border: OutlineInputBorder(),
                      hintText: '1.00',
                      alignLabelWithHint: true,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      _priceFocus.requestFocus();
                    },
                    textDirection: TextDirection.ltr,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Единица',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedUnit = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _priceController,
              focusNode: _priceFocus,
              decoration: const InputDecoration(
                labelText: 'Цена (руб.) *',
                border: OutlineInputBorder(),
                prefixText: '₽ ',
                hintText: '0.00',
                alignLabelWithHint: true,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                _descriptionFocus.requestFocus();
              },
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _descriptionController,
              focusNode: _descriptionFocus,
              decoration: const InputDecoration(
                labelText: 'Описание (необязательно)',
                border: OutlineInputBorder(),
                hintText: 'Дополнительная информация',
                alignLabelWithHint: true,
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 25),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Отмена'),
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
                    child: Text(
                      widget.initialItem != null && widget.initialItem!.id > 0
                          ? 'Сохранить'
                          : 'Добавить',
                    ),
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
