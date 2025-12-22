import 'package:flutter/material.dart';
import 'package:ceiling_crm/database/database_helper.dart';
import 'package:ceiling_crm/models/client.dart';
import 'package:ceiling_crm/models/project.dart';
import 'package:ceiling_crm/models/project_worker.dart';
import 'package:ceiling_crm/models/transaction.dart';

class TestDataScreen extends StatefulWidget {
  const TestDataScreen({super.key});

  @override
  State<TestDataScreen> createState() => _TestDataScreenState();
}

class _TestDataScreenState extends State<TestDataScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _message = 'Нажмите кнопку для создания тестовых данных';

  Future<void> _createTestData() async {
    setState(() => _message = 'Создаю тестовые данные...');
    
    try {
      // Очищаем базу
      await _dbHelper.clearDatabase();
      
      // 1. Создаём клиента
      final client = Client(
        name: 'Дядя Миллионер',
        phone: '+7 (999) 123-45-67',
        objectAddress: 'Нежинская 1к2',
        notes: 'Постоянный клиент, любит качество',
        createdAt: DateTime.now(),
      );
      final clientId = await _dbHelper.insertClient(client);
      
      // 2. Создаём проект
      final project = Project(
        title: 'Объект: Нежинская 1к2',
        clientId: clientId,
        contractSum: 150000.0,
        prepaymentReceived: 50000.0,
        status: 'active',
        createdAt: DateTime.now(),
        deadline: DateTime.now().add(const Duration(days: 30)),
        workers: [
          ProjectWorker(
            projectId: 0, // Временно
            name: 'Лёша',
            hasCar: true,
          ),
          ProjectWorker(
            projectId: 0,
            name: 'Я',
            hasCar: false,
          ),
        ],
      );
      final projectId = await _dbHelper.insertProject(project);
      
      // 3. Добавляем транзакции
      final transactions = [
        // Доходы
        Transaction.income(
          projectId: projectId,
          amount: 50000.0,
          source: 'Аванс',
          comment: 'Предоплата 50%',
          date: DateTime.now().subtract(const Duration(days: 5)),
        ),
        
        // Расходы
        Transaction.gasoline(
          projectId: projectId,
          amount: 24000.0,
          comment: 'Бензин для объекта',
          date: DateTime.now().subtract(const Duration(days: 3)),
        ),
        
        Transaction.materials(
          projectId: projectId,
          amount: 35000.0,
          materialName: 'Полотна москва',
          comment: 'Закупка полотен',
          date: DateTime.now().subtract(const Duration(days: 2)),
        ),
        
        Transaction.materials(
          projectId: projectId,
          amount: 15000.0,
          materialName: 'Световое оборудование',
          comment: 'Светильники и провода',
          date: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      
      for (final transaction in transactions) {
        await _dbHelper.insertTransaction(transaction);
      }
      
      setState(() => _message = '''
✅ Тестовые данные созданы успешно!

Созданы:
• Клиент: ${client.name}
• Проект: ${project.title}
• Бригада: ${project.workers.length} чел.
• Транзакции: ${transactions.length} шт.

Сумма договора: ${project.contractSum} ₽
Аванс получен: ${project.prepaymentReceived} ₽

Расходы:
• Бензин: 24,000 ₽
• Материалы: 50,000 ₽

Теперь можно протестировать расчёт зарплаты по вашей формуле.
''');
      
    } catch (e) {
      setState(() => _message = '❌ Ошибка: $e');
    }
  }

  Future<void> _clearDatabase() async {
    setState(() => _message = 'Очищаю базу данных...');
    try {
      await _dbHelper.clearDatabase();
      setState(() => _message = '✅ База данных очищена');
    } catch (e) {
      setState(() => _message = '❌ Ошибка: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тестирование данных'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.data_usage,
                      size: 60,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Тестовые данные',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Создайте демо-данные для тестирования приложения',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      _message,
                      style: const TextStyle(fontSize: 14),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _createTestData,
                            icon: const Icon(Icons.add_circle),
                            label: const Text('Создать тестовые данные'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearDatabase,
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Очистить базу', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Что создаётся:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _BulletPoint(text: 'Клиент "Дядя Миллионер" с адресом объекта'),
                    _BulletPoint(text: 'Проект "Нежинская 1к2" на 150,000 ₽'),
                    _BulletPoint(text: 'Бригада: Лёша (водитель) и Я (монтажник)'),
                    _BulletPoint(text: 'Аванс 50,000 ₽ (доход)'),
                    _BulletPoint(text: 'Расход на бензин 24,000 ₽'),
                    _BulletPoint(text: 'Расход на материалы 50,000 ₽'),
                    SizedBox(height: 12),
                    Text(
                      'После создания можно проверить расчёт зарплаты по формуле:',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  
  const _BulletPoint({required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
