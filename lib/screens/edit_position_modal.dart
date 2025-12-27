// lib/screens/edit_position_modal.dart
import 'package:flutter/material.dart';

class EditPositionModal extends StatefulWidget {
  final Map<String, dynamic> position;
  final Function(Map<String, dynamic>) onSave;

  const EditPositionModal({
    super.key,
    required this.position,
    required this.onSave,
  });

  @override
  State<EditPositionModal> createState() => _EditPositionModalState();
}

class _EditPositionModalState extends State<EditPositionModal> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _unitController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.position['name'] ?? '',
    );
    _quantityController = TextEditingController(
      text: (widget.position['quantity'] ?? 1).toString(),
    );
    _priceController = TextEditingController(
      text: (widget.position['price'] ?? 0).toString(),
    );
    _unitController = TextEditingController(
      text: widget.position['unit'] ?? 'шт.',
    );
    _descriptionController = TextEditingController(
      text: widget.position['description'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _savePosition() {
    final updatedPosition = {
      ...widget.position,
      'name': _nameController.text,
      'quantity': double.tryParse(_quantityController.text) ?? 1,
      'price': double.tryParse(_priceController.text) ?? 0,
      'unit': _unitController.text,
      'description': _descriptionController.text,
    };
    
    widget.onSave(updatedPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Редактирование позиции',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Название
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Наименование',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            // Количество и цена
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Количество',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Ед.изм.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Цена',
                      border: OutlineInputBorder(),
                      prefixText: '₽ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Примечание
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Примечание',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            
            // Кнопки
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, {'delete': true}),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Удалить'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _savePosition();
                      Navigator.pop(context);
                    },
                    child: const Text('Сохранить'),
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
