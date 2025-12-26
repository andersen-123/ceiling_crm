// lib/screens/quote_list_screen.dart

import 'package:flutter/material.dart';
import '../widgets/quote_list_tile.dart';
import '../models/quote.dart';
import '../data/database_helper.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({Key? key}) : super(key: key);

  @override
  State<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
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

  // 6. Метод перехода к созданию нового КП (пока заглушка)
  void _navigateToCreateQuote() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Placeholder()), // TODO: Заменить на QuoteEditScreen
    ).then((_) => _loadQuotes()); // Перезагружаем список после возврата
  }

  // 7. Метод перехода к редактированию КП (пока заглушка)
  void _navigateToEditQuote(Quote quote) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Placeholder()), // TODO: Заменить на QuoteEditScreen
    ).then((_) => _loadQuotes());
  }

  // 8. Построение UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои КП'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotes,
            tooltip: 'Обновить',
          ),
        ],
      ),
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
