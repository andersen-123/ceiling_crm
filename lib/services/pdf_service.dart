import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ДОБАВЛЕНО
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/models/company_profile.dart';

class PdfService {
  static Future<Uint8List> generateQuotePdfFromModels({
    required Quote quote,
    required List<LineItem> lineItems,
    required CompanyProfile companyProfile,
  }) async {
    final pdf = pw.Document();
    
    // Форматируем дату
    final dateFormat = DateFormat('dd.MM.yyyy');
    final createdDate = quote.createdAt;
    
    // Рассчитываем итоги
    double subtotal = 0;
    for (var item in lineItems) {
      subtotal += item.total;
    }
    
    final vatRate = quote.vatRate;
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
          return _buildPdfContent(
            quote: quote,
            lineItems: lineItems,
            companyProfile: companyProfile,
            dateFormat: dateFormat,
            createdDate: createdDate,
            subtotal: subtotal,
            vatRate: vatRate,
            vatAmount: vatAmount,
            total: total,
            currencyFormat: currencyFormat,
          );
        },
      ),
    );
    
    return pdf.save();
  }

  // Основной метод для совместимости со старой версией
  static Future<Uint8List> generateQuotePdf(Map<String, dynamic> quoteMap) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Загружаем настройки компании
    final companyProfile = CompanyProfile.fromMap({
      'name': prefs.getString('company_name') ?? 'Моя Компания',
      'phone': prefs.getString('company_phone') ?? '+7 (999) 123-45-67',
      'email': prefs.getString('company_email') ?? 'info@company.ru',
      'address': prefs.getString('company_address') ?? 'г. Москва, ул. Примерная, д. 1',
      'vat_rate': prefs.getDouble('vat_rate') ?? 20.0,
      'default_margin': prefs.getDouble('default_margin') ?? 30.0,
      'currency': '₽',
    });
    
    // Создаем модель Quote из Map
    final quote = Quote(
      id: quoteMap['id'],
      clientName: quoteMap['client_name'] ?? '',
      clientPhone: quoteMap['client_phone'] ?? '',
      objectAddress: quoteMap['object_address'] ?? '',
      notes: quoteMap['notes'],
      status: quoteMap['status'] ?? 'draft',
      createdAt: DateTime.parse(quoteMap['created_at']),
      updatedAt: quoteMap['updated_at'] != null 
          ? DateTime.parse(quoteMap['updated_at']) 
          : null,
      total: (quoteMap['total'] as num?)?.toDouble() ?? 0.0,
      vatRate: (quoteMap['vat_rate'] as num?)?.toDouble() ?? 20.0,
    );
    
    // Создаем модели LineItem из positions
    final List<LineItem> lineItems = [];
    final positions = List<Map<String, dynamic>>.from(quoteMap['positions'] ?? []);
    
    for (var position in positions) {
      final lineItem = LineItem(
        id: position['id'],
        quoteId: quote.id ?? 0,
        name: position['name'] ?? '',
        description: position['description'],
        quantity: (position['quantity'] as num?)?.toDouble() ?? 1.0,
        unit: position['unit'] ?? 'шт.',
        price: (position['price'] as num?)?.toDouble() ?? 0.0,
        total: (position['total'] as num?)?.toDouble() ?? 0.0,
        sortOrder: position['sort_order'] ?? 0,
        createdAt: position['created_at'] != null
            ? DateTime.parse(position['created_at'])
            : DateTime.now(),
      );
      lineItems.add(lineItem);
    }
    
    return await generateQuotePdfFromModels(
      quote: quote,
      lineItems: lineItems,
      companyProfile: companyProfile,
    );
  }

  static pw.Widget _buildPdfContent({
    required Quote quote,
    required List<LineItem> lineItems,
    required CompanyProfile companyProfile,
    required DateFormat dateFormat,
    required DateTime createdDate,
    required double subtotal,
    required double vatRate,
    required double vatAmount,
    required double total,
    required NumberFormat currencyFormat,
  }) {
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
                  companyProfile.name,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  companyProfile.address,
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Тел: ${companyProfile.phone} | Email: ${companyProfile.email}',
                  style: pw.TextStyle(fontSize: 10),
                ),
                if (companyProfile.website != null && companyProfile.website!.isNotEmpty)
                  pw.Text(
                    'Сайт: ${companyProfile.website}',
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
                  '№ ${quote.id}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'от ${dateFormat.format(createdDate)}',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: _getStatusColor(quote.status),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    _getStatusLabel(quote.status),
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
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
                    quote.clientName,
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
                    quote.clientPhone,
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
                    quote.objectAddress,
                    style: pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'ПРИМЕЧАНИЕ:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    quote.notes ?? 'Не указано',
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
        
        _buildPositionsTable(lineItems, currencyFormat),
        
        pw.SizedBox(height: 30),
        
        // ИТОГИ
        _buildTotalsSection(
          subtotal: subtotal,
          vatRate: vatRate,
          vatAmount: vatAmount,
          total: total,
          currencyFormat: currencyFormat,
        ),
        
        pw.SizedBox(height: 40),
        
        // ПОДПИСИ
        _buildSignaturesSection(quote, companyProfile),
        
        pw.SizedBox(height: 20),
        
        // ПРИМЕЧАНИЕ
        _buildFooterNote(),
      ],
    );
  }

  static pw.Widget _buildPositionsTable(List<LineItem> lineItems, NumberFormat currencyFormat) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: pw.FlexColumnWidth(0.5),  // №
        1: pw.FlexColumnWidth(3.0),  // Наименование
        2: pw.FlexColumnWidth(0.8),  // Кол-во
        3: pw.FlexColumnWidth(1.2),  // Ед.
        4: pw.FlexColumnWidth(1.5),  // Цена
        5: pw.FlexColumnWidth(1.5),  // Сумма
      },
      children: [
        // Заголовок таблицы
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(
              child: pw.Text(
                '№',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              padding: pw.EdgeInsets.all(6),
            ),
            pw.Padding(
              child: pw.Text(
                'Наименование',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              padding: pw.EdgeInsets.all(6),
            ),
            pw.Padding(
              child: pw.Text(
                'Кол-во',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              padding: pw.EdgeInsets.all(6),
            ),
            pw.Padding(
              child: pw.Text(
                'Ед.',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              padding: pw.EdgeInsets.all(6),
            ),
            pw.Padding(
              child: pw.Text(
                'Цена',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              padding: pw.EdgeInsets.all(6),
            ),
            pw.Padding(
              child: pw.Text(
                'Сумма',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              padding: pw.EdgeInsets.all(6),
            ),
          ],
        ),
        
        // Позиции
        for (int i = 0; i < lineItems.length; i++)
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
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(lineItems[i].name),
                    if (lineItems[i].description != null && lineItems[i].description!.isNotEmpty)
                      pw.Text(
                        lineItems[i].description!,
                        style: pw.TextStyle(fontSize: 8),
                      ),
                  ],
                ),
                padding: pw.EdgeInsets.all(6),
              ),
              pw.Padding(
                child: pw.Text(
                  lineItems[i].quantity.toStringAsFixed(2),
                  textAlign: pw.TextAlign.center,
                ),
                padding: pw.EdgeInsets.all(6),
              ),
              pw.Padding(
                child: pw.Text(
                  lineItems[i].unit,
                  textAlign: pw.TextAlign.center,
                ),
                padding: pw.EdgeInsets.all(6),
              ),
              pw.Padding(
                child: pw.Text(
                  currencyFormat.format(lineItems[i].price),
                  textAlign: pw.TextAlign.center,
                ),
                padding: pw.EdgeInsets.all(6),
              ),
              pw.Padding(
                child: pw.Text(
                  currencyFormat.format(lineItems[i].total),
                  textAlign: pw.TextAlign.center,
                ),
                padding: pw.EdgeInsets.all(6),
              ),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildTotalsSection({
    required double subtotal,
    required double vatRate,
    required double vatAmount,
    required double total,
    required NumberFormat currencyFormat,
  }) {
    return pw.Align(
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
                  child: pw.Text('НДС ${vatRate.toStringAsFixed(1)}%:'),
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
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  padding: pw.EdgeInsets.all(8),
                ),
                pw.Padding(
                  child: pw.Text(
                    currencyFormat.format(total),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.right,
                  ),
                  padding: pw.EdgeInsets.all(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildSignaturesSection(Quote quote, CompanyProfile companyProfile) {
    return pw.Row(
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
              '_________________ / ${companyProfile.name} /',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'М.П.',
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
              '_________________ / ${quote.clientName} /',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${quote.clientPhone}',
              style: pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooterNote() {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Примечание:',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '1. Данное коммерческое предложение действительно в течение 30 дней с даты составления.',
            style: pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            '2. Окончательная стоимость может быть скорректирована после замера объекта.',
            style: pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            '3. Все цены указаны в рублях, включая НДС (если применимо).',
            style: pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  // Вспомогательные методы для статусов
  static String _getStatusLabel(String status) {
    switch (status) {
      case 'draft': return 'ЧЕРНОВИК';
      case 'sent': return 'ОТПРАВЛЕН';
      case 'accepted': return 'ПРИНЯТ';
      case 'rejected': return 'ОТКЛОНЕН';
      default: return 'ЧЕРНОВИК';
    }
  }

  static PdfColor _getStatusColor(String status) {
    switch (status) {
      case 'draft': return PdfColors.grey;
      case 'sent': return PdfColors.blue;
      case 'accepted': return PdfColors.green;
      case 'rejected': return PdfColors.red;
      default: return PdfColors.grey;
    }
  }
}
