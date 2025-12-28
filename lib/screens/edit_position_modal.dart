import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/line_item.dart';

class EditPositionModal extends StatefulWidget {
  final LineItem? initialItem;

  const EditPositionModal({
    Key? key,
    this.initialItem,
  }) : super(key: key);

  @override
  _EditPositionModalState createState() => _EditPositionModalState();
}

class _EditPositionModalState extends State<EditPositionModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _unitController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(text: widget.initialItem?.name ?? '');
    _unitController = TextEditingController(text: widget.initialItem?.unit ?? 'шт.');
    _priceController = TextEditingController(
      text: (widget.initialItem?.price ?? 0).toStringAsFixed(2),
    );
    _quantityController = TextEditingController(
      text: (widget.initialItem?.quantity ?? 1).toString(),
    );
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  LineItem _getUpdatedItem() {
    return LineItem(
      id: widget.initialItem?.id,
      quoteId: widget.initialItem?.quoteId ?? 0,
      name: _nameController.text.trim(),
      unit: _unitController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0.0,
      quantity: double.tryParse(_quantityController.text) ?? 1.0,
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_getUpdatedItem());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialItem == null ? 'Новая позиция' : 'Редактировать позицию'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Наименование *',
                icon: Icons.description,
                required: true,
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _unitController,
                      label: 'Единица измерения',
                      icon: Icons.straighten,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _quantityController,
                      label: 'Количество',
                      icon: Icons.format_list_numbered,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final quantity = double.tryParse(value ?? '');
                        if (quantity == null || quantity <= 0) {
                          return 'Введите корректное количество';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              _buildTextField(
                controller: _priceController,
                label: 'Цена за единицу *',
                icon: Icons.attach_money,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                required: true,
                validator: (value) {
                  final price = double.tryParse(value ?? '');
                  if (price == null || price < 0) {
                    return 'Введите корректную цену';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Расчет итоговой суммы
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Расчет',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Количество × Цена:'),
                          Text(
                            '${_quantityController.text} × ${_priceController.text}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Итого:'),
                          Text(
                            _calculateTotal(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _save,
          child: const Text('Сохранить позицию'),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: keyboardType,
        onChanged: (value) {
          // Пересчитываем итог при изменении
          if (keyboardType == TextInputType.numberWithOptions(decimal: true)) {
            setState(() {});
          }
        },
        validator: validator ?? (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'Это поле обязательно';
          }
          return null;
        },
      ),
    );
  }

  String _calculateTotal() {
    try {
      final quantity = double.tryParse(_quantityController.text) ?? 0;
      final price = double.tryParse(_priceController.text) ?? 0;
      final total = quantity * price;
      
      return '${total.toStringAsFixed(2)} ₽';
    } catch (e) {
      return '0.00 ₽';
    }
  }
}
