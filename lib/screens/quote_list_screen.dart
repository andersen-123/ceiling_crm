// lib/screens/quote_list_screen.dart

import 'settings_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/quote_list_tile.dart';
import '../models/quote.dart';
import '../data/database_helper.dart';
import 'quote_edit_screen.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({Key? key}) : super(key: key);

  @override
  State<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // 1. Список КП
  List<Quote> _quotes = [];

  // 2. Загрузка данных
  bool _isLoading = true;

  // 3. Инициализация состояния
  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  // 4. Метод загрузки данных из БД
  Future<void> _loadQuotes() async {
    setState(() => _isLoading = true);
    try {
      final quotes = await DatabaseHelper().getAllQuotes();
      setState(() => _quotes = quotes);
    } catch (e) {
      // Временно выводим ошибку в консоль. Позже добавим уведомление.
      debugPrint('Ошибка загрузки КП: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 5. Метод удаления КП
  Future<void> _deleteQuote(int id, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить КП?'),
        content: Text('КП для ${_quotes[index].customerName} будет удалён.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper().deleteQuote(id);
        // Обновляем список локально
        setState(() => _quotes.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('КП удалён')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
      }
    }
  }

  // 6. Метод перехода к созданию нового КП
  void _navigateToCreateQuote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuoteEditScreen(existingQuote: null),
      ),
    ).then((value) {
      if (value == true) {
        _loadQuotes(); // Перезагружаем список после сохранения
      }
    });
  }
  // 7. Метод перехода к редактированию КП
  void _navigateToEditQuote(Quote quote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteEditScreen(existingQuote: quote),
      ),
    ).then((value) {
      if (value == true) {
        _loadQuotes(); // Перезагружаем список после сохранения
      }
    });
  }
    
  // 8. Построение бокового меню
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Заголовок Drawer
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description, size: 48, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Ceiling CRM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Управление КП',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Пункты меню
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Главная'),
                  onTap: () {
                    Navigator.pop(context); // Закрыть Drawer
                    // Уже на главной
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Настройки компании'),
                  onTap: () {
                    Navigator.pop(context); // Закрыть Drawer
                    _navigateToSettings();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('Статистика'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Добавить экран статистики
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Экран статистики в разработке')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Резервные копии'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Добавить резервное копирование
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Резервное копирование в разработке')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Справка'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Добавить справку
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('О приложении'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog();
                  },
                ),
              ],
            ),
          ),
          
          // Нижняя часть Drawer
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Версия 1.0.0',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'КП: ${_quotes.length}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
    // 9. Переход к настройкам
  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
  
    // 10. Диалог "О приложении"
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('О приложении'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ceiling CRM', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Приложение для управления коммерческими предложениями по натяжным потолкам.'),
            SizedBox(height: 12),
            Text('Функции:'),
            Text('• Создание и редактирование КП'),
            Text('• Управление позициями работ'),
            Text('• Экспорт в PDF'),
            Text('• Настройки компании'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
  
  // 8. Построение UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Мои КП'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotes,
            tooltip: 'Обновить',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quotes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Нет коммерческих предложений',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Нажмите "+" чтобы создать первое КП',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadQuotes,
                  child: ListView.builder(
                    itemCount: _quotes.length,
                    itemBuilder: (context, index) {
                      final quote = _quotes[index];
                      return QuoteListTile(
                        quote: quote,
                        onTap: () => _navigateToEditQuote(quote),
                        onDelete: () => _deleteQuote(quote.id!, index),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateQuote,
        child: const Icon(Icons.add),
        tooltip: 'Создать новое КП',
      ),
    );
  }
}
