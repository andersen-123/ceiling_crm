import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ceiling CRM')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Добро пожаловать в Ceiling CRM!',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => context.go('/estimates'),
              icon: const Icon(Icons.list),
              label: const Text('Список смет'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.go('/calculator'),
              icon: const Icon(Icons.calculate),
              label: const Text('Калькулятор'),
            ),
          ],
        ),
      ),
    );
  }
}
