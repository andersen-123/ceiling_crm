import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _areaController = TextEditingController();
  final double _pricePerM2 = 500; // примерная цена

  double? _total;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Калькулятор')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _areaController,
              decoration: const InputDecoration(labelText: 'Площадь м²'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final area = double.tryParse(_areaController.text);
                if (area != null) {
                  setState(() => _total = area * _pricePerM2);
                }
              },
              child: const Text('Рассчитать'),
            ),
            const SizedBox(height: 20),
            if (_total != null)
              Text('Цена: $_total ₽', style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
