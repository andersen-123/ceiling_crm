import 'package:flutter/material.dart';
import 'package:ceiling_crm/utils/test_data_generator.dart';

class DebugScreen extends StatefulWidget {
  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  bool _isGenerating = false;
  bool _isTesting = false;
  bool _isClearing = false;
  Map<String, dynamic>? _testResults;

  Future<void> _generateTestData() async {
    setState(() {
      _isGenerating = true;
      _testResults = null;
    });
    
    try {
      await TestDataGenerator.generateTestData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Тестовые данные успешно созданы'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _runTests() async {
    setState(() {
      _isTesting = true;
      _testResults = null;
    });
    
    try {
      final results = await TestDataGenerator.runTests();
      setState(() {
        _testResults = results;
      });
      
      if (results['all_passed'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Все тесты пройдены успешно!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Некоторые тесты не пройдены'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка тестирования: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _clearTestData() async {
    setState(() {
      _isClearing = true;
      _testResults = null;
    });
    
    try {
      await TestDataGenerator.clearTestData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Тестовые данные очищены'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isClearing = false;
      });
    }
  }

  Widget _buildTestResultCard() {
    if (_testResults == null) return SizedBox();
    
    final passed = _testResults!['passed'] ?? 0;
    final total = _testResults!['total'] ?? 0;
    final allPassed = _testResults!['all_passed'] ?? false;
    final results = _testResults!['results'] as Map<String, bool>?;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Результаты тестирования',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: allPassed ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$passed/$total',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            if (results != null)
              Column(
                children: results.entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          entry.value ? Icons.check_circle : Icons.error,
                          color: entry.value ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getTestName(entry.key),
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          entry.value ? 'Успех' : 'Ошибка',
                          style: TextStyle(
                            color: entry.value ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _getTestName(String key) {
    final names = {
      'create_quote': 'Создание КП',
      'add_line_item': 'Добавление позиции',
      'get_quote': 'Получение КП',
      'get_line_items': 'Получение позиций',
      'calculate_total': 'Расчет суммы',
      'update_status': 'Обновление статуса',
      'search_quotes': 'Поиск КП',
      'delete_quote': 'Удаление КП',
    };
    return names[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Отладка и тестирование'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Информация
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Инструменты разработчика',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Используйте эти инструменты для тестирования функционала приложения перед выпуском.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Кнопки действий
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateTestData,
                    icon: _isGenerating 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.data_array),
                    label: _isGenerating 
                        ? Text('Создание данных...')
                        : Text('Создать тестовые данные'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isTesting ? null : _runTests,
                    icon: _isTesting 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.play_arrow),
                    label: _isTesting 
                        ? Text('Запуск тестов...')
                        : Text('Запустить автоматические тесты'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isClearing ? null : _clearTestData,
                    icon: _isClearing 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.delete),
                    label: _isClearing 
                        ? Text('Очистка...')
                        : Text('Очистить тестовые данные'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Результаты тестов
            _buildTestResultCard(),
            
            SizedBox(height: 24),
            
            // Информация о версии
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Информация о приложении',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Версия:'),
                        Text('1.0.0', style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Архитектура:'),
                        Text('Модели + Репозиторий', style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('База данных:'),
                        Text('SQLite', style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PDF генерация:'),
                        Text('reportlab + printing', style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
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
