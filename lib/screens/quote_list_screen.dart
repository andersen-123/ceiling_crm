// Главный экран приложения - список коммерческих предложений.
// Отображает все КП из базы данных с возможностью поиска, фильтрации и действий.

import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/quote.dart';
import '../widgets/quote_list_tile.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({super.key});

  @override
  QuoteListScreenState createState() => QuoteListScreenState();
}

class QuoteListScreenState extends State<QuoteListScreen> {
  // Хранилище данных
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // Состояние экрана
  List<Quote> _quotes = [];
  List<Quote> _filteredQuotes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'all';

  // Доступные статусы для фильтрации
  final List<Map<String, String>> _statusFilters = [
    {'value': 'all', 'label': 'Все'},
    {'value': 'draft', 'label': 'Черновик'},
    {'value': 'sent', 'label': 'Отправлено'},
    {'value': 'approved', 'label': 'Согласовано'},
    {'value': 'completed', 'label': 'Выполнено'},
  ];

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  // Загрузка данных из базы
  Future<void> _loadQuotes() async {
    setState(() => _isLoading = true);
    
    try {
      final quotes = await _dbHelper.getAllQuotes();
      setState(() {
        _quotes = quotes;
        _filteredQuotes = quotes;
      });
    } catch (error) {
      _showErrorSnackbar('Ошибка загрузки: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Применение фильтров (поиск + статус)
  void _applyFilters() {
    List<Quote> result = _quotes;

    // Фильтр по статусу
    if (_selectedStatus != 'all') {
      result = result.where((quote) => quote.status == _selectedStatus).toList();
    }

    // Поиск по тексту
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((quote) {
        return quote.customerName.toLowerCase().contains(query) ||
            (quote.address?.toLowerCase().contains(query) ?? false) ||
            (quote.objectName.toLowerCase().contains(query)) ||
            (quote.notes?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    setState(() => _filteredQuotes = result);
  }

  // Удаление КП (мягкое)
  Future<void> _deleteQuote(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить КП?'),
        content: const Text('Коммерческое предложение будет перемещено в корзину.'),
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
        await _dbHelper.softDeleteQuote(id);
        _showSuccessSnackbar('КП перемещено в корзину');
        _loadQuotes(); // Перезагружаем список
      } catch (error) {
        _showErrorSnackbar('Ошибка удаления: $error');
      }
    }
  }

  // Создание нового КП
  void _createNewQuote() {
    // TODO: Переход на экран создания (будет в Этапе 3)
    _showInfoSnackbar('Функция создания КП будет доступна в следующем обновлении');
  }

  // Дублирование КП
  Future<void> _duplicateQuote(Quote quote) async {
    try {
      final newQuote = quote.copyWith(
        id: null,
        customerName: '${quote.customerName} (копия)',
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: null,
      );
      
      await _dbHelper.insertQuote(newQuote);
      _showSuccessSnackbar('КП успешно скопировано');
      _loadQuotes();
    } catch (error) {
      _showErrorSnackbar('Ошибка копирования: $error');
    }
  }

  // Вспомогательные методы для уведомлений
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Статистика для отображения в заголовке
  Map<String, dynamic> _getStats() {
    final total = _quotes.length;
    final filtered = _filteredQuotes.length;
    final totalAmount = _quotes.fold(0.0, (sum, quote) => sum + quote.totalAmount);
    
    return {
      'total': total,
      'filtered': filtered,
      'totalAmount': totalAmount,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Коммерческие предложения'),
        actions: [
          // Индикатор фильтра
          if (_selectedStatus != 'all' || _searchQuery.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text(stats['filtered'].toString()),
                child: const Icon(Icons.filter_alt),
              ),
              onPressed: () {
                // Сброс фильтров
                setState(() {
                  _selectedStatus = 'all';
                  _searchQuery = '';
                });
                _applyFilters();
              },
              tooltip: 'Сбросить фильтры',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadQuotes,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          // Панель поиска и фильтров
          _buildFilterPanel(),
          
          // Статистика
          _buildStatsPanel(stats),
          
          // Список КП
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQuotes.isEmpty
                    ? _buildEmptyState()
                    : _buildQuoteList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewQuote,
        tooltip: 'Создать КП',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Панель фильтров и поиска
  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Строка поиска
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Поиск по клиенту, адресу...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Кнопка расширенного фильтра
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (value) {
                  setState(() => _selectedStatus = value);
                  _applyFilters();
                },
                itemBuilder: (context) => _statusFilters.map((filter) {
                  return PopupMenuItem<String>(
                    value: filter['value'],
                    child: Row(
                      children: [
                        Icon(
                          _selectedStatus == filter['value']
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: _selectedStatus == filter['value']
                              ? Colors.blue
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(filter['label']!),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Панель статистики
  Widget _buildStatsPanel(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Найдено: ${stats['filtered']} из ${stats['total']}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              if (stats['total'] > 0)
                Text(
                  'Общая сумма: ${stats['totalAmount'].toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
            ],
          ),
          if (_searchQuery.isNotEmpty || _selectedStatus != 'all')
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedStatus = 'all';
                });
                _applyFilters();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
              ),
              child: const Text('Сбросить', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  // Пустое состояние
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Нет коммерческих предложений',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedStatus != 'all'
                ? 'Попробуйте изменить фильтры'
                : 'Создайте первое КП, нажав на кнопку ниже',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _createNewQuote,
            icon: const Icon(Icons.add),
            label: const Text('Создать КП'),
          ),
        ],
      ),
    );
  }

  // Список КП
  Widget _buildQuoteList() {
    return RefreshIndicator(
      onRefresh: _loadQuotes,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filteredQuotes.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final quote = _filteredQuotes[index];
          return QuoteListTile(
            quote: quote,
            onTap: () {
              // TODO: Переход на экран редактирования (Этап 3)
              _showInfoSnackbar('Редактирование КП #${quote.id}');
            },
            onDelete: () => _deleteQuote(quote.id!),
            onDuplicate: () => _duplicateQuote(quote),
          );
        },
      ),
    );
  }
}
