import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/services/database_helper.dart';
import 'package:ceiling_crm/screens/quote_edit_screen.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({Key? key}) : super(key: key);

  @override
  _QuoteListScreenState createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  late Future<List<Quote>> _quotesFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  void _loadQuotes() {
    setState(() {
      _quotesFuture = _dbHelper.getAllQuotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Коммерческие предложения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToEditScreen(null),
          ),
        ],
      ),
      body: FutureBuilder<List<Quote>>(
        future: _quotesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          
          final quotes = snapshot.data ?? [];
          
          if (quotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Нет коммерческих предложений'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _navigateToEditScreen(null),
                    child: const Text('Создать первое КП'),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: quotes.length,
            itemBuilder: (context, index) {
              final quote = quotes[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: const Icon(Icons.description, color: Colors.blue),
                  title: Text(quote.clientName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${quote.items.length} позиций'),
                      Text(
                        '${quote.totalAmount.toStringAsFixed(2)} руб.',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  trailing: Text(
                    quote.createdAt.toString().substring(0, 10),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => _navigateToEditScreen(quote.id),
                  onLongPress: () => _showDeleteDialog(quote),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _navigateToEditScreen(int? quoteId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteEditScreen(quoteId: quoteId),
      ),
    );
    
    if (result == true) {
      _loadQuotes();
    }
  }

  Future<void> _showDeleteDialog(Quote quote) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить КП?'),
        content: Text('Вы уверены, что хотите удалить КП для "${quote.clientName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await _dbHelper.deleteQuote(quote.id!);
              _loadQuotes();
              Navigator.pop(context);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
