import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:intl/intl.dart';

class PdfService {
  // Формат чисел для рублей
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 2,
  );

  // Формат даты
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  // Генерация PDF документа
  Future<Uint8List> generateQuotePdf(Quote quote) async {
    final pdf = pw.Document();

    // Добавляем страницу
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Шапка документа
              _buildHeader(quote),
              pw.SizedBox(height: 20),
              
              // Информация о клиенте
              _buildClientInfo(quote),
              pw.SizedBox(height: 20),
              
              // Таблица позиций
              _buildItemsTable(quote),
              pw.SizedBox(height: 20),
              
              // Итоговая сумма
              _buildTotalSection(quote),
              pw.SizedBox(height: 20),
              
              // Примечания
              if (quote.notes.isNotEmpty) _buildNotesSection(quote),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Шапка документа
  pw.Widget _buildHeader(Quote quote) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'КОММЕРЧЕСКОЕ ПРЕДЛОЖЕНИЕ',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          '№ ${quote.id} от ${_dateFormat.format(quote.createdAt)}',
          style: pw.TextStyle(fontSize: 14),
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  // Информация о клиенте
  pw.Widget _buildClientInfo(Quote quote) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'КЛИЕНТ',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Имя: ${quote.clientName}'),
        pw.Text('Адрес: ${quote.clientAddress}'),
        if (quote.clientPhone.isNotEmpty) pw.Text('Телефон: ${quote.clientPhone}'),
        if (quote.clientEmail.isNotEmpty) pw.Text('Email: ${quote.clientEmail}'),
      ],
    );
  }

  // Таблица позиций
  pw.Widget _buildItemsTable(Quote quote) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'СМЕТА',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            // Заголовок таблицы
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    '№',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Наименование',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Кол-во',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Ед.',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Цена',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Сумма',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
            // Данные позиций
            for (int i = 0; i < quote.items.length; i++)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('${i + 1}'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(quote.items[i].name),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      quote.items[i].quantity.toStringAsFixed(2),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(quote.items[i].unit),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      _currencyFormat.format(quote.items[i].price),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      _currencyFormat.format(quote.items[i].quantity * quote.items[i].price),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  // Итоговая сумма
  pw.Widget _buildTotalSection(Quote quote) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'ИТОГО:',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            _currencyFormat.format(quote.totalAmount),
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green,
            ),
          ),
        ],
      ),
    );
  }

  // Примечания
  pw.Widget _buildNotesSection(Quote quote) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ПРИМЕЧАНИЯ:',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(quote.notes),
      ],
    );
  }

  // Предпросмотр PDF
  Future<void> previewPdf(BuildContext context, Quote quote) async {
    final pdfBytes = await generateQuotePdf(quote);
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  // Сохранение PDF в файл
  Future<void> savePdfToFile(Quote quote) async {
    final pdfBytes = await generateQuotePdf(quote);
    
    // TODO: Реализовать сохранение в файл
    // Для этого нужен пакет file_picker или path_provider
  }
}
