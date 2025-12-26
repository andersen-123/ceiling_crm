// lib/services/pdf_service.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../data/database_helper.dart';

class PdfService {
  // 1. Основной метод генерации PDF
  Future<File> generateQuotePdf(Quote quote, List<LineItem> lineItems) async {
    // Создаём PDF-документ
    final pdf = pw.Document();

    // Добавляем страницу с содержимым
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          // Заголовок документа
          _buildHeader(quote),
          pw.SizedBox(height: 20),
          
          // Информация о клиенте
          _buildClientInfo(quote),
          pw.SizedBox(height: 20),
          
          // Таблица с позициями
          _buildLineItemsTable(lineItems),
          pw.SizedBox(height: 20),
          
          // Итоговая информация
          _buildTotals(quote, lineItems),
          pw.SizedBox(height: 30),
          
          // Подписи
          _buildSignatures(),
        ],
      ),
    );

    // Сохраняем PDF во временный файл
    return await _savePdfToFile(pdf, quote);
  }

  // 2. Заголовок документа
  pw.Widget _buildHeader(Quote quote) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
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
                  '№ ${quote.id?.toString().padLeft(4, '0') ?? 'НОВЫЙ'}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Дата: ${_formatDate(quote.quoteDate)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Статус: ${quote.status}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(quote.status),
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  // 3. Информация о клиенте
  pw.Widget _buildClientInfo(Quote quote) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'КЛИЕНТ',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Имя:', quote.customerName),
                  _buildInfoRow('Телефон:', quote.customerPhone),
                ],
              ),
              pw.SizedBox(width: 40),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Адрес:', quote.address),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Строка информации
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$label ',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value.isNotEmpty ? value : 'не указано',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // 5. Таблица с позициями
  pw.Widget _buildLineItemsTable(List<LineItem> lineItems) {
    // Группируем позиции по разделам
    final Map<String, List<LineItem>> groupedItems = {};
    for (final item in lineItems) {
      groupedItems.putIfAbsent(item.section, () => []).add(item);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'СПЕЦИФИКАЦИЯ',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
        pw.SizedBox(height: 8),
        
        // Для каждого раздела создаём свою таблицу
        for (final section in groupedItems.keys) ...[
          pw.Text(
            section.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          _buildSectionTable(groupedItems[section]!),
          pw.SizedBox(height: 12),
        ],
      ],
    );
  }

  // 6. Таблица для одного раздела
  pw.Widget _buildSectionTable(List<LineItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(5), // №
        1: const pw.FlexColumnWidth(25), // Описание
        2: const pw.FlexColumnWidth(5), // Ед.
        3: const pw.FlexColumnWidth(5), // Кол-во
        4: const pw.FlexColumnWidth(7), // Цена
        5: const pw.FlexColumnWidth(7), // Сумма
      },
      children: [
        // Заголовок таблицы
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('№', isHeader: true),
            _buildTableCell('Наименование работ/материалов', isHeader: true),
            _buildTableCell('Ед.', isHeader: true),
            _buildTableCell('Кол-во', isHeader: true),
            _buildTableCell('Цена', isHeader: true),
            _buildTableCell('Сумма', isHeader: true),
          ],
        ),
        // Данные
        for (int i = 0; i < items.length; i++)
          pw.TableRow(
            children: [
              _buildTableCell('${i + 1}'),
              _buildTableCell(items[i].description),
              _buildTableCell(items[i].unit),
              _buildTableCell(items[i].quantity.toStringAsFixed(2)),
              _buildTableCell('${items[i].unitPrice.toStringAsFixed(2)} ₽'),
              _buildTableCell('${items[i].total.toStringAsFixed(2)} ₽'),
            ],
          ),
      ],
    );
  }

  // 7. Ячейка таблицы
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: isHeader
            ? pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)
            : const pw.TextStyle(fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // 8. Итоговая информация
  pw.Widget _buildTotals(Quote quote, List<LineItem> lineItems) {
    final total = lineItems.fold(0.0, (sum, item) => sum + item.total);
    final vat = total * 0.2; // НДС 20%
    final totalWithVat = total + vat;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildTotalRow('Итого без НДС:', total),
            _buildTotalRow('НДС 20%:', vat),
            pw.Divider(thickness: 1),
            _buildTotalRow('Всего к оплате:', totalWithVat, isBold: true),
            pw.SizedBox(height: 10),
            if (quote.prepayment > 0) ...[
              _buildTotalRow('Аванс:', quote.prepayment),
              _buildTotalRow(
                'Остаток к оплате:',
                totalWithVat - quote.prepayment,
                isBold: true,
                color: PdfColors.green,
              ),
            ],
            pw.SizedBox(height: 20),
            pw.Text(
              '*Срок действия предложения: 30 календарных дней',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ),
      ],
    );
  }

  // 9. Строка итогов
  pw.Widget _buildTotalRow(String label, double amount,
      {bool isBold = false, PdfColor? color}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Text(
          '${amount.toStringAsFixed(2)} ₽',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  // 10. Блок подписей
  pw.Widget _buildSignatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // Исполнитель
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Исполнитель:', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 40),
            pw.Text('_________________',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text('(подпись)', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 5),
            pw.Text('М.П.', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        // Заказчик
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Заказчик:', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 40),
            pw.Text('_________________',
                style: const pw.TextStyle(fontSize: 12)),
            pw.Text('(подпись)', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 5),
            pw.Text('М.П.', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  // 11. Сохранение PDF в файл
  Future<File> _savePdfToFile(pw.Document pdf, Quote quote) async {
    // Получаем директорию для временных файлов
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName =
        'КП_${quote.customerName}_${quote.id}_$timestamp.pdf'
            .replaceAll(RegExp(r'[^\w\d]'), '_'); // Заменяем спецсимволы
    final path = '${directory.path}/$fileName';

    // Сохраняем PDF
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // 12. Вспомогательные методы
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  PdfColor _getStatusColor(String status) {
    switch (status) {
      case 'Подписан':
        return PdfColors.green;
      case 'Отправлен':
        return PdfColors.blue;
      case 'В работе':
        return PdfColors.orange;
      case 'Черновик':
      default:
        return PdfColors.grey;
    }
  }

  // 13. Просмотр PDF (для отладки)
  Future<void> previewPdf(Quote quote, List<LineItem> lineItems) async {
    final pdf = await generateQuotePdf(quote, lineItems);
    await Printing.layoutPdf(
      onLayout: (format) => pdf.readAsBytes(),
    );
  }
}
