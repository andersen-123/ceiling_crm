import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PdfService {
  static Future<Uint8List> generateQuotePdf(Map<String, dynamic> quote) async {
    final pdf = pw.Document();
    final prefs = await SharedPreferences.getInstance();
    
    // Загружаем настройки компании
    final companyName = prefs.getString('company_name') ?? 'Моя Компания';
    final companyPhone = prefs.getString('company_phone') ?? '+7 (999) 123-45-67';
    final companyEmail = prefs.getString('company_email') ?? 'info@company.ru';
    final companyAddress = prefs.getString('company_address') ?? 'г. Москва, ул. Примерная, д. 1';
    final vatRate = prefs.getDouble('vat_rate') ?? 20.0;
    
    // Форматируем дату
    final dateFormat = DateFormat('dd.MM.yyyy');
    final createdDate = quote['created_at'] != null 
        ? DateTime.parse(quote['created_at']) 
        : DateTime.now();
    
    // Рассчитываем итоги
    double subtotal = 0;
    final List<Map<String, dynamic>> positions = 
        List<Map<String, dynamic>>.from(quote['positions'] ?? []);
    
    for (var position in positions) {
      subtotal += (position['price'] ?? 0) * (position['quantity'] ?? 1);
    }
    
    final vatAmount = subtotal * (vatRate / 100);
    final total = subtotal + vatAmount;
    
    // Форматируем валюту
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 2,
    );
    
    // Создаем PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ШАПКА КОМПАНИИ
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        companyAddress,
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Тел: $companyPhone | Email: $companyEmail',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'КОММЕРЧЕСКОЕ ПРЕДЛОЖЕНИЕ',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '№ ${quote['id']}',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        'от ${dateFormat.format(createdDate)}',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              
              // ДАННЫЕ КЛИЕНТА
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'КЛИЕНТ:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          quote['client_name'] ?? 'Не указано',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'ТЕЛЕФОН:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          quote['client_phone'] ?? 'Не указано',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'АДРЕС ОБЪЕКТА:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          quote['object_address'] ?? 'Не указано',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'СРОК ДЕЙСТВИЯ:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '30 дней с даты составления',
                          style: pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // ТАБЛИЦА ПОЗИЦИЙ
              pw.Text(
                'СПЕЦИФИКАЦИЯ РАБОТ И МАТЕРИАЛОВ',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(1),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1),
                  4: pw.FlexColumnWidth(1),
                },
                children: [
                  // Заголовок таблицы
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        child: pw.Text(
                          '№',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        padding: pw.EdgeInsets.all(6),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          'Наименование',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        padding: pw.EdgeInsets.all(6),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          'Кол-во',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        padding: pw.EdgeInsets.all(6),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          'Цена',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        padding: pw.EdgeInsets.all(6),
                      ),
                      pw.Padding(
                        child: pw.Text(
                          'Сумма',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        padding: pw.EdgeInsets.all(6),
                      ),
                    ],
                  ),
                  
                  // Позиции
                  for (int i = 0; i < positions.length; i++)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          child: pw.Text(
                            '${i + 1}',
                            textAlign: pw.TextAlign.center,
                          ),
                          padding: pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(positions[i]['name'] ?? ''),
                          padding: pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(
                            positions[i]['quantity'].toString(),
                            textAlign: pw.TextAlign.center,
                          ),
                          padding: pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(
                            currencyFormat.format(positions[i]['price'] ?? 0),
                            textAlign: pw.TextAlign.center,
                          ),
                          padding: pw.EdgeInsets.all(6),
                        ),
                        pw.Padding(
                          child: pw.Text(
                            currencyFormat.format(
                              (positions[i]['price'] ?? 0) * (positions[i]['quantity'] ?? 1)
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          padding: pw.EdgeInsets.all(6),
                        ),
                      ],
                    ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // ИТОГИ
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 300,
                  child: pw.Table(
                    border: pw.TableBorder.all(),
                    columnWidths: {
                      0: pw.FlexColumnWidth(2),
                      1: pw.FlexColumnWidth(1),
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            child: pw.Text('Сумма без НДС:'),
                            padding: pw.EdgeInsets.all(8),
                          ),
                          pw.Padding(
                            child: pw.Text(
                              currencyFormat.format(subtotal),
                              textAlign: pw.TextAlign.right,
                            ),
                            padding: pw.EdgeInsets.all(8),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            child: pw.Text('НДС ${vatRate}%:'),
                            padding: pw.EdgeInsets.all(8),
                          ),
                          pw.Padding(
                            child: pw.Text(
                              currencyFormat.format(vatAmount),
                              textAlign: pw.TextAlign.right,
                            ),
                            padding: pw.EdgeInsets.all(8),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          pw.Padding(
                            child: pw.Text(
                              'ИТОГО:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            padding: pw.EdgeInsets.all(8),
                          ),
                          pw.Padding(
                            child: pw.Text(
                              currencyFormat.format(total),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                            padding: pw.EdgeInsets.all(8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              pw.SizedBox(height: 40),
              
              // ПОДПИСИ
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'От компании:',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Text(
                        '_________________ / ${companyName} /',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Принял(а):',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Text(
                        '_________________ / ${quote['client_name'] ?? 'Клиент'} /',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // ПРИМЕЧАНИЕ
              pw.Container(
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Примечание: Данное коммерческое предложение является предварительным расчетом. '
                  'Окончательная стоимость может быть скорректирована после замера объекта.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    
    return pdf.save();
  }
}
