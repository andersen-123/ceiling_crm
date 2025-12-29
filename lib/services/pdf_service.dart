import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company_profile.dart';
import '../data/database_helper.dart';

class PdfService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Uint8List> generateQuotePdf(Quote quote, List<LineItem> items) async {
    final pdf = pw.Document();
    final company = await _dbHelper.getCompanyProfile() ?? CompanyProfile(
      id: 1,
      name: 'Ваша компания',
      email: '',
      phone: '',
      address: '',
      website: '',
      taxId: '',
      logoPath: '',
      createdAt: DateTime.now(),
    );

    final dateFormat = DateFormat('dd.MM.yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 2,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Заголовок
              pw.Center(
                child: pw.Text(
                  'КОММЕРЧЕСКОЕ ПРЕДЛОЖЕНИЕ',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 20),

              // Информация о компании
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          company.name,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (company.address.isNotEmpty)
                          pw.Text(
                            'Адрес: ${company.address}',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        if (company.phone.isNotEmpty)
                          pw.Text(
                            'Телефон: ${company.phone}',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        if (company.email.isNotEmpty)
                          pw.Text(
                            'Email: ${company.email}',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        if (company.website.isNotEmpty)
                          pw.Text(
                            'Сайт: ${company.website}',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        if (company.taxId.isNotEmpty)
                          pw.Text(
                            'ИНН: ${company.taxId}',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        '№ ${quote.id}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Дата: ${dateFormat.format(quote.createdAt)}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Статус: ${quote.status}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Информация о клиенте
              pw.Text(
                'Клиент:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      quote.clientName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (quote.clientEmail.isNotEmpty)
                      pw.Text(
                        'Телефон: ${quote.clientPhone}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    if (quote.clientEmail.isNotEmpty)
                      pw.Text(
                        'Email: ${quote.clientEmail}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    if (quote.clientAddress.isNotEmpty)
                      pw.Text(
                        'Адрес: ${quote.clientAddress}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Название проекта
              if (quote.projectName.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Проект:',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      quote.projectName,
                      style: pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 10),
                  ],
                ),

              // Описание проекта
              if (quote.projectDescription.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Описание работ:',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      quote.projectDescription,
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                ),

              // Таблица позиций
              pw.Text(
                'Спецификация:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FixedColumnWidth(50),
                  3: const pw.FixedColumnWidth(60),
                  4: const pw.FixedColumnWidth(40),
                  5: const pw.FixedColumnWidth(80),
                },
                children: [
                  // Заголовок таблицы
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          '№',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Наименование',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Кол-во',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Ед.',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Цена',
                          style: pw.TextStyle(  // ИСПРАВЛЕНО: было pwStyle
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          'Сумма',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),

                  // Данные таблицы
                  for (var i = 0; i < items.length; i++)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '${i + 1}',
                            style: pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            items[i].description,  // ИСПРАВЛЕНО: убрали !
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            items[i].quantity.toStringAsFixed(2),
                            style: pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            items[i].unit,
                            style: pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            currencyFormat.format(items[i].price),
                            style: pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            currencyFormat.format(items[i].totalPrice),
                            style: pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Итоговая сумма
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Итого: ',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    currencyFormat.format(quote.totalAmount),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Примечания
              if (quote.notes.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Примечания:',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      quote.notes,
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                ),

              // Подпись
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        pw.Divider(),
                        pw.Text(
                          'С уважением, ${company.name}',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Дата: ${dateFormat.format(DateTime.now())}',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
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
}
