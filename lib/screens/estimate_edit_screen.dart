import 'package:flutter/material.dart';
import '../models/estimate.dart';

class EstimateEditScreen extends StatefulWidget {
  final Estimate? estimate;
  const EstimateEditScreen({super.key, this.estimate});

  @override
  State<EstimateEditScreen> createState() => _EstimateEditScreenState();
}

class _EstimateEditScreenState extends State<EstimateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clientController;
  late TextEditingController _areaController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _clientController = TextEditingController(text: widget.estimate?.clientName ?? '');
    _areaController = TextEditingController(text: widget.estimate?.area.toString() ?? '');
    _priceController = TextEditingController(text: widget.estimate?.price.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактирование сметы')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _clientController,
                decoration: const InputDecoration(labelText: 'Имя клиента'),
                validator: (v) => v!.isEmpty ? 'Введите имя' : null,
              ),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(labelText: 'Площадь м²'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Введите площадь' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Цена ₽'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Введите цену' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final est = Estimate(
                      clientName: _clientController.text,
                      area: double.parse(_areaController.text),
                      price: double.parse(_priceController.text),
                      id: widget.estimate?.id,
                    );
                    Navigator.pop(context, est);
                  }
                },
                child: const Text('Сохранить'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
