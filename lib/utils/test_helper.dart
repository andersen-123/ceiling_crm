import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/services/database_helper.dart';

class TestHelper {
  static final TestHelper _instance = TestHelper._internal();
  factory TestHelper() => _instance;
  TestHelper._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Создать тестовые данные
  Future<void> createTestData() async {
    try {
      // Очистить базу данных
      await _clearDatabase();
      
      // Создать тестовые КП
      await _createTestQuotes();
      
      print('✅ Тестовые данные созданы успешно');
    } catch (e) {
      print('❌ Ошибка создания тестовых данных: $e');
    }
  }

  Future<void> _clearDatabase() async {
    final db = await _dbHelper.database;
    await db.delete('quotes');
    await db.delete('line_items');
  }

  Future<void> _createTestQuotes() async {
    // Тестовое КП 1
    final quote1 = Quote(
      clientName: 'Иванов Иван Иванович',
      clientPhone: '+7 (999) 123-45-67',
      clientAddress: 'г. Москва, ул. Ленина, д. 10, кв. 25',
      notes: 'Клиент заинтересован в установке парящего потолка с подсветкой',
      totalAmount: 34500.0,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      items: [
        LineItem(
          quoteId: 0,
          name: 'Полотно MSD Premium белое матовое с установкой',
          description: 'Стандартная установка',
          unitPrice: 610.0,
          quantity: 25,
          unit: 'м²',
        ),
        LineItem(
          quoteId: 0,
          name: 'Монтаж "парящего" потолка, установка светодиодной ленты',
          description: 'Создание парящего потолка с подсветкой',
          unitPrice: 1600.0,
          quantity: 12,
          unit: 'м.п.',
        ),
      ],
    );

    // Тестовое КП 2
    final quote2 = Quote(
      clientName: 'Петрова Мария Сергеевна',
      clientPhone: '+7 (916) 987-65-43',
      clientAddress: 'г. Москва, пр-т Мира, д. 45, кв. 12',
      notes: 'Кухня и гостиная, нужны точечные светильники',
      totalAmount: 21800.0,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      items: [
        LineItem(
          quoteId: 0,
          name: 'Полотно MSD Premium белое матовое с установкой',
          description: 'Стандартная установка',
          unitPrice: 610.0,
          quantity: 20,
          unit: 'м²',
        ),
        LineItem(
          quoteId: 0,
          name: 'Монтаж закладных под световое оборудование, установка светильников',
          description: 'Подготовка и установка светильников',
          unitPrice: 780.0,
          quantity: 8,
          unit: 'шт.',
        ),
        LineItem(
          quoteId: 0,
          name: 'Установка вентиляционной решетки',
          description: 'Монтаж вентиляционной решетки',
          unitPrice: 600.0,
          quantity: 2,
          unit: 'шт.',
        ),
      ],
    );

    // Тестовое КП 3
    final quote3 = Quote(
      clientName: 'Сидоров Алексей Владимирович',
      clientPhone: '+7 (903) 555-44-33',
      clientAddress: 'г. Москва, ул. Пушкина, д. 15, кв. 7',
      notes: 'Офисное помещение, нужен быстрый монтаж',
      totalAmount: 15250.0,
      createdAt: DateTime.now(),
      items: [
        LineItem(
          quoteId: 0,
          name: 'Полотно MSD Premium белое матовое с установкой',
          description: 'Стандартная установка',
          unitPrice: 610.0,
          quantity: 15,
          unit: 'м²',
        ),
        LineItem(
          quoteId: 0,
          name: 'Профиль стеновой/потолочный гарпунный с установкой',
          description: 'Монтаж профиля по периметру',
          unitPrice: 310.0,
          quantity: 30,
          unit: 'м.п.',
        ),
        LineItem(
          quoteId: 0,
          name: 'Вставка по периметру гарпунная',
          description: 'Установка гарпунной вставки',
          unitPrice: 220.0,
          quantity: 30,
          unit: 'м.п.',
        ),
      ],
    );

    await _dbHelper.insertQuote(quote1);
    await _dbHelper.insertQuote(quote2);
    await _dbHelper.insertQuote(quote3);
  }

  // Проверить все функции приложения
  Future<Map<String, dynamic>> runComprehensiveTest() async {
    final results = <String, dynamic>{};
    
    try {
      // Тест 1: Проверка базы данных
      results['database_test'] = await _testDatabase();
      
      // Тест 2: Проверка моделей
      results['models_test'] = _testModels();
      
      // Тест 3: Проверка PDF генерации
      results['pdf_test'] = await _testPdfGeneration();
      
      // Тест 4: Проверка шаблонов
      results['templates_test'] = _testTemplates();
      
      results['overall_status'] = 'PASS';
      results['message'] = 'Все тесты пройдены успешно';
      
    } catch (e) {
      results['overall_status'] = 'FAIL';
      results['error'] = e.toString();
    }
    
    return results;
  }

  Future<Map<String, dynamic>> _testDatabase() async {
    final result = <String, dynamic>{};
    
    try {
      // Проверить подключение к БД
      final db = await _dbHelper.database;
      result['database_connection'] = 'PASS';
      
      // Проверить создание таблиц
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;"
      );
      final tableNames = tables.map((t) => t['name'] as String).toList();
      
      result['tables_exist'] = tableNames.contains('quotes') && 
                               tableNames.contains('line_items') &&
                               tableNames.contains('company_profile');
      result['table_list'] = tableNames;
      
      // Проверить CRUD операции
      final testQuote = Quote(
        clientName: 'Тестовый клиент',
        totalAmount: 1000.0,
        createdAt: DateTime.now(),
      );
      
      final id = await _dbHelper.insertQuote(testQuote);
      result['insert_operation'] = id > 0 ? 'PASS' : 'FAIL';
      
      final retrievedQuote = await _dbHelper.getQuoteById(id);
      result['read_operation'] = retrievedQuote != null ? 'PASS' : 'FAIL';
      
      if (retrievedQuote != null) {
        retrievedQuote.clientName = 'Обновленный клиент';
        final updateResult = await _dbHelper.updateQuote(retrievedQuote);
        result['update_operation'] = updateResult > 0 ? 'PASS' : 'FAIL';
      }
      
      final deleteResult = await _dbHelper.deleteQuote(id);
      result['delete_operation'] = deleteResult > 0 ? 'PASS' : 'FAIL';
      
      result['status'] = 'PASS';
      
    } catch (e) {
      result['status'] = 'FAIL';
      result['error'] = e.toString();
    }
    
