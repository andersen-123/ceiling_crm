import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quote.dart';
import '../models/company_profile.dart';
import '../models/line_item.dart';

class PdfService {
  // Загружаем шрифт Roboto из assets
  static Future<pw.Font> _loadRobotoFont() async {
    final ByteData fontData = await rootBundle.load('fonts/Roboto-Regular.ttf');
    final Uint8List fontBytes = fontData.buffer.asUint8List();
    return pw.Font.ttf(fontBytes);
  }

  static Future<pw.Font> _loadRobotoBoldFont() async {
    final ByteData fontData = await rootBundle.load('fonts/Roboto-Bold.ttf');
    final Uint8List fontBytes = fontData.buffer.asUint8List();
    return pw.Font.ttf(fontBytes);
  }

  static Future<Uint8List> generateQuotePdf(
    Quote quote, 
    List<LineItem> items, 
    CompanyProfile company
  ) async {
    // Загружаем шрифты
    final robotoFont = await _loadRobotoFont();
    final robotoBoldFont = await _loadRobotoBoldFont();
    
    final pdf = pw.Document();
    
    // Стили для текста
    final headerStyle = pw.TextStyle(
      font: robotoBoldFont,
      fontSize: 16,
      color: PdfColors.black,
    );
    
    final titleStyle = pw.TextStyle(
      font: robotoBoldFont,
      fontSize: 20,
      color: PdfColors.black,
    );
    
    final normalStyle = pw.TextStyle(
      font: robotoFont,
      fontSize: 11,
      color: PdfColors.black,
    );
    
    final smallStyle = pw.TextStyle(
      font: robotoFont,
      fontSize: 10,
      color: PdfColors.grey700,
    );
    
    final tableHeaderStyle = pw.TextStyle(
      font: robotoBoldFont,
      fontSize: 11,
      color: PdfColors.white,
    );
    
    // Форматирование чисел
    String formatCurrency(double value) {
      return '${value.toStringAsFixed(2).replaceAll('.', ',')} ₽';
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Шапка с логотипом и контактами
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        company.companyName,
                        style: titleStyle,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        company.address ?? '',
                        style: normalStyle,
                      ),
                      pw.Text(
                        'Тел: ${company.phone ?? '+7 (999) 123-45-67'}',
                        style: normalStyle,
                      ),
                      pw.Text(
                        'Email: ${company.email ?? 'info@company.ru'}',
                        style: normalStyle,
                      ),
                    ],
                  ),
                  // Здесь можно добавить логотип если есть
                  // pw.Image(pw.MemoryImage(logoBytes), width: 100, height: 50),
                ],
              ),
              
              pw.Divider(height: 20, thickness: 2),
              
              // Заголовок КП и статус
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'КОММЕРЧЕСКОЕ ПРЕДЛОЖЕНИЕ',
                        style: headerStyle,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        '№ ${quote.id?.toString().padLeft(6, '0') ?? 'Новый'}',
                        style: pw.TextStyle(
                          font: robotoBoldFont,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  // Блок статуса
                  pw.Container(
                    padding: pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: _getStatusColor(quote.status),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      quote.statusDisplay.toUpperCase(),
                      style: pw.TextStyle(
                        font: robotoBoldFont,
                        fontSize: 10,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Информация о клиенте
              pw.Container(
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Клиент:',
                      style: pw.TextStyle(
                        font: robotoBoldFont,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Text('Название: ', style: pw.TextStyle(font: robotoBoldFont, fontSize: 11)),
                        pw.Text(quote.clientName, style: normalStyle),
                      ],
                    ),
                    if (quote.clientPhone != null && quote.clientPhone!.isNotEmpty)
                      pw.Row(
                        children: [
                          pw.Text('Телефон: ', style: pw.TextStyle(font: robotoBoldFont, fontSize: 11)),
                          pw.Text(quote.clientPhone!, style: normalStyle),
                        ],
                      ),
                    if (quote.clientEmail != null && quote.clientEmail!.isNotEmpty)
                      pw.Row(
                        children: [
                          pw.Text('Email: ', style: pw.TextStyle(font: robotoBoldFont, fontSize: 11)),
                          pw.Text(quote.clientEmail!, style: normalStyle),
                        ],
                      ),
                    pw.Row(
                      children: [
                        pw.Text('Дата создания: ', style: pw.TextStyle(font: robotoBoldFont, fontSize: 11)),
                        pw.Text(
                          '${quote.createdAt.day.toString().padLeft(2, '0')}.${quote.createdAt.month.toString().padLeft(2, '0')}.${quote.createdAt.year}',
                          style: normalStyle,
                        ),
                      ],
                    ),
                    if (quote.validUntil != null)
                      pw.Row(
                        children: [
                          pw.Text('Действует до: ', style: pw.TextStyle(font: robotoBoldFont, fontSize: 11)),
                          pw.Text(
                            '${quote.validUntil!.day.toString().padLeft(2, '0')}.${quote.validUntil!.month.toString().padLeft(2, '0')}.${quote.validUntil!.year}',
                            style: normalStyle,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Таблица с позициями
              pw.Text(
                'Спецификация:',
                style: pw.TextStyle(
                  font: robotoBoldFont,
                  fontSize: 14,
                ),
              ),
              pw.SizedBox(height: 10),
              
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
                columnWidths: {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1.5),
                  4: pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Заголовок таблицы
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.blue700),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('#', style: tableHeaderStyle, textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Наименование', style: tableHeaderStyle),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Кол-во', style: tableHeaderStyle, textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Цена', style: tableHeaderStyle, textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text('Сумма', style: tableHeaderStyle, textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  
                  // Позиции
                  for (var i = 0; i < items.length; i++)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            (i + 1).toString(),
                            style: normalStyle,
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(items[i].description, style: normalStyle),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            items[i].quantity.toStringAsFixed(2).replaceAll('.', ','),
                            style: normalStyle,
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            formatCurrency(items[i].unitPrice),
                            style: normalStyle,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            formatCurrency(items[i].totalPrice),
                            style: normalStyle,
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Итого
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(
                            'Итого: ',
                            style: pw.TextStyle(
                              font: robotoBoldFont,
                              fontSize: 12,
                            ),
                          ),
                          pw.Text(
                            formatCurrency(quote.totalPrice),
                            style: pw.TextStyle(
                              font: robotoBoldFont,
                              fontSize: 14,
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Без НДС',
                        style: smallStyle,
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // Примечания и подписи
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (quote.notes.isNotEmpty)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Примечания:',
                          style: pw.TextStyle(
                            font: robotoBoldFont,
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(quote.notes, style: normalStyle),
                        pw.SizedBox(height: 16),
                      ],
                    ),
                  
                  // Блок подписей
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Подготовил:', style: normalStyle),
                          pw.SizedBox(height: 20),
                          pw.Container(
                            width: 200,
                            child: pw.Divider(color: PdfColors.black),
                          ),
                          pw.Text('${company.managerName ?? 'Менеджер'} / ${company.position ?? 'Должность'}', style: smallStyle),
                        ],
                      ),
                      
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Согласовано:', style: normalStyle),
                          pw.SizedBox(height: 20),
                          pw.Container(
                            width: 200,
                            child: pw.Divider(color: PdfColors.black),
                          ),
                          pw.Text('Клиент', style: smallStyle),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // Статус и комментарий (если есть)
              if (quote.statusComment != null && quote.statusComment!.isNotEmpty)
                pw.Container(
                  padding: pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Комментарий к статусу:',
                        style: pw.TextStyle(
                          font: robotoBoldFont,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(quote.statusComment!, style: normalStyle),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
  
  // Цвет статуса для PDF
  static PdfColor _getStatusColor(String status) {
    switch (status) {
      case 'draft': return PdfColors.grey;
      case 'sent': return PdfColors.blue;
      case 'accepted': return PdfColors.green;
      case 'rejected': return PdfColors.red;
      case 'expired': return PdfColors.orange;
      default: return PdfColors.grey;
    }
  }

  // Сохранение PDF в файл
  static Future<File> savePdfToFile(Uint8List pdfBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  // Предпросмотр PDF
  static Future<void> previewPdf(Uint8List pdfBytes, BuildContext context) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  // Поделиться PDF
  static Future<void> sharePdf(Uint8List pdfBytes, String fileName, BuildContext context) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(pdfBytes);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Коммерческое предложение $fileName',
      text: 'Отправляю коммерческое предложение $fileName',
    );
  }
}
