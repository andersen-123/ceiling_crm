import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/services/database_helper.dart';
import 'package:ceiling_crm/screens/quote_edit_screen.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({Key? key}) : super(key: key);

  @override
  _QuoteListScreenState createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Quote> _quotes = [];
  double _totalRevenue = 0.0;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadQuotes();
    _loadRevenue();
  }

  Future<void> _loadQuotes() async {
    final quotes = await _dbHelper.getAllQuotes();
    setState(() {
      _quotes = quotes;
    });
  }

  Future<void> _loadRevenue() async {
    final revenue = await _dbHelper.getTotalRevenue();
    setState(() {
      _totalRevenue = revenue;
    });
  }

  List<Quote> _getFilteredQuotes() {
    if (_filterStatus == 'all') {
      return _quotes;
    }
    return _quotes.where((quote) => quote.status == _filterStatus).toList();
  }

  void _addNewQuote() async {
    final newQuote = Quote(
      clientName: 'Новый клиент',
      clientPhone: '',
      objectAddress: '',
    );

    final id = await _dbHelper.insertQuote(newQuote);
    
    // Создаем одну позицию по умолчанию для нового КП
    final defaultItem = LineItem(
      quoteId: id,
      name: 'Полотно MSD Premium белое матовое с установкой',
      unit: 'м²',
      price: 610.0,
      quantity: 0.0,
    );
    await _dbHelper.insertLineItem(defaultItem);

    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteEditScreen(quoteId: id),
      ),
    ).then((_) {
      _loadQuotes();
      _loadRevenue();
    });
  }

  void _editQuote(int quoteId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteEditScreen(quoteId: quoteId),
      ),
    ).then((_) {
      _loadQuotes();
      _loadRevenue();
    });
  }

  Future<void> _deleteQuote(int quoteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить КП'),
        content: const Text('Вы уверены, что хотите удалить это коммерческое предложение?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteQuote(quoteId);
      _loadQuotes();
      _loadRevenue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredQuotes = _getFilteredQuotes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Коммерческие предложения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadQuotes();
              _loadRevenue();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Статистика и фильтры
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Фильтры по статусу
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilter('all', 'Все'),
                      _buildStatusFilter('draft', 'Черновики'),
                      _buildStatusFilter('pending', 'На рассмотрении'),
                      _buildStatusFilter('accepted', 'Принятые'),
                      _buildStatusFilter('rejected', 'Отклоненные'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Статистика
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Всего КП',
                      _quotes.length.toString(),
                      Icons.description,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Выручка',
                      '${_totalRevenue.toStringAsFixed(0)} ₽',
                      Icons.attach_money,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Активные',
                      _quotes.where((q) => q.status == 'pending').length.toString(),
                      Icons.hourglass_empty,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Список КП
          Expanded(
            child: filteredQuotes.isEmpty
                ? const Center(
                    child: Text('Нет коммерческих предложений'),
                  )
                : ListView.builder(
                    itemCount: filteredQuotes.length,
                    itemBuilder: (context, index) {
                      final quote = filteredQuotes[index];
                      return _buildQuoteCard(quote);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewQuote,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusFilter(String status, String label) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterStatus = selected ? status : 'all';
          });
        },
        backgroundColor: isSelected ? Colors.blue[100] : null,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildQuoteCard(Quote quote) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: quote.statusColor.withOpacity(0.2),
          child: Icon(
            Icons.description,
            color: quote.statusColor,
          ),
        ),
        title: Text(quote.clientName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quote.objectAddress ?? 'Адрес не указан'),
            Text(
              'Создан: ${_formatDate(quote.createdAt)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(quote.statusText),
              backgroundColor: quote.statusColor.withOpacity(0.2),
              labelStyle: TextStyle(color: quote.statusColor),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editQuote(quote.id!);
                } else if (value == 'delete') {
                  _deleteQuote(quote.id!);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Редактировать'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Удалить'),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _editQuote(quote.id!),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
