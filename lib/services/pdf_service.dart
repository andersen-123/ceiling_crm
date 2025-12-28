import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../services/database_helper.dart';

class PdfService {
  static Future<void> generateAndShareQuote({
    required Quote quote,
    required List<LineItem> lineItems,
    required BuildContext context,
  }) async {
    try {
      // 1. Получаем профиль компании
      final dbHelper = DatabaseHelper.instance;
      final companyProfile = await dbHelper.getCompanyProfile();
      
      // 2. Генерируем PDF
      final pdf = await _generatePdfDocument(quote, lineItems, companyProfile);
      
      // 3. Сохраняем во временный файл
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/quote_${quote.id}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // 4. Предпросмотр
      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
      );
      
      // 5. Шаринг
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path)],
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
      
    } catch (e) {
      print('Ошибка генерации PDF: $e');
      rethrow;
    }
  }
  
  static Future<pw.Document> _generatePdfDocument(
    Quote quote,
    List<LineItem> items,
    dynamic companyProfile,
  ) async {
    final pdf = pw.Document();
    
    // Заголовок
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Заголовок КП
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Коммерческое предложение №${quote.id}',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Информация о компании
              if (companyProfile != null) 
                _buildCompanyInfo(companyProfile),
              
              pw.SizedBox(height: 20),
              
              // Информация о клиенте
              _buildClientInfo(quote),
              
              pw.SizedBox(height: 30),
              
              // Таблица позиций
              _buildItemsTable(items),
              
              pw.SizedBox(height: 30),
              
              // Итоги
              _buildTotals(quote, items),
            ],
          );
        },
      ),
    );
    
    return pdf;
  }
  
  static pw.Widget _buildCompanyInfo(dynamic profile) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          profile.companyName ?? 'PotolokForLife',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (profile.phone != null) pw.Text('Тел: ${profile.phone}'),
        if (profile.email != null) pw.Text('Email: ${profile.email}'),
        if (profile.address != null) pw.Text('Адрес: ${profile.address}'),
      ],
    );
  }
  
  static pw.Widget _buildClientInfo(Quote quote) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Клиент:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text('Имя: ${quote.clientName}'),
        if (quote.clientPhone != null && quote.clientPhone!.isNotEmpty)
          pw.Text('Телефон: ${quote.clientPhone}'),
        if (quote.objectAddress != null && quote.objectAddress!.isNotEmpty)
          pw.Text('Адрес объекта: ${quote.objectAddress}'),
        pw.Text('Дата: ${_formatDate(quote.createdAt)}'),
        pw.Text('Статус: ${_getStatusText(quote.status)}'),
      ],
    );
  }
  
  static pw.Widget _buildItemsTable(List<LineItem> items) {
    final headers = ['№', 'Наименование', 'Ед.', 'Кол-во', 'Цена', 'Сумма'];
    
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FixedColumnWidth(40),
        3: const pw.FixedColumnWidth(60),
        4: const pw.FixedColumnWidth(70),
        5: const pw.FixedColumnWidth(80),
      },
      children: [
        // Заголовки
        pw.TableRow(
          children: headers.map((header) => 
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                header,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            )
          ).toList(),
        ),
        
        // Данные
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final total = item.price * item.quantity;
          
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('${index + 1}'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(item.name),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(item.unit),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(item.quantity.toStringAsFixed(2)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('${item.price.toStringAsFixed(2)} ₽'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('${total.toStringAsFixed(2)} ₽'),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
  
  static pw.Widget _buildTotals(Quote quote, List<LineItem> items) {
    final subtotal = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    final vatRate = quote.vatRate ?? 0.0;
    final vatAmount = subtotal * (vatRate / 100);
    final total = subtotal + vatAmount;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('Сумма: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('${subtotal.toStringAsFixed(2)} ₽'),
          ],
        ),
        if (vatRate > 0) pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('НДС ${vatRate}%: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('${vatAmount.toStringAsFixed(2)} ₽'),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('ИТОГО: ', style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            )),
            pw.Text('${total.toStringAsFixed(2)} ₽', style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            )),
          ],
        ),
      ],
    );
  }
  
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
  
  static String _getStatusText(String status) {
    switch (status) {
      case 'accepted': return 'Принят';
      case 'rejected': return 'Отклонен';
      case 'pending': return 'На рассмотрении';
      default: return 'Черновик';
    }
  }
}
