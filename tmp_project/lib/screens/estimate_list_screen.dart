import 'package:flutter/material.dart';
import 'estimate_edit_screen.dart';
import 'calculator_screen.dart';

class EstimatesListScreen extends StatelessWidget {
  const EstimatesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои сметы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('PotolokForLife'),
                  content: const Text(
                    'Приложение для расчета смет натяжных потолков\n\n'
                    'Используйте калькулятор для создания сметы на основе реальных цен из Excel-шаблона.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Список смет',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Для начала работы создайте смету через калькулятор',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalculatorScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.calculate),
              label: const Text('Открыть калькулятор'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EstimateEditScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Новая смета'),
      ),
    );
  }
}
