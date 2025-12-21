import 'package:flutter/material.dart';
import '../models/estimate.dart';
import 'estimate_edit_screen.dart';

class EstimateListScreen extends StatefulWidget {
  const EstimateListScreen({super.key});

  @override
  State<EstimateListScreen> createState() => _EstimateListScreenState();
}

class _EstimateListScreenState extends State<EstimateListScreen> {
  final List<Estimate> _estimates = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сметы')),
      body: ListView.builder(
        itemCount: _estimates.length,
        itemBuilder: (context, index) {
          final est = _estimates[index];
          return ListTile(
            title: Text(est.clientName),
            subtitle: Text('Площадь: ${est.area} м², Цена: ${est.price} ₽'),
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EstimateEditScreen(estimate: est),
                ),
              );
              if (updated != null) {
                setState(() {
                  _estimates[index] = updated;
                });
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final newEstimate = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EstimateEditScreen()),
          );
          if (newEstimate != null) {
            setState(() => _estimates.add(newEstimate));
          }
        },
      ),
    );
  }
}
