import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../services/database_helper.dart';
import '../services/pdf_service.dart';
import '../models/line_item.dart';
import '../models/company_profile.dart';

class QuoteDetailScreen extends StatefulWidget {
  final Quote quote;
  
  const QuoteDetailScreen({Key? key, required this.quote}) : super(key: key);
  
  @override
  _QuoteDetailScreenState createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  late Quote _quote;
  List<LineItem> _items = [];
  CompanyProfile? _companyProfile;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  @override
  void initState() {
    super.initState();
    _quote = widget.quote;
    _loadData();
  }
  
  Future<void> _loadData() async {
    // Загружаем позиции
    final items = await _dbHelper.getLineItemsByQuoteId(_quote.id!);
    
    // Загружаем профиль компании
    final company = await _dbHelper.getCompanyProfile();
    
    setState(() {
      _items = items;
      _companyProfile = company;
    });
  }
  
  Future<void> _updateQuoteStatus(String status, {String? comment}) async {
    final updatedQuote = Quote(
      id: _quote.id,
      title: _quote.title,
      clientName: _quote.clientName,
      clientPhone: _quote.clientPhone,
      clientEmail: _quote.clientEmail,
      clientAddress: _quote.clientAddress,
      createdAt: _quote.createdAt,
      validUntil: _quote.validUntil,
      notes: _quote.notes,
      totalPrice: _quote.totalPrice,
      status: status,
      statusChangedAt: DateTime.now(),
      statusComment: comment,
    );
    
    await _dbHelper.updateQuote(updatedQuote);
    
    setState(() {
      _quote = updatedQuote;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Статус обновлен на "${_quote.statusDisplay}"')),
    );
  }
  
  Future<void> _showStatusDialog() async {
    String? comment;
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Изменить статус КП'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Кнопки статусов
              _buildStatusButton('Принять', 'accepted', Colors.green, Icons.check),
              SizedBox(height: 8),
              _buildStatusButton('Отклонить', 'rejected', Colors.red, Icons.close),
              SizedBox(height: 8),
              _buildStatusButton('Отправить', 'sent', Colors.blue, Icons.send),
              SizedBox(height: 16),
              
              // Поле для комментария
              TextField(
                decoration: InputDecoration(
                  labelText: 'Комментарий (необязательно)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => comment = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildStatusButton(String text, String status, Color color, IconData icon) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        _updateQuoteStatus(status, comment: '');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: Size(double.infinity, 48),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
  
  Future<void> _generateAndPreviewPdf() async {
    if (_companyProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Загрузите данные компании в настройках')),
      );
      return;
    }
    
    try {
      final pdfBytes = await PdfService.generateQuotePdf(_quote, _items, _companyProfile!);
      await PdfService.previewPdf(pdfBytes, context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка генерации PDF: $e')),
      );
    }
  }
  
  Future<void> _sharePdf() async {
    if (_companyProfile == null) return;
    
    try {
      final pdfBytes = await PdfService.generateQuotePdf(_quote, _items, _companyProfile!);
      final fileName = 'КП_${_quote.id}_${_quote.clientName}';
      await PdfService.sharePdf(pdfBytes, fileName, context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('КП: ${_quote.title}'),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _generateAndPreviewPdf,
            tooltip: 'Предпросмотр PDF',
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _sharePdf,
            tooltip: 'Поделиться PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Блок статуса
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Статус:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Chip(
                          label: Text(
                            _quote.statusDisplay,
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: _quote.statusColor,
                        ),
                      ],
                    ),
                    
                    if (_quote.statusChangedAt != null)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Изменен: ${_quote.statusChangedAt!.day.toString().padLeft(2, '0')}.${_quote.statusChangedAt!.month.toString().padLeft(2, '0')}.${_quote.statusChangedAt!.year}',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    
                    if (_quote.statusComment != null && _quote.statusComment!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Комментарий: ${_quote.statusComment!}',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    
                    SizedBox(height: 16),
                    
                    ElevatedButton(
                      onPressed: _showStatusDialog,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                      ),
                      child: Text('Изменить статус'),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Информация о клиенте
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Информация о клиенте',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow('Клиент:', _quote.clientName),
                    if (_quote.clientPhone != null && _quote.clientPhone!.isNotEmpty)
                      _buildInfoRow('Телефон:', _quote.clientPhone!),
                    if (_quote.clientEmail != null && _quote.clientEmail!.isNotEmpty)
                      _buildInfoRow('Email:', _quote.clientEmail!),
                    if (_quote.clientAddress != null && _quote.clientAddress!.isNotEmpty)
                      _buildInfoRow('Адрес:', _quote.clientAddress!),
                    _buildInfoRow(
                      'Дата создания:',
                      '${_quote.createdAt.day.toString().padLeft(2, '0')}.${_quote.createdAt.month.toString().padLeft(2, '0')}.${_quote.createdAt.year}',
                    ),
                    if (_quote.validUntil != null)
                      _buildInfoRow(
                        'Действует до:',
                        '${_quote.validUntil!.day.toString().padLeft(2, '0')}.${_quote.validUntil!.month.toString().padLeft(2, '0')}.${_quote.validUntil!.year}',
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Позиции
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Позиции (${_items.length})',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    ..._items.map((item) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.description),
                        subtitle: Text('${item.quantity} × ${item.unitPrice.toStringAsFixed(2)} ₽'),
                        trailing: Text(
                          '${item.totalPrice.toStringAsFixed(2)} ₽',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )),
                    Divider(),
                    ListTile(
                      title: Text(
                        'ИТОГО:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        '${_quote.totalPrice.toStringAsFixed(2)} ₽',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_quote.notes.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Примечания',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(_quote.notes),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
