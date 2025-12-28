import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ceiling_crm/screens/quote_edit_screen.dart';
import 'package:ceiling_crm/screens/settings_screen.dart';
import 'package:ceiling_crm/services/database_helper.dart';
import 'package:ceiling_crm/services/pdf_service.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class QuoteListScreen extends StatefulWidget {
  @override
  _QuoteListScreenState createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  List<Map<String, dynamic>> quotes = [];
  bool _isLoading = true;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    try {
      final loadedQuotes = await _dbHelper.getAllQuotes();
      setState(() {
        quotes = loadedQuotes;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки КП: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteQuote(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить КП?'),
        content: Text('Вы уверены, что хотите удалить это коммерческое предложение?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Удалить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteQuote(id);
      await _loadQuotes();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('КП удалено'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _createNewQuote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteEditScreen(),
      ),
    );

    if (result == true) {
      await _loadQuotes();
    }
  }

  Future<void> _editQuote(Map<String, dynamic> quote) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuoteEditScreen(quote: quote),
      ),
    );

    if (result == true) {
      await _loadQuotes();
    }
  }

  void _showPdfOptions(BuildContext context, Map<String, dynamic> quote) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.preview, color: Colors.blue),
                title: Text('Предпросмотр PDF'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/pdf_preview',
                    arguments: quote,
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: Colors.green),
                title: Text('Поделиться PDF'),
                onTap: () async {
                  Navigator.pop(context);
                  await _sharePdf(quote);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Удалить КП'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteQuote(quote['id']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sharePdf(Map<String, dynamic> quote) async {
    try {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Генерируем PDF
      final pdfBytes = await PdfService.generateQuotePdf(quote);
      
      // Сохраняем временный файл
      final tempDir = await getTemporaryDirectory();
      final fileName = 'КП_${quote['id']}_${quote['client_name'] ?? 'Без_названия'}.pdf'
          .replaceAll(RegExp(r'[^\w\d]'), '_');
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Закрываем индикатор загрузки
      Navigator.pop(context);

      // Открываем диалог шаринга
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Коммерческое предложение №${quote['id']} для ${quote['client_name']}',
        subject: 'КП №${quote['id']}',
      );

      // Удаляем временный файл через 30 секунд
      Future.delayed(Duration(seconds: 30), () async {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Ошибка удаления временного файла: $e');
        }
      });

    } catch (e) {
      // Закрываем индикатор загрузки если есть ошибка
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при создании или отправке PDF: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Коммерческие предложения'),
        backgroundColor: Colors.blueGrey[800],
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                ),
              );
            },
            tooltip: 'Настройки компании',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : quotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Нет коммерческих предложений',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Нажмите "+" чтобы создать первое КП',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadQuotes,
                  child: ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: quotes.length,
                    itemBuilder: (context, index) {
                      final quote = quotes[index];
                      final dateFormat = DateFormat('dd.MM.yyyy');
                      final createdDate = quote['created_at'] != null
                          ? DateTime.parse(quote['created_at'])
                          : DateTime.now();
                      
                      double total = 0;
                      final positions = List<Map<String, dynamic>>.from(
                          quote['positions'] ?? []);
                      for (var position in positions) {
                        total += (position['price'] ?? 0) * (position['quantity'] ?? 1);
                      }

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        elevation: 2,
                        child: InkWell(
                          onTap: () => _editQuote(quote),
                          onLongPress: () => _showPdfOptions(context, quote),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'КП №${quote['id']}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey[800],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        quote['client_name'] ?? 'Без названия',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        quote['object_address'] ?? 'Адрес не указан',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        dateFormat.format(createdDate),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${NumberFormat.currency(locale: 'ru_RU', symbol: '₽').format(total)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${positions.length} поз.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blueGrey[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewQuote,
        child: Icon(Icons.add),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        tooltip: 'Создать новое КП',
      ),
    );
  }
}
