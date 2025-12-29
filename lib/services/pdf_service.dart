import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company_profile.dart';

class PdfService {
  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 0,
  );

  Future<File> generateQuotePdf({
    required Quote quote,
    required List<LineItem> items,
    required CompanyProfile companyProfile,
  }) async {
    final pdf = pw.Document();

    // Получаем путь для сохранения
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'КП_${quote.clientName}_$timestamp.pdf';
    final filePath = '${directory.path}/$fileName';

    // Создаем PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Шапка с логотипом и реквизитами
              _buildHeader(companyProfile),
              pw.SizedBox(height: 30),
              
              // Заголовок КП
              pw.Center(
                child: pw.Text(
                  'КОММЕРЧЕСКОЕ ПРЕДЛОЖЕНИЕ',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Информация о клиенте
              _buildClientInfo(quote),
              pw.SizedBox(height: 20),
              
              // Таблица позиций
              _buildItemsTable(items),
              pw.SizedBox(height: 20),
              
              // Итоговая сумма
              _buildTotal(quote),
              pw.SizedBox(height: 30),
              
              // Подписи
              _buildSignatures(),
            ],
          );
        },
      ),
    );

    // Сохраняем файл
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildHeader(CompanyProfile company) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              company.companyName,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (company.address != null && company.address!.isNotEmpty)
              pw.Text(company.address!, style: _smallText()),
            if (company.phone != null && company.phone!.isNotEmpty)
              pw.Text('Тел: ${company.phone!}', style: _smallText()),
            if (company.email != null && company.email!.isNotEmpty)
              pw.Text('Email: ${company.email!}', style: _smallText()),
            if (company.website != null && company.website!.isNotEmpty)
              pw.Text('Сайт: ${company.website!}', style: _smallText()),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildClientInfo(Quote quote) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Клиент: ${quote.clientName}', style: _normalText()),
        if (quote.address != null && quote.address!.isNotEmpty)
          pw.Text('Адрес: ${quote.address!}', style: _normalText()),
        if (quote.phone != null && quote.phone!.isNotEmpty)
          pw.Text('Телефон: ${quote.phone!}', style: _normalText()),
        if (quote.email != null && quote.email!.isNotEmpty)
          pw.Text('Email: ${quote.email!}', style: _normalText()),
        pw.Text(
          'Дата: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}',
          style: _normalText(),
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable(List<LineItem> items) {
    final headers = ['№', 'Наименование', 'Кол-во', 'Ед.', 'Цена', 'Сумма'];
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(50),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(70),
        5: const pw.FixedColumnWidth(80),
      },
      children: [
        // Заголовки таблицы
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers
              .map((text) => pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      text,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ))
              .toList(),
        ),
        // Данные
        for (int i = 0; i < items.length; i++)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('${i + 1}', style: _tableText()),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(items[i].description, style: _tableText()),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  items[i].quantity.toString(),
                  style: _tableText(),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  items[i].unit ?? 'шт.',
                  style: _tableText(),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  currencyFormat.format(items[i].pricePerUnit),
                  style: _tableText(),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  currencyFormat.format(items[i].total),
                  style: _tableText(),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildTotal(Quote quote) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'ИТОГО: ${currencyFormat.format(quote.totalAmount)}',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            _amountInWords(quote.totalAmount),
            style: _smallText(),
            textAlign: pw.TextAlign.right,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('От лица Исполнителя:', style: _smallText()),
            pw.SizedBox(height: 40),
            pw.Text('_________________ / _________________', style: _smallText()),
            pw.Text('         (подпись)          (ФИО)', style: _verySmallText()),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('От лица Заказчика:', style: _smallText()),
            pw.SizedBox(height: 40),
            pw.Text('_________________ / _________________', style: _smallText()),
            pw.Text('         (подпись)          (ФИО)', style: _verySmallText()),
          ],
        ),
      ],
    );
  }

  String _amountInWords(double amount) {
    final int rubles = amount.floor();
    final int kopecks = ((amount - rubles) * 100).round();
    return '${NumberFormat("#,##0", "ru_RU").format(rubles)} руб. $kopecks коп.';
  }

  pw.TextStyle _smallText() {
    return const pw.TextStyle(fontSize: 10);
  }

  pw.TextStyle _verySmallText() {
    return const pw.TextStyle(fontSize: 8);
  }

  pw.TextStyle _normalText() {
    return const pw.TextStyle(fontSize: 12);
  }

  pw.TextStyle _tableText() {
    return const pw.TextStyle(fontSize: 10);
  }

  // Метод для предпросмотра PDF
  Future<void> previewPdf({
    required Quote quote,
    required List<LineItem> items,
    required CompanyProfile companyProfile,
  }) async {
    final pdfFile = await generateQuotePdf(
      quote: quote,
      items: items,
      companyProfile: companyProfile,
    );
    
    // Показываем предпросмотр
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return await pdfFile.readAsBytes();
      },
    );
  }

  // Метод для шаринга PDF
  Future<void> sharePdf({
    required Quote quote,
    required List<LineItem> items,
    required CompanyProfile companyProfile,
  }) async {
    try {
      final pdfFile = await generateQuotePdf(
        quote: quote,
        items: items,
        companyProfile: companyProfile,
      );
      
      // Шарим файл
      await Share.shareFiles(
        [pdfFile.path],
        text: 'Коммерческое предложение для ${quote.clientName}',
        subject: 'КП ${quote.clientName}',
      );
      
    } catch (e) {
      rethrow;
    }
  }
}
