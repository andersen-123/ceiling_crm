import 'package:flutter/material.dart';
import '../models/estimate.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  double _total = 0.0;

  void _calculate() {
    final double width = double.tryParse(_widthController.text) ?? 0;
    final double length = double.tryParse(_lengthController.text) ?? 0;
    final double price = double.tryParse(_priceController.text) ?? 0;

    setState(() {
      _total = width * length * price;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Калькулятор сметы')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _widthController,
              decoration: const InputDecoration(labelText: 'Ширина (м)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _lengthController,
              decoration: const InputDecoration(labelText: 'Длина (м)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Цена за м² (₽)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('Рассчитать'),
            ),
            const SizedBox(height: 20),
            Text(
              'Итого: $_total ₽',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
