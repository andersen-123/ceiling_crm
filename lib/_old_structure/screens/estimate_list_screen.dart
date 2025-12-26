import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../database/database_helper.dart';
import '../models/estimate.dart';

class EstimateListScreen extends StatefulWidget {
  const EstimateListScreen({super.key});

  @override
  State<EstimateListScreen> createState() => _EstimateListScreenState();
}

class _EstimateListScreenState extends State<EstimateListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Estimate> _estimates = [];

  @override
  void initState() {
    super.initState();
    _loadEstimates();
  }

  Future<void> _loadEstimates() async {
    final estimates = await _dbHelper.getEstimates();
    setState(() {
      _estimates = estimates;
    });
  }

  Future<void> _deleteEstimate(int id) async {
    await _dbHelper.deleteEstimate(id);
    _loadEstimates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Список смет')),
      body: ListView.builder(
        itemCount: _estimates.length,
        itemBuilder: (context, index) {
          final estimate = _estimates[index];
          return ListTile(
            title: Text(estimate.name ?? '${estimate.clientName} - ${estimate.createdDate.toString().substring(0, 10)}'),
            subtitle: Text('Итого: ${estimate.total} ₽'),
            onTap: () => context.go('/estimate_edit', extra: estimate),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteEstimate(estimate.id!),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => context.go('/estimate_edit'),
      ),
    );
  }
}
