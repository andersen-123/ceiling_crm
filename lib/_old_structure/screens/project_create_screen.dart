import 'package:flutter/material.dart';
import 'package:ceiling_crm/database/database_helper.dart';
import 'package:ceiling_crm/models/project.dart';
import 'package:ceiling_crm/models/project_worker.dart';

class ProjectCreateScreen extends StatefulWidget {
  final VoidCallback onProjectCreated;

  const ProjectCreateScreen({
    super.key,
    required this.onProjectCreated,
  });

  @override
  State<ProjectCreateScreen> createState() => _ProjectCreateScreenState();
}

class _ProjectCreateScreenState extends State<ProjectCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Поля формы
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contractSumController = TextEditingController();
  final TextEditingController _prepaymentController = TextEditingController();
  String _status = 'plan';

  // Список работников
  final List<ProjectWorker> _workers = [];
  final TextEditingController _workerNameController = TextEditingController();
  bool _workerHasCar = false;

  void _addWorker() {
    final name = _workerNameController.text.trim();
    if (name.isEmpty) return;

    final worker = ProjectWorker(
      projectId: 0, // Временное значение
      name: name,
      hasCar: _workerHasCar,
    );

    setState(() {
      _workers.add(worker);
      _workerNameController.clear();
      _workerHasCar = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Добавлен работник: $name')),
    );
  }

  void _removeWorker(int index) {
    setState(() {
      _workers.removeAt(index);
    });
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    if (_workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте хотя бы одного работника'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final project = Project(
      title: _titleController.text.trim(),
      contractSum: double.parse(_contractSumController.text),
      prepaymentReceived: double.parse(_prepaymentController.text),
      status: _status,
      createdAt: DateTime.now(),
      workers: _workers,
    );

    try {
      await _dbHelper.insertProject(project);
      widget.onProjectCreated();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Проект успешно создан'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый проект'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProject,
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
              // Основная информация
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Основная информация',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Название проекта',
                          hintText: 'Например: Объект Нежинская 1к2',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите название проекта';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _contractSumController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Сумма договора',
                                suffixText: '₽',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Введите сумму';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Введите число';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _prepaymentController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Аванс',
                                suffixText: '₽',
                                border: OutlineInputBorder(),
                              ),
                              initialValue: '0',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Статус',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'plan',
                            child: Text('Планирование'),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('В работе'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('Завершён'),
                          ),
                          DropdownMenuItem(
                            value: 'paid',
                            child: Text('Оплачен'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _status = value!);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Бригада
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Бригада',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _workerNameController,
                              decoration: const InputDecoration(
                                labelText: 'Имя работника',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          CheckboxListTile(
                            title: const Text('Авто'),
                            value: _workerHasCar,
                            onChanged: (value) {
                              setState(() => _workerHasCar = value!);
                            },
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, size: 40),
                            color: Colors.blue,
                            onPressed: _addWorker,
                            tooltip: 'Добавить работника',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Список добавленных работников
              if (_workers.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Добавленные работники',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_workers.length} чел.',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._workers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final worker = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: worker.hasCar ? Colors.blue[50] : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(worker.name.substring(0, 1)),
                              ),
                              title: Text(worker.name),
                              subtitle: worker.hasCar
                                  ? const Text('Имеет автомобиль')
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeWorker(index),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Отмена'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProject,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Создать проект'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contractSumController.dispose();
    _prepaymentController.dispose();
    _workerNameController.dispose();
    super.dispose();
  }
}
