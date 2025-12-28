import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../services/database_helper.dart';
import 'quote_edit_screen.dart';
import 'quote_detail_screen.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({Key? key}) : super(key: key);

  @override
  _QuoteListScreenState createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Quote> _quotes = [];
  List<Quote> _filteredQuotes = [];
  Map<String, int> _stats = {};
  double _totalRevenue = 0.0;
  
  // Фильтр статусов
  String _selectedStatus = 'all';
  final List<Map<String, dynamic>> _statusFilters = [
    {'value': 'all', 'label': 'Все', 'color': Colors.grey},
    {'value': 'draft', 'label': 'Черновики', 'color': Colors.grey},
    {'value': 'sent', 'label': 'Отправленные', 'color': Colors.blue},
    {'value': 'accepted', 'label': 'Принятые', 'color': Colors.green},
    {'value': 'rejected', 'label': 'Отклоненные', 'color': Colors.red},
    {'value': 'expired', 'label': 'Просроченные', 'color': Colors.orange},
  ];

  @override
  void initState() {
    super.initState();
    _loadQuotes();
    _loadStatistics();
  }

  Future<void> _loadQuotes() async {
    final quotes = await _dbHelper.getAllQuotes();
    setState(() {
      _quotes = quotes;
      _applyFilter();
    });
  }

  Future<void> _loadStatistics() async {
    final stats = await _dbHelper.getQuotesStatistics();
    final revenue = await _dbHelper.getTotalRevenue();
    
    setState(() {
      _stats = stats;
      _totalRevenue = revenue;
    });
  }

  void _applyFilter() {
    if (_selectedStatus == 'all') {
      _filteredQuotes = _quotes;
    } else {
      _filteredQuotes = _quotes.where((quote) => quote.status == _selectedStatus).toList();
    }
  }

  void _onStatusFilterChanged(String? value) {
    if (value == null) return;
    
    setState(() {
      _selectedStatus = value;
      _applyFilter();
    });
  }

  Future<void> _refreshData() async {
    await _loadQuotes();
    await _loadStatistics();
  }

  void _showStatisticsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Статистика КП'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatItem('Всего КП:', _quotes.length.toString(), Colors.blue),
                _buildStatItem('Черновики:', _stats['draft']?.toString() ?? '0', Colors.grey),
                _buildStatItem('Отправленные:', _stats['sent']?.toString() ?? '0', Colors.blue),
                _buildStatItem('Принятые:', _stats['accepted']?.toString() ?? '0', Colors.green),
                _buildStatItem('Отклоненные:', _stats['rejected']?.toString() ?? '0', Colors.red),
                _buildStatItem('Просроченные:', _stats['expired']?.toString() ?? '0', Colors.orange),
                Divider(height: 20),
                _buildStatItem('Общая выручка:', '${_totalRevenue.toStringAsFixed(2)} ₽', Colors.green, isBold: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusInfo = {
      'draft': {'label': 'Черновик', 'color': Colors.grey},
      'sent': {'label': 'Отправлен', 'color': Colors.blue},
      'accepted': {'label': 'Принят', 'color': Colors.green},
      'rejected': {'label': 'Отклонен', 'color': Colors.red},
      'expired': {'label': 'Просрочен', 'color': Colors.orange},
    };
    
    final info = statusInfo[status] ?? {'label': status, 'color': Colors.grey};
    
    return Chip(
      label: Text(
        info['label'] as String,
        style: TextStyle(
          fontSize: 10,
          color: Colors.white,
        ),
      ),
      backgroundColor: info['color'] as Color,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Коммерческие предложения'),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: _showStatisticsDialog,
            tooltip: 'Статистика',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          // Фильтр статусов
          Container(
            padding: EdgeInsets.all(12),
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Фильтр по статусу:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((filter) {
                      final isSelected = _selectedStatus == filter['value'];
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            filter['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: filter['color'] as Color,
                          backgroundColor: Colors.grey[200],
                          onSelected: (selected) {
                            if (selected) {
                              _onStatusFilterChanged(filter['value'] as String?);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Найдено: ${_filteredQuotes.length} из ${_quotes.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Список КП
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: _filteredQuotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Нет коммерческих предложений',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _selectedStatus == 'all'
                                ? 'Создайте первое КП'
                                : 'Нет КП с выбранным статусом',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredQuotes.length,
                      itemBuilder: (context, index) {
                        final quote = _filteredQuotes[index];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: quote.statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '#${quote.id}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: quote.statusColor,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              quote.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  quote.clientName,
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildStatusChip(quote.status),
                                    SizedBox(width: 8),
                                    Text(
                                      '${quote.createdAt.day.toString().padLeft(2, '0')}.${quote.createdAt.month.toString().padLeft(2, '0')}.${quote.createdAt.year}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${quote.totalPrice.toStringAsFixed(2)} ₽',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Без НДС',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuoteDetailScreen(quote: quote),
                                ),
                              ).then((_) => _refreshData());
                            },
                            onLongPress: () {
                              _showQuoteActions(quote);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuoteEditScreen(),
            ),
          );
          
          if (result == true) {
            await _refreshData();
          }
        },
        icon: Icon(Icons.add),
        label: Text('Новое КП'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _showQuoteActions(Quote quote) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Редактировать'),
                onTap: () {
                  Navigator.pop(context);
                  _editQuote(quote);
                },
              ),
              ListTile(
                leading: Icon(Icons.content_copy, color: Colors.orange),
                title: Text('Создать копию'),
                onTap: () {
                  Navigator.pop(context);
                  _duplicateQuote(quote);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Удалить'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteQuote(quote);
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.close),
                title: Text('Отмена'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editQuote(Quote quote) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteEditScreen(quote: quote),
      ),
    );
    
    if (result == true) {
      await _refreshData();
    }
  }

  void _duplicateQuote(Quote original) async {
    // Создаем копию quote
    final newQuote = Quote(
      title: 'Копия: ${original.title}',
      clientName: original.clientName,
      clientPhone: original.clientPhone,
      clientEmail: original.clientEmail,
      clientAddress: original.clientAddress,
      createdAt: DateTime.now(),
      validUntil: original.validUntil,
      notes: original.notes,
      totalPrice: original.totalPrice,
      status: 'draft', // Копия всегда черновик
    );
    
    final newQuoteId = await _dbHelper.insertQuote(newQuote);
    
    // Копируем позиции
    final items = await _dbHelper.getLineItemsByQuoteId(original.id!);
    for (final item in items) {
      final newItem = LineItem(
        quoteId: newQuoteId,
        description: item.description,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        totalPrice: item.totalPrice,
      );
      await _dbHelper.insertLineItem(newItem);
    }
    
    await _refreshData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Копия КП создана')),
    );
  }

  void _deleteQuote(Quote quote) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Удалить КП?'),
          content: Text('Вы уверены, что хотите удалить КП "${quote.title}"? Это действие нельзя отменить.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                await _dbHelper.deleteQuote(quote.id!);
                Navigator.pop(context);
                await _refreshData();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('КП удалено')),
                );
              },
              child: Text(
                'Удалить',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
