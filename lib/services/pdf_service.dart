import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company_profile.dart';
import '../services/database_helper.dart';

class PdfService {
  // Основной метод для генерации и шаринга PDF
  static Future<void> generateAndShareQuote({
    required Quote quote,
    required List<LineItem> lineItems,
    required BuildContext context,
  }) async {
    try {
      print('🔧 Начинаем генерацию PDF для КП #${quote.id}');
    
      // 1. Получаем профиль компании
      final dbHelper = DatabaseHelper.instance;
      final companyProfile = await dbHelper.getCompanyProfile();
      print('✅ Профиль компании загружен');
    
      // 2. Генерируем PDF документ
      final pdf = await _generatePdfDocument(quote, lineItems, companyProfile);
      print('✅ PDF документ сгенерирован');
    
      // 3. Сохраняем во временный файл
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/КП_${quote.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      print('✅ PDF сохранен: ${file.path}');
    
      // 4. Предпросмотр PDF
      print('📄 Открываем предпросмотр PDF...');
      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
      );
      print('✅ Предпросмотр открыт');
    
      // 5. Шаринг файла - ТОЛЬКО ОДИН АРГУМЕНТ
      print('📤 Открываем диалог шаринга...');
      await Share.shareXFiles([XFile(file.path)]);
      print('✅ Шаринг запущен');
    
    } catch (e) {
      print('❌ Ошибка генерации PDF: $e');
      rethrow;
    }
  }
  
  // Генерация PDF документа
  static Future<pw.Document> _generatePdfDocument(
    Quote quote,
    List<LineItem> items,
    CompanyProfile? companyProfile,
  ) async {
    final pdf = pw.Document();
    
    // Загружаем шрифт (если нужно)
    // final font = await PdfGoogleFonts.robotoRegular();
    
    // Создаем стили
    final headerStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blue800,
    );
    
    final subtitleStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    );
    
    final normalStyle = pw.TextStyle(
      fontSize: 12,
    );
    
    final smallStyle = pw.TextStyle(
      fontSize: 10,
    );
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            // Шапка документа
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Заголовок
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'КОММЕРЧЕСКОЕ ПРЕДЛОЖЕНИЕ',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '№ ${quote.id}',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      'Дата: ${_formatDate(quote.createdAt)}',
                      style: normalStyle,
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 20),
                
                // Информация о компании
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyProfile?.companyName ?? 'PotolokForLife',
                        style: subtitleStyle,
                      ),
                      if (companyProfile?.phone != null) 
                        pw.Text('Телефон: ${companyProfile!.phone}', style: smallStyle),
                      if (companyProfile?.email != null) 
                        pw.Text('Email: ${companyProfile!.email}', style: smallStyle),
                      if (companyProfile?.address != null) 
                        pw.Text('Адрес: ${companyProfile!.address}', style: smallStyle),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Информация о клиенте
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Клиент:', style: subtitleStyle),
                      pw.Text('${quote.clientName}', style: normalStyle),
                      if (quote.clientPhone != null && quote.clientPhone!.isNotEmpty)
                        pw.Text('Телефон: ${quote.clientPhone}', style: smallStyle),
                      if (quote.objectAddress != null && quote.objectAddress!.isNotEmpty)
                        pw.Text('Адрес объекта: ${quote.objectAddress}', style: smallStyle),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Таблица позиций
                pw.Text('СПИСОК ПОЗИЦИЙ:', style: subtitleStyle),
                pw.SizedBox(height: 10),
                
                _buildItemsTable(items, normalStyle, smallStyle),
                
                pw.SizedBox(height: 30),
                
                // Итоги
                _buildTotalsSection(quote, items, subtitleStyle, normalStyle),
                
                pw.SizedBox(height: 40),
                
                // Подписи
                _buildSignatureSection(companyProfile, normalStyle),
                
                pw.SizedBox(height: 20),
                
                // Примечание
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey200),
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text(
                    'Данное коммерческое предложение действительно в течение 30 дней с даты составления. '
                    'Цены указаны в рублях и включают НДС, если не указано иное.',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey600,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );
    
    return pdf;
  }
  
  // Строим таблицу позиций
  static pw.Widget _buildItemsTable(List<LineItem> items, pw.TextStyle normalStyle, pw.TextStyle smallStyle) {
    if (items.isEmpty) {
      return pw.Text('Позиции не добавлены', style: normalStyle);
    }
    
    return pw.TableHelper.fromTextArray(
      context: null,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
      cellStyle: smallStyle,
      headerDecoration: pw.BoxDecoration(color: PdfColors.grey100),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),  // №
        1: const pw.FlexColumnWidth(3),    // Наименование
        2: const pw.FixedColumnWidth(50),  // Ед.
        3: const pw.FixedColumnWidth(60),  // Кол-во
        4: const pw.FixedColumnWidth(70),  // Цена
        5: const pw.FixedColumnWidth(80),  // Сумма
      },
      headers: ['№', 'Наименование', 'Ед.', 'Кол-во', 'Цена, ₽', 'Сумма, ₽'],
      data: List<List<String>>.generate(items.length, (index) {
        final item = items[index];
        final total = item.price * item.quantity;
        
        return [
          (index + 1).toString(),
          item.name,
          item.unit,
          item.quantity.toStringAsFixed(2),
          item.price.toStringAsFixed(2),
          total.toStringAsFixed(2),
        ];
      }),
    );
  }
  
  // Секция итогов
  static pw.Widget _buildTotalsSection(Quote quote, List<LineItem> items, pw.TextStyle subtitleStyle, pw.TextStyle normalStyle) {
    final subtotal = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    final vatRate = quote.vatRate ?? 0.0;
    final vatAmount = subtotal * (vatRate / 100);
    final total = subtotal + vatAmount;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Сумма:', style: normalStyle),
              pw.Text('${subtotal.toStringAsFixed(2)} ₽', style: normalStyle),
            ],
          ),
          
          if (vatRate > 0) pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('НДС ${vatRate.toStringAsFixed(1)}%:', style: normalStyle),
              pw.Text('${vatAmount.toStringAsFixed(2)} ₽', style: normalStyle),
            ],
          ),
          
          pw.Divider(),
          
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('ИТОГО:', style: subtitleStyle.copyWith(fontSize: 16)),
              pw.Text(
                '${total.toStringAsFixed(2)} ₽',
                style: subtitleStyle.copyWith(
                  fontSize: 16,
                  color: PdfColors.green700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Секция подписей
  static pw.Widget _buildSignatureSection(CompanyProfile? companyProfile, pw.TextStyle normalStyle) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Подпись исполнителя
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Исполнитель:', style: normalStyle),
            pw.SizedBox(height: 30),
            pw.Text('_________________________', style: normalStyle),
            pw.Text(companyProfile?.managerName ?? 'Менеджер', style: normalStyle),
            if (companyProfile?.position != null)
              pw.Text(companyProfile!.position, style: normalStyle.copyWith(fontSize: 10)),
          ],
        ),
        
        // Подпись клиента
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Клиент:', style: normalStyle),
            pw.SizedBox(height: 30),
            pw.Text('_________________________', style: normalStyle),
            pw.Text('', style: normalStyle),
          ],
        ),
      ],
    );
  }
  
  // Форматирование даты
  static String _formatDate(DateTime date) {
    final formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(date);
  }
  
  // Вспомогательный метод для форматирования валюты
  static String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}
