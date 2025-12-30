import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company_profile.dart';

class PdfService {
  static final PdfService instance = PdfService._init();
  
  PdfService._init();
  
  factory PdfService() => instance;

  final currencyFormat = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 2,
  );

  /// Генерация PDF для коммерческого предложения
  Future<Uint8List> generateQuotePdf(Quote quote, CompanyProfile company) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Заголовок компании
              pw.Text(
                company.companyName,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              pw.Text(company.phone, style: const pw.TextStyle(fontSize: 12)),
              pw.Text(company.email, style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 30),

              // Заголовок документа
              pw.Center(
                child: pw.Text(
                  'КОММЕРЧЕСКОЕ ПРЕДЛОЖЕНИЕ',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),

              // Информация о клиенте
              pw.Text('Клиент: ${quote.clientName}',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              if (quote.clientPhone.isNotEmpty)
                pw.Text('Телефон: ${quote.clientPhone}', style: const pw.TextStyle(fontSize: 12)),
              if (quote.clientEmail.isNotEmpty)
                pw.Text('Email: ${quote.clientEmail}', style: const pw.TextStyle(fontSize: 12)),
              if (quote.projectName.isNotEmpty)
                pw.Text('Проект: ${quote.projectName}', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),

              // Таблица позиций (будет добавлена ниже)
              pw.Text('Позиции:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              // ИТОГО
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'ИТОГО: ${currencyFormat.format(quote.totalAmount)}',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),

              pw.SizedBox(height: 40),

              // Подпись
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Дата: ${DateFormat('dd.MM.yyyy').format(quote.date)}'),
                      pw.SizedBox(height: 20),
                      pw.Text('Подпись: _________________'),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Сохранение PDF в файл
  Future<File> savePdfToFile(Uint8List bytes, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }
}

