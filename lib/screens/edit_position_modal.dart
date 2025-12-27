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
        text: widget.position['name'] ?? '');
    _quantityController = TextEditingController(
        text: (widget.position['quantity'] ?? 1).toString());
    _priceController = TextEditingController(
        text: (widget.position['price'] ?? 0).toString());
    _unitController = TextEditingController(
        text: widget.position['unit'] ?? 'шт.');
    _descriptionController = TextEditingController(
        text: widget.position['description'] ?? '');
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
    
    // Рассчитываем сумму
    final quantity = double.tryParse(_quantityController.text) ?? 1;
    final price = double.tryParse(_priceController.text) ?? 0;
    updatedPosition['total'] = quantity * price;
    
    widget.onSave(updatedPosition);
    Navigator.pop(context);
  }

  void _deletePosition() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить позицию?'),
        content: const Text('Вы уверены, что хотите удалить эту позицию?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Закрываем диалог подтверждения
              Navigator.pop(context, {'delete': true}); // Возвращаем флаг удаления
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Редактирование позиции',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Название позиции
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Наименование',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              
              // Количество и цена в одной строке
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Количество',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _updateTotal(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: 'Ед.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Цена, ₽',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixText: '₽ ',
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _updateTotal(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Итого
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Сумма:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${_calculateTotal().toStringAsFixed(2)} ₽',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Описание
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Примечание',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deletePosition,
                      icon: const Icon(Icons.delete, size: 20),
                      label: const Text('Удалить'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _savePosition,
                      icon: const Icon(Icons.save, size: 20),
                      label: const Text('Сохранить'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    return quantity * price;
  }

  void _updateTotal() {
    setState(() {});
  }
}
