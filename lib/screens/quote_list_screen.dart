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
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PdfService _pdfService = PdfService();
  List<Quote> _quotes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quotes = await _dbHelper.getAllQuotes();
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

  List<Quote> get _filteredQuotes {
    if (_searchQuery.isEmpty) return _quotes;
    
    final query = _searchQuery.toLowerCase();
    return _quotes.where((quote) {
      return quote.clientName.toLowerCase().contains(query) ||
          quote.clientAddress.toLowerCase().contains(query) ||
          quote.clientPhone.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _deleteQuote(int quoteId) async {
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
      await _dbHelper.deleteQuote(quoteId);
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

  Future<void> _duplicateQuote(Quote quote) async {
    try {
      final newQuote = quote.copyWith(
        id: 0,
        clientName: '${quote.clientName} (копия)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _dbHelper.insertQuote(newQuote);
      await _loadQuotes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('КП дублировано'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Ошибка дублирования: $e');
    }
  }

  void _showContextMenu(BuildContext context, Quote quote) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Редактировать КП'),
              onTap: () {
                Navigator.of(context).pop(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy, color: Colors.orange),
              title: const Text('Дублировать КП'),
              onTap: () {
                Navigator.of(context).pop(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.green),
              title: const Text('Создать PDF'),
              onTap: () {
                Navigator.of(context).pop(3);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить КП'),
              onTap: () {
                Navigator.of(context).pop(4);
              },
            ),
          ],
        ),
      ),
    );

    if (result == 1) {
      // Редактировать КП
      final updated = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => QuoteEditScreen(quoteId: quote.id),
        ),
      );
      
      if (updated == true) {
        await _loadQuotes();
      }
    } else if (result == 2) {
      // Дублировать КП
      await _duplicateQuote(quote);
    } else if (result == 3) {
      // Создать PDF
      _generatePdfForQuote(quote);
    } else if (result == 4) {
      // Удалить КП
      await _deleteQuote(quote.id);
    }
  }

  // Обновите метод:
  void _generatePdfForQuote(Quote quote) async {
    try {
      await _pdfService.previewPdf(context, quote);
    } catch (e) {
      print('Ошибка генерации PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка генерации PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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

  double _calculateTotalSum() {
    return _quotes.fold(0.0, (sum, quote) => sum + quote.totalAmount);
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
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProposalDetailScreen(quote: quote),
                                  ),
                                ).then((_) => _loadQuotes());
                              },
                              onLongPress: () => _showContextMenu(context, quote),
                              child: QuoteListTile(quote: quote),
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
