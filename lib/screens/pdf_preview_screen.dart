// lib/screens/pdf_preview_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> quote;
  final String fileName;

  const PdfPreviewScreen({
    super.key,
    required this.quote,
    this.fileName = 'proposal.pdf',
  });

  Future<void> _sharePdf(BuildContext context) async {
    try {
      // TODO: Реализовать реальную генерацию PDF
      // Пока просто демонстрируем шаринг текста
      await Share.share(
        'КП для ${quote['clientName']}\n'
        'Сумма: ${quote['totalAmount']} ₽\n'
        'Адрес: ${quote['address']}',
        subject: 'КП ${quote['clientName']}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка шаринга: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('КП для ${quote['clientName']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePdf(context),
            tooltip: 'Поделиться',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            const Center(
              child: Text(
                'КОММЕРЧЕСКОЕ ПРЕДЛОЖЕНИЕ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Информация о клиенте
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Клиент:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(quote['clientName'] ?? 'Не указано'),
                    const SizedBox(height: 8),
                    const Text(
                      'Адрес:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(quote['address'] ?? 'Не указано'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Позиции
            if (quote['positions'] != null && (quote['positions'] as List).isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Состав работ:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate((quote['positions'] as List).length, (index) {
                        final pos = quote['positions'][index];
                        final total = (pos['quantity'] ?? 0) * (pos['price'] ?? 0);
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            child: Text((index + 1).toString()),
                          ),
                          title: Text(pos['name'] ?? 'Без названия'),
                          subtitle: Text('${pos['quantity']} ${pos['unit']} × ${pos['price']} ₽'),
                          trailing: Text(
                            '$total ₽',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 30),
            
            // Итого
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ИТОГО:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${quote['totalAmount']?.toStringAsFixed(2) ?? '0.00'} ₽',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Уведомление
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.info, color: Colors.amber),
                    SizedBox(height: 8),
                    Text(
                      'Реальная генерация PDF будет реализована в следующем обновлении',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.amber.shade800),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
