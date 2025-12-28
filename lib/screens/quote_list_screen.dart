import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ceiling_crm/screens/quote_edit_screen.dart';
import 'package:ceiling_crm/screens/settings_screen.dart';
import 'package:ceiling_crm/screens/pdf_preview_screen.dart';
import 'package:ceiling_crm/screens/debug_screen.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/repositories/quote_repository.dart';
import 'package:ceiling_crm/services/pdf_service.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class QuoteListScreen extends StatefulWidget {
  @override
  _QuoteListScreenState createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  final QuoteRepository _quoteRepo = QuoteRepository();
  List<Quote> _quotes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _statusFilter;

  // Статусы для фильтрации
  final Map<String, String> _statusLabels = {
    'draft': 'Черновик',
    'sent': 'Отправлен',
    'accepted': 'Принят',
    'rejected': 'Отклонен',
  };

  final Map<String, Color> _statusColors = {
    'draft': Colors.grey,
    'sent': Colors.blue,
    'accepted': Colors.green,
    'rejected': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<Quote> quotes;
      
      if (_statusFilter != null) {
        quotes = await _quoteRepo.getQuotesByStatus(_statusFilter!);
      } else if (_searchQuery.isNotEmpty) {
        quotes = await _quoteRepo.searchQuotes(_searchQuery);
      } else {
        quotes = await _quoteRepo.getAllQuotes();
      }

      setState(() {
        _quotes = quotes;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки КП: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки данных: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteQuote(Quote quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить КП?'),
        content: Text('Вы уверены, что хотите удалить КП №${quote.id} для "${quote.clientName}"?'),
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
      try {
        await _quoteRepo.deleteQuote(quote.id!);
        await _loadQuotes();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('КП №${quote.id} удалено'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Future<void> _editQuote(Quote quote) async {
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

  void _showPdfOptions(BuildContext context, Quote quote) {
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
                onTap: () async {
                  Navigator.pop(context);
                  await _previewPdf(quote);
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
              if (quote.status == 'draft')
                ListTile(
                  leading: Icon(Icons.send, color: Colors.orange),
                  title: Text('Отметить как отправленный'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateQuoteStatus(quote, 'sent');
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Удалить КП'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteQuote(quote);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _previewPdf(Quote quote) async {
    try {
      // Получаем полные данные КП
      final quoteSummary = await _quoteRepo.getQuoteSummary(quote.id!);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            quote: quoteSummary['quote'] as Quote,
            lineItems: (quoteSummary['line_items'] as List).cast<LineItem>(),
            subtotal: quoteSummary['subtotal'] as double,
            vatAmount: quoteSummary['vat_amount'] as double,
            total: quoteSummary['total'] as double,
          ),
        ),
      );
    } catch (e) {
      print('Ошибка предпросмотра PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка создания PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sharePdf(Quote quote) async {
    try {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Получаем данные для PDF
      final quoteSummary = await _quoteRepo.getQuoteSummary(quote.id!);
      final quoteData = quoteSummary['quote'] as Quote;
      final lineItems = (quoteSummary['line_items'] as List).cast<LineItem>();
      
      // Создаем Map для совместимости со старой версией PdfService
      final quoteMap = {
        'id': quoteData.id,
        'client_name': quoteData.clientName,
        'client_phone': quoteData.clientPhone,
        'object_address': quoteData.objectAddress,
        'notes': quoteData.notes,
        'status': quoteData.status,
        'created_at': quoteData.createdAt.toIso8601String(),
        'updated_at': quoteData.updatedAt?.toIso8601String(),
        'total': quoteData.total,
        'vat_rate': quoteData.vatRate,
        'positions': lineItems.map((item) => item.toMap()).toList(),
      };

      // Генерируем PDF
      final pdfBytes = await PdfService.generateQuotePdf(quoteMap);
      
      // Сохраняем временный файл
      final tempDir = await getTemporaryDirectory();
      final fileName = 'КП_${quote.id}_${quote.clientName}.pdf'
          .replaceAll(RegExp(r'[^\w\d]'), '_');
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Закрываем индикатор загрузки
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Открываем диалог шаринга
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Коммерческое предложение №${quote.id} для ${quote.clientName}',
        subject: 'КП №${quote.id}',
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

  Future<void> _updateQuoteStatus(Quote quote, String newStatus) async {
    try {
      await _quoteRepo.updateQuoteStatus(quote.id!, newStatus);
      await _loadQuotes();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Статус КП обновлен на "${_statusLabels[newStatus]}"'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка обновления статуса: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildQuoteCard(Quote quote, int index) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final statusLabel = _statusLabels[quote.status] ?? 'Черновик';
    final statusColor = _statusColors[quote.status] ?? Colors.grey;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _editQuote(quote),
        onLongPress: () => _showPdfOptions(context, quote),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок и статус
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'КП №${quote.id}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Клиент
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      quote.clientName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 4),
              
              // Адрес
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      quote.objectAddress,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 4),
              
              // Дата и сумма
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        dateFormat.format(quote.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    NumberFormat.currency(locale: 'ru_RU', symbol: '₽').format(quote.total),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              
              if (quote.notes != null && quote.notes!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '📝 ${quote.notes!}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
          SizedBox(height: 20),
          if (_statusFilter != null || _searchQuery.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _statusFilter = null;
                  _searchQuery = '';
                });
                _loadQuotes();
              },
              child: Text('Сбросить фильтры'),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Поиск по клиенту, адресу...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                    _loadQuotes();
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          // Дебаунс поиска
          Future.delayed(Duration(milliseconds: 300), () {
            if (_searchQuery == value) {
              _loadQuotes();
            }
          });
        },
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Кнопка "Все"
          FilterChip(
            label: Text('Все'),
            selected: _statusFilter == null,
            onSelected: (selected) {
              setState(() {
                _statusFilter = null;
              });
              _loadQuotes();
            },
            backgroundColor: Colors.grey[100],
            selectedColor: Colors.blueGrey[100],
          ),
          SizedBox(width: 8),
          
          // Фильтры по статусам
          ..._statusLabels.entries.map((entry) {
            final status = entry.key;
            final label = entry.value;
            final isSelected = _statusFilter == status;
            
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _statusFilter = selected ? status : null;
                  });
                  _loadQuotes();
                },
                backgroundColor: Colors.grey[100],
                selectedColor: _statusColors[status]?.withOpacity(0.2) ?? Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected 
                      ? _statusColors[status] ?? Colors.black 
                      : Colors.grey[700],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Коммерческие предложения'),
        backgroundColor: Colors.blueGrey[800],
        elevation: 2,
        actions: [
          GestureDetector(
            onLongPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DebugScreen(),
                ),
              );
            },
            child: IconButton(
              icon: Icon(Icons.bug_report),
              onPressed: () {
                // Обычное нажатие ничего не делает
              },
              tooltip: 'Удерживайте 3 секунды для отладки',
            ),
          ),
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
      body: Column(
        children: [
          // Поиск
          _buildSearchBar(),
          
          // Фильтры по статусу
          _buildStatusFilter(),
          
          SizedBox(height: 8),
          
          // Информация о количестве
          if (!_isLoading && _quotes.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Найдено: ${_quotes.length}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _loadQuotes,
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text('Обновить'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ),
          
          // Список КП
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _quotes.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadQuotes,
                        child: ListView.builder(
                          padding: EdgeInsets.all(8),
                          itemCount: _quotes.length,
                          itemBuilder: (context, index) {
                            return _buildQuoteCard(_quotes[index], index);
                          },
                        ),
                      ),
          ),
        ],
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
