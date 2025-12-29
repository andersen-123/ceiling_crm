import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ceiling_crm/screens/quote_edit_screen.dart';
import 'package:ceiling_crm/screens/quick_add_screen.dart';
import 'package:ceiling_crm/screens/settings_screen.dart';
import 'package:ceiling_crm/data/database_helper.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/services/pdf_service.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({super.key});

  @override
  State<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  List<Quote> _quotes = [];
  bool _isLoading = true;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final PdfService _pdfService = PdfService();

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
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки КП: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final quoteDate = DateTime(date.year, date.month, date.day);

    if (quoteDate == today) {
      return 'Сегодня';
    } else if (quoteDate == yesterday) {
      return 'Вчера';
    } else {
      return DateFormat('dd.MM.yyyy').format(date);
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 2,
    ).format(amount);
  }

  String _formatItemCount(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return '$count позиция';
    } else if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return '$count позиции';
    } else {
      return '$count позиций';
    }
  }

  Future<void> _createTestData() async {
    try {
      print('🔄 Запускаю создание тестовых данных...');
    
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Создаю тестовые данные...'),
          duration: Duration(seconds: 2),
        ),
      );

      await _dbHelper.createTestData();
    
      print('✅ Тестовые данные созданы, обновляю список...');
    
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Тестовые данные успешно созданы!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Обновляем список
      await _loadQuotes();
    
      print('🎉 Процесс завершен успешно!');

    } catch (e) {
      print('❌ Ошибка в _createTestData: $e');
    
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _exportQuoteAsPdf(Quote quote) async {
    try {
      final lineItems = await _dbHelper.getLineItemsForQuote(quote.id!);
      final companyProfile = await _dbHelper.getCompanyProfile();
      if (companyProfile != null) {
        final pdfFile = await _pdfService.generateQuotePdf(
          quote: quote,
          items: lineItems,
          companyProfile: companyProfile,
        );
      
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка генерации PDF: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _shareQuote(Quote quote) async {
    try {
      final lineItems = await _dbHelper.getLineItemsForQuote(quote.id!);
      final companyProfile = await _dbHelper.getCompanyProfile();
      if (companyProfile != null) {
        final pdfFile = await _pdfService.generateQuotePdf(
          quote: quote,
          items: lineItems,
          companyProfile: companyProfile,
        );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📤 Функция шаринга будет доступна в следующем обновлении'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка подготовки КП для шаринга: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteQuote(Quote quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить КП?'),
        content: Text('Вы уверены, что хотите удалить КП для "${quote.clientName}"?'),
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
        await _dbHelper.deleteQuote(quote.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ КП удалено'),
            duration: Duration(seconds: 2),
          ),
        );
        await _loadQuotes();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка удаления КП: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildQuoteCard(Quote quote) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuoteEditScreen(quote: quote),
            ),
          ).then((_) => _loadQuotes());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      quote.clientName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: quote.status == 'отправлено' ? Colors.green[100] : 
                            quote.status == 'черновик' ? Colors.orange[100] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      quote.status,
                      style: TextStyle(
                        color: quote.status == 'отправлено' ? Colors.green[800] : 
                              quote.status == 'черновик' ? Colors.orange[800] : Colors.blue[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (quote.projectName.isNotEmpty)
                Text(
                  quote.projectName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(quote.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(quote.totalAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf, size: 20),
                        onPressed: () => _exportQuoteAsPdf(quote),
                        tooltip: 'Экспорт в PDF',
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, size: 20),
                        onPressed: () => _shareQuote(quote),
                        tooltip: 'Поделиться',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                        onPressed: () => _deleteQuote(quote),
                        tooltip: 'Удалить',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧪 Тестирование приложения',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Проверьте основные функции приложения:',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          _buildTestItem('✅ Создание и редактирование КП'),
          _buildTestItem('✅ 22 шаблона позиций'),
          _buildTestItem('✅ PDF генерация и шаринг'),
          _buildTestItem('✅ Настройки компании'),
          _buildTestItem('✅ Локальная база данных'),
          _buildTestItem('✅ Навигация и меню'),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _createTestData,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Создать тестовые данные'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Вернуться к списку КП'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestItem(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ceiling CRM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuoteEditScreen(),
                ),
              ).then((_) => _loadQuotes());
            },
            tooltip: 'Создать новое КП',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotes,
            tooltip: 'Обновить список',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.description, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Нет коммерческих предложений',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Создайте первое КП, нажав на кнопку "+"',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createTestData,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Создать тестовые данные'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadQuotes,
                  child: ListView.builder(
                    itemCount: _quotes.length,
                    itemBuilder: (context, index) {
                      return _buildQuoteCard(_quotes[index]);
                    },
                  ),
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
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Ceiling CRM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Управление коммерческими предложениями',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '📊 Основные',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Главная'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Создать КП'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuoteEditScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Все КП'),
              onTap: () {
                Navigator.pop(context);
                _loadQuotes();
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '⚙️ Настройки',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Компания'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Внешний вид'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Реализовать экран настроек внешнего вида
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Резервное копирование'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Реализовать экран бэкапа
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Тестирование'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: _buildTestScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '❓ Помощь',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Справка'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Реализовать экран справки
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('О приложении'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Реализовать экран "О приложении"
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '📈 Дополнительно',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Статистика'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Реализовать экран статистики
              },
            ),
            ListTile(
              leading: const Icon(Icons.import_export),
              title: const Text('Экспорт данных'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Реализовать экран экспорта
              },
            ),
          ],
        ),
      ),
    );
  }
}
