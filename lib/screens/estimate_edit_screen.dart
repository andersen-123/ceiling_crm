import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../database/database_helper.dart';
import '../models/estimate.dart';
import '../services/auto_save_service.dart';

class EstimateEditScreen extends StatefulWidget {
  final Estimate? estimate;
  const EstimateEditScreen({super.key, this.estimate});

  @override
  State<EstimateEditScreen> createState() => _EstimateEditScreenState();
}

class _EstimateEditScreenState extends State<EstimateEditScreen> {
  final _nameController = TextEditingController();
  final _totalController = TextEditingController();
  final AutoSaveService _autoSaveService = AutoSaveService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Estimate? _estimate;

  @override
  void initState() {
    super.initState();
    _estimate = widget.estimate ?? Estimate(name: '', total: 0.0);
    _nameController.text = _estimate!.name;
    _totalController.text = _estimate!.total.toString();
    _autoSaveService.startAutoSave(_estimate!);
  }

  @override
  void dispose() {
    _autoSaveService.stop();
    _nameController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    _estimate!
      ..name = _nameController.text
      ..total = double.tryParse(_totalController.text) ?? 0.0;

    if (_estimate!.id == null) {
      await _dbHelper.insertEstimate(_estimate!);
    } else {
      await _dbHelper.updateEstimate(_estimate!);
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактирование сметы')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Название сметы'),
            ),
            TextField(
              controller: _totalController,
              decoration: const InputDecoration(labelText: 'Итого, ₽'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
