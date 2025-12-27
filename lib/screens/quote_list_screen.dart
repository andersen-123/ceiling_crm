// lib/screens/quote_list_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/services/database_helper.dart';
import 'package:ceiling_crm/screens/quote_edit_screen.dart';
import 'package:ceiling_crm/screens/proposal_detail_screen.dart';
import 'package:ceiling_crm/widgets/quote_list_tile.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({super.key});

  @override
  State<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Quote> _quotes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  // Загрузка всех КП из базы
  Future<void> _loadQuotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quotes = await _dbHelper.getAllProposals();
      setState(() {
        _quotes = quotes;
      });
    } catch (e) {
      print('Ошибка загрузки КП: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Фильтрация по поисковому запросу
  List<Quote> get _filteredQuotes {
    if (_searchQuery.isEmpty) return _quotes;
    
    final query = _searchQuery.toLowerCase();
    return _quotes.where((quote) {
      return quote.clientName.toLowerCase().contains(query) ||
          quote.address.toLowerCase().contains(query) ||
          quote.phone.toLowerCase().contains(query);
    }).toList();
  }

  // Удаление КП
  Future<void> _deleteQuote(Quote quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить КП?'),
        content: const Text('Вы уверены, что хотите удалить это коммерческое предложение?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteProposal(quote.id!);
      await _loadQuotes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('КП удалено'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Переход к редактированию КП
  void _editQuote(Quote quote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteEditScreen(quoteToEdit: quote),
      ),
    ).then((_) => _loadQuotes());
  }

  // Переход к деталям КП
  void _viewQuote(Quote quote) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProposalDetailScreen(quote: quote.toMap()),
      ),
    ).then((_) => _loadQuotes());
  }

  // Виджет пустого состояния
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'Нет коммерческих предложений',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Создайте первое КП для вашего клиента',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuoteEditScreen(),
                ),
              ).then((_) => _loadQuotes());
            },
            icon: const Icon(Icons.add),
            label: const Text('Создать КП'),
          ),
        ],
      ),
    );
  }

  // Расчет общей суммы всех КП
  double _calculateTotalSum() {
    return _quotes.fold(0.0, (sum, quote) => sum + (quote.totalAmount));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Коммерческие предложения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotes,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Поиск по клиентам, адресам...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          
          // Статистика
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  backgroundColor: Colors.blue.shade50,
                  label: Text(
                    'Всего: ${_quotes.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  backgroundColor: Colors.green.shade50,
                  label: Text(
                    'Сумма: ${_calculateTotalSum().toStringAsFixed(2)} ₽',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Список КП
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQuotes.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadQuotes,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _filteredQuotes.length,
                          itemBuilder: (context, index) {
                            final quote = _filteredQuotes[index];
                            return QuoteListTile(
                              quote: quote,
                              onTap: () => _viewQuote(quote),
                              onEdit: () => _editQuote(quote),
                              onDelete: () => _deleteQuote(quote),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QuoteEditScreen(),
            ),
          ).then((_) => _loadQuotes());
        },
        child: const Icon(Icons.add),
        tooltip: 'Создать новое КП',
      ),
    );
  }
}
