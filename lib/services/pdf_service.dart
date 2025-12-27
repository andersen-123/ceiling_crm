import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ceiling_crm/models/quote.dart';

class PdfService {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 2,
  );

  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  Future<Uint8List> generateQuotePdf(Quote quote) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(quote),
              pw.SizedBox(height: 20),
              _buildClientInfo(quote),
              pw.SizedBox(height: 20),
              _buildItemsTable(quote),
              pw.SizedBox(height: 20),
              _buildTotalSection(quote),
              if (quote.notes.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildNotesSection(quote),
              ],
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

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
          columnWidths: {
            0: const pw.FlexColumnWidth(0.5),
            1: const pw.FlexColumnWidth(2.5),
            2: const pw.FlexColumnWidth(0.8),
            3: const pw.FlexColumnWidth(0.7),
            4: const pw.FlexColumnWidth(1.0),
            5: const pw.FlexColumnWidth(1.0),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('№', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Наименование', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Кол-во', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Ед.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Цена', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Сумма', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ),
              ],
            ),
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
                    child: pw.Text(quote.items[i].quantity.toStringAsFixed(2), textAlign: pw.TextAlign.right),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(quote.items[i].unit),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(_currencyFormat.format(quote.items[i].price), textAlign: pw.TextAlign.right),
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

  Future<void> previewPdf(BuildContext context, Quote quote) async {
    try {
      final pdfBytes = await generateQuotePdf(quote);
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      print('Ошибка предпросмотра PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка предпросмотра: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> sharePdf(BuildContext context, Quote quote) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Генерация PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Подготовка файла для отправки...'),
            ],
          ),
        ),
      );

      final pdfBytes = await generateQuotePdf(quote);
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/КП_${quote.id}_${quote.clientName}.pdf');
      await file.writeAsBytes(pdfBytes);

      if (context.mounted) {
        Navigator.of(context).pop();
        await Share.shareFiles([file.path], text: 'Коммерческое предложение для ${quote.clientName}');
      }
    } catch (e) {
      print('Ошибка шаринга PDF: $e');
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