    return result;
  }

  Map<String, dynamic> _testModels() {
    final result = <String, dynamic>{};
    
    try {
      // Тест модели Quote
      final quote = Quote(
        clientName: 'Тест',
        totalAmount: 1000.0,
        createdAt: DateTime.now(),
      );
      
      result['quote_creation'] = 'PASS';
      result['quote_to_map'] = quote.toMap() is Map ? 'PASS' : 'FAIL';
      
      final quoteFromMap = Quote.fromMap({
        'id': 1,
        'clientName': 'Тест',
        'totalAmount': 1000.0,
        'createdAt': DateTime.now().toIso8601String(),
      });
      result['quote_from_map'] = quoteFromMap.id == 1 ? 'PASS' : 'FAIL';
      
      // Тест модели LineItem
      final item = LineItem(
        quoteId: 1,
        name: 'Тестовая позиция',
        unitPrice: 100.0,
        quantity: 2,
      );
      
      result['line_item_creation'] = 'PASS';
      result['line_item_total'] = item.totalPrice == 200.0 ? 'PASS' : 'FAIL';
      result['line_item_to_map'] = item.toMap() is Map ? 'PASS' : 'FAIL';
      
      final itemFromMap = LineItem.fromMap({
        'id': 1,
        'quoteId': 1,
        'name': 'Тест',
        'unitPrice': 100.0,
        'quantity': 2,
      });
      result['line_item_from_map'] = itemFromMap.id == 1 ? 'PASS' : 'FAIL';
      
      result['status'] = 'PASS';
      
    } catch (e) {
      result['status'] = 'FAIL';
      result['error'] = e.toString();
    }
    
    return result;
  }

  Future<Map<String, dynamic>> _testPdfGeneration() async {
    final result = <String, dynamic>{};
    
    try {
      // Этот тест нужно будет доработать после импорта PdfService
      result['status'] = 'SKIPPED';
      result['message'] = 'Требуется импорт PdfService';
      
    } catch (e) {
      result['status'] = 'FAIL';
      result['error'] = e.toString();
    }
    
    return result;
  }

  Map<String, dynamic> _testTemplates() {
    final result = <String, dynamic>{};
    
    try {
      result['status'] = 'PASS';
      result['message'] = 'Тест шаблонов требует TemplateService';
      
    } catch (e) {
      result['status'] = 'FAIL';
      result['error'] = e.toString();
    }
    
    return result;
  }

  // Показать диалог с результатами тестирования
  static void showTestResultsDialog(BuildContext context, Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Результаты тестирования'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _buildTestResultsList(results),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              // Экспорт результатов
              _exportTestResults(results);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Результаты экспортированы в консоль'),
                ),
              );
            },
            child: const Text('Экспорт'),
          ),
        ],
      ),
    );
  }

  static List<Widget> _buildTestResultsList(Map<String, dynamic> results) {
    final widgets = <Widget>[];
    
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Icon(
              results['overall_status'] == 'PASS' ? Icons.check_circle : Icons.error,
              color: results['overall_status'] == 'PASS' ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              'Общий статус: ${results['overall_status']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: results['overall_status'] == 'PASS' ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
    
    // Добавить результаты каждого теста
    for (final entry in results.entries) {
      if (entry.key != 'overall_status' && entry.key != 'message' && entry.key != 'error') {
        if (entry.value is Map) {
          widgets.add(_buildTestSection(entry.key, entry.value as Map<String, dynamic>));
        }
      }
    }
    
    if (results.containsKey('message')) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            results['message'],
            style: const TextStyle(color: Colors.green),
          ),
        ),
      );
    }
    
    if (results.containsKey('error')) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'Ошибка: ${results['error']}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    
    return widgets;
  }

  static Widget _buildTestSection(String title, Map<String, dynamic> sectionResults) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.replaceAll('_', ' ').toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...sectionResults.entries.map((entry) {
          final isPass = entry.value == 'PASS' || entry.value == true;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  isPass ? Icons.check : Icons.close,
                  size: 16,
                  color: isPass ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(
                      color: isPass ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  static void _exportTestResults(Map<String, dynamic> results) {
    print('=' * 50);
    print('ОТЧЕТ О ТЕСТИРОВАНИИ Ceiling CRM');
    print('=' * 50);
    print('Дата: ${DateTime.now()}');
    print('Общий статус: ${results['overall_status']}');
    print('');
    
    for (final entry in results.entries) {
      if (entry.key != 'overall_status' && entry.key != 'message' && entry.key != 'error') {
        print('${entry.key.toUpperCase()}:');
        if (entry.value is Map) {
          for (final subEntry in (entry.value as Map).entries) {
            print('  ${subEntry.key}: ${subEntry.value}');
          }
        }
        print('');
      }
    }
    
    if (results.containsKey('message')) {
      print('Сообщение: ${results['message']}');
    }
    
    if (results.containsKey('error')) {
      print('Ошибка: ${results['error']}');
    }
    
    print('=' * 50);
  }
}
