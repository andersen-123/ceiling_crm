import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/company_profile.dart';
import 'package:ceiling_crm/services/database_helper.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  // Основной метод генерации PDF
  Future<File> generateQuotePdf(Quote quote, CompanyProfile company) async {
    final pdf = pw.Document();

    // Стили для документа
    final headerStyle = pw.TextStyle(
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blue,
    );

    final subtitleStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.black,
    );

    final normalStyle = pw.TextStyle(
      fontSize: 12,
      color: PdfColors.black,
    );

    final tableHeaderStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    final totalStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.green,
    );

    // Создаем PDF документ
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Text(
            'КП №${quote.id?.toString().padLeft(4, '0') ?? 'Новый'}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey,
            ),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Страница ${context.pageNumber} из ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
        build: (context) => [
          // Заголовок документа
          pw.Header(
            level: 0,
            child: pw.Text('КОММЕРЧЕСКОЕ ПРЕДЛОЖЕНИЕ', style: headerStyle),
          ),
          
          pw.SizedBox(height: 20),
          
          // Информация о компании
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(company.companyName, style: subtitleStyle),
                pw.SizedBox(height: 5),
                pw.Text('Адрес: ${company.address}', style: normalStyle),
                pw.Text('Телефон: ${company.phone}', style: normalStyle),
                pw.Text('Email: ${company.email}', style: normalStyle),
                if (company.website.isNotEmpty)
                  pw.Text('Сайт: ${company.website}', style: normalStyle),
              ],
            ),
          ),
          
          pw.SizedBox(height: 20),
          
          // Информация о клиенте
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('КЛИЕНТ', style: subtitleStyle),
                      pw.SizedBox(height: 10),
                      pw.Text('Имя: ${quote.clientName}', style: normalStyle),
                      if (quote.clientPhone.isNotEmpty)
                        pw.Text('Телефон: ${quote.clientPhone}', style: normalStyle),
                      if (quote.clientAddress.isNotEmpty)
                        pw.Text('Адрес: ${quote.clientAddress}', style: normalStyle),
                    ],
                  ),
                ),
              ),
              
              pw.SizedBox(width: 20),
              
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey, width: 0.5),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ДЕТАЛИ ПРЕДЛОЖЕНИЯ', style: subtitleStyle),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Дата создания: ${_formatDate(quote.createdAt)}',
                        style: normalStyle,
                      ),
                      if (quote.updatedAt != null)
                        pw.Text(
                          'Дата обновления: ${_formatDate(quote.updatedAt!)}',
                          style: normalStyle,
                        ),
                      pw.Text(
                        'Количество позиций: ${quote.items.length}',
                        style: normalStyle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 25),
          
          // Таблица с позициями
          pw.Text('СПИСОК ПОЗИЦИЙ', style: subtitleStyle),
          pw.SizedBox(height: 10),
          
          if (quote.items.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Center(
                child: pw.Text('Нет добавленных позиций', style: normalStyle),
              ),
            )
          else
            pw.Table.fromTextArray(
              context: context,
              border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.blue,
              ),
              headerStyle: tableHeaderStyle,
              cellStyle: normalStyle,
              headerPadding: const pw.EdgeInsets.all(8),
              cellPadding: const pw.EdgeInsets.all(8),
              columnWidths: {
                0: const pw.FlexColumnWidth(3), // Наименование
                1: const pw.FlexColumnWidth(2), // Описание
                2: const pw.FlexColumnWidth(1), // Кол-во
                3: const pw.FlexColumnWidth(1), // Ед.
                4: const pw.FlexColumnWidth(1.5), // Цена
                5: const pw.FlexColumnWidth(1.5), // Сумма
              },
              headers: ['Наименование', 'Описание', 'Кол-во', 'Ед.', 'Цена', 'Сумма'],
              data: quote.items.map((item) => [
                item.name,
                item.description,
                item.quantity.toString(),
                item.unit,
                '${_formatCurrency(item.unitPrice)} руб.',
                '${_formatCurrency(item.totalPrice)} руб.',
              ]).toList(),
            ),
          
          pw.SizedBox(height: 25),
          
          // Итоговая сумма
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue.shade(50),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('ИТОГО К ОПЛАТЕ:', style: subtitleStyle),
                pw.Text(
                  '${_formatCurrency(quote.totalAmount)} руб.',
                  style: totalStyle,
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 30),
          
          // Примечания
          if (quote.notes.isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ПРИМЕЧАНИЯ', style: subtitleStyle),
                  pw.SizedBox(height: 10),
                  pw.Text(quote.notes, style: normalStyle),
                ],
              ),
            ),
          
          pw.SizedBox(height: 30),
          
          // Банковские реквизиты
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('БАНКОВСКИЕ РЕКВИЗИТЫ', style: subtitleStyle),
                pw.SizedBox(height: 10),
                pw.Text(company.bankDetails, style: normalStyle),
                pw.SizedBox(height: 15),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Директор', style: normalStyle.copyWith(fontWeight: pw.FontWeight.bold)),
                        pw.Text(company.directorName, style: normalStyle),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Подпись __________', style: normalStyle),
                        pw.SizedBox(height: 20),
                        pw.Text('М.П.', style: normalStyle),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 20),
          
          // Футер
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey, width: 0.5),
            ),
            child: pw.Center(
              child: pw.Text(
                'Данное коммерческое предложение действительно в течение 30 дней с даты создания',
                style: normalStyle.copyWith(fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );

    // Сохраняем PDF в файл
    return await _savePdfToFile(pdf, quote);
  }

  // Вспомогательные методы
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }

  Future<File> _savePdfToFile(pw.Document pdf, Quote quote) async {
    // Создаем имя файла
    final fileName = 'КП_${quote.clientName.replaceAll(' ', '_')}_${quote.id ?? 'new'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    
    // Получаем директорию для сохранения
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    
    // Сохраняем PDF
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  // Метод для предпросмотра PDF
  Future<void> previewPdf(Quote quote) async {
    try {
      final company = await DatabaseHelper().getCompanyProfile();
      final pdfFile = await generateQuotePdf(quote, company);
      
      await Printing.layoutPdf(
        onLayout: (format) => pdfFile.readAsBytes(),
      );
    } catch (e) {
      print('Ошибка предпросмотра PDF: $e');
      rethrow;
    }
  }

  // Метод для шаринга PDF
  Future<void> sharePdf(Quote quote) async {
    try {
      final company = await DatabaseHelper().getCompanyProfile();
      final pdfFile = await generateQuotePdf(quote, company);
      
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Коммерческое предложение для ${quote.clientName}',
        subject: 'КП №${quote.id?.toString().padLeft(4, '0') ?? "Новый"}',
      );
    } catch (e) {
      print('Ошибка шаринга PDF: $e');
      rethrow;
    }
  }

  // Метод для получения пути к последнему сгенерированному PDF
  Future<String?> getLastPdfPath(Quote quote) async {
    final directory = await getApplicationDocumentsDirectory();
    final files = Directory(directory.path).listSync();
    
    // Ищем PDF файлы для этого КП
    final quotePdfFiles = files.where((file) {
      return file.path.endsWith('.pdf') && 
             file.path.contains('КП_${quote.clientName.replaceAll(' ', '_')}');
    }).toList();
    
    if (quotePdfFiles.isNotEmpty) {
      // Берем самый новый файл
      quotePdfFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return quotePdfFiles.first.path;
    }
    
    return null;
  }
}
