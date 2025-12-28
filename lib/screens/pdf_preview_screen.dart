import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/services/pdf_service.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Quote quote;
  final List<LineItem> lineItems;
  final double subtotal;
  final double vatAmount;
  final double total;

  PdfPreviewScreen({
    required this.quote,
    required this.lineItems,
    required this.subtotal,
    required this.vatAmount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    // Конвертируем данные в формат для PdfService
    final quoteMap = {
      'id': quote.id,
      'client_name': quote.clientName,
      'client_phone': quote.clientPhone,
      'object_address': quote.objectAddress,
      'notes': quote.notes,
      'status': quote.status,
      'created_at': quote.createdAt.toIso8601String(),
      'updated_at': quote.updatedAt?.toIso8601String(),
      'total': quote.total,
      'vat_rate': quote.vatRate,
      'positions': lineItems.map((item) => item.toMap()).toList(),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Предпросмотр КП №${quote.id}'),
        backgroundColor: Colors.blueGrey[800],
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () async {
              // Здесь можно добавить сохранение файла
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PDF сохранен в галерею'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            tooltip: 'Сохранить PDF',
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => PdfService.generateQuotePdf(quoteMap),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        useActions: true,
        onPrinted: (context) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF отправлен на печать'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onShared: (context) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF отправлен'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}
