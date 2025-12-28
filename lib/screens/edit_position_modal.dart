import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/line_item.dart';

class EditPositionModal extends StatefulWidget {
  final LineItem? initialItem;
  final Function(LineItem)? onSave;
  final int? quoteId;
  
  const EditPositionModal({
    Key? key,
    this.initialItem,
    this.onSave,
    this.quoteId,
  }) : super(key: key);
  
  @override
  _EditPositionModalState createState() => _EditPositionModalState();
}

class _EditPositionModalState extends State<EditPositionModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _priceController;
  
  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(text: widget.initialItem?.name ?? '');
    _descriptionController = TextEditingController(text: widget.initialItem?.description ?? '');
    _quantityController = TextEditingController(
      text: widget.initialItem?.quantity.toString() ?? '1'
    );
    _unitController = TextEditingController(text: widget.initialItem?.unit ?? 'шт.');
    _priceController = TextEditingController(
      text: widget.initialItem?.price.toString() ?? '0'
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    super.dispose();
  }
  
  void _save() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final quantity = double.tryParse(_quantityController.text) ?? 1.0;
      final unit = _unitController.text.trim();
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final total = price * quantity;
      
      final item = LineItem(
        id: widget.initialItem?.id,
        quoteId: widget.initialItem?.quoteId ?? widget.quoteId ?? 0,
        name: name,
        description: description.isNotEmpty ? description : null,
        quantity: quantity,
        unit: unit,
        price: price,
        total: total,
        sortOrder: widget.initialItem?.sortOrder ?? 0,
        createdAt: widget.initialItem?.createdAt ?? DateTime.now(),
      );
      
      if (widget.onSave != null) {
        widget.onSave!(item);
      }
      
      Navigator.pop(context, item);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialItem != null && (widget.initialItem?.id ?? 0) > 0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать позицию' : 'Новая позиция'),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _save,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Наименование *',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите наименование';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              
              // Количество и единица измерения
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Количество *',
                        prefixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите количество';
                        }
                        final val = double.tryParse(value);
                        if (val == null || val <= 0) {
                          return 'Введите корректное количество';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: 'Ед. изм.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              // Цена
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Цена *',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                  suffixText: '₽',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите цену';
                  }
                  final val = double.tryParse(value);
                  if (val == null || val < 0) {
                    return 'Введите корректную цену';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              // Предпросмотр суммы
              Card(
                color: Colors.grey[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Сумма:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${_calculateTotal()} ₽',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 32),
              
              // Кнопка сохранения
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: Icon(Icons.save),
                  label: Text(isEditing ? 'ОБНОВИТЬ ПОЗИЦИЮ' : 'СОХРАНИТЬ ПОЗИЦИЮ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _calculateTotal() {
    try {
      final quantity = double.tryParse(_quantityController.text) ?? 1.0;
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final total = quantity * price;
      return total.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }
}
