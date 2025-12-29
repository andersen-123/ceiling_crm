import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../data/database_helper.dart';
import '../models/quote.dart';
import '../services/pdf_service.dart';
import 'quote_edit_screen.dart';
import 'settings_screen.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({Key? key}) : super(key: key);

  @override
  _QuoteListScreenState createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PdfService _pdfService = PdfService();
  List<Quote> _quotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() => _isLoading = true);
    try {
      final quotes = await _dbHelper.getAllQuotes();
      setState(() {
        _quotes = quotes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Ошибка загрузки: $e', isError: true);
    }
  }

  Future<void> _deleteQuote(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text('Удалить это коммерческое предложение?'),
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

    if (confirm == true) {
      try {
        await _dbHelper.deleteQuote(id);
        _showSnackBar('КП удалено');
        _loadQuotes();
      } catch (e) {
        _showSnackBar('Ошибка удаления: $e', isError: true);
      }
    }
  }

  Future<void> _exportQuoteAsPdf(Quote quote) async {
    try {
      final company = await _dbHelper.getCompanyProfile();
      final pdfBytes = await _pdfService.generateQuotePdf(quote, company);

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
      );

      _showSnackBar('PDF создан успешно');
    } catch (e) {
      _showSnackBar('Ошибка генерации PDF: $e', isError: true);
    }
  }

  Future<void> _shareQuote(Quote quote) async {
    try {
      final company = await _dbHelper.getCompanyProfile();
      final pdfBytes = await _pdfService.generateQuotePdf(quote, company);
      final file = await _pdfService.savePdfToFile(pdfBytes, 'quote_${quote.id}.pdf');

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Коммерческое предложение для ${quote.clientName}',
      );
    } catch (e) {
      _showSnackBar('Ошибка подготовки КП для шаринга: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Коммерческие предложения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quotes.isEmpty
              ? _buildEmptyState()
              : _buildQuoteList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QuoteEditScreen(),
            ),
          );
          _loadQuotes();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Нет коммерческих предложений',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Нажмите + чтобы создать первое КП',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteList() {
    return RefreshIndicator(
      onRefresh: _loadQuotes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _quotes.length,
        itemBuilder: (context, index) {
          final quote = _quotes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                quote.clientName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (quote.projectName.isNotEmpty)
                    Text(
                      quote.projectName,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: quote.status == 'отправлено'
                              ? Colors.green[100]
                              : quote.status == 'черновик'
                                  ? Colors.orange[100]
                                  : Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          quote.status,
                          style: TextStyle(
                            fontSize: 12,
                            color: quote.status == 'отправлено'
                                ? Colors.green[800]
                                : quote.status == 'черновик'
                                    ? Colors.orange[800]
                                    : Colors.blue[800],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${NumberFormat.currency(locale: 'ru', symbol: '₽', decimalDigits: 0).format(quote.totalAmount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuoteEditScreen(quote: quote),
                      ),
                    ).then((_) => _loadQuotes());
                  } else if (value == 'pdf') {
                    _exportQuoteAsPdf(quote);
                  } else if (value == 'share') {
                    _shareQuote(quote);
                  } else if (value == 'delete') {
                    if (quote.id != null) _deleteQuote(quote.id!);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                  const PopupMenuItem(value: 'pdf', child: Text('Экспорт в PDF')),
                  const PopupMenuItem(value: 'share', child: Text('Поделиться')),
                  const PopupMenuItem(value: 'delete', child: Text('Удалить')),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuoteEditScreen(quote: quote),
                  ),
                ).then((_) => _loadQuotes());
              },
            ),
          );
        },
      ),
    );
  }
}
