import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';

class ProposalDetailScreen extends StatelessWidget {
  final Quote quote;

  const ProposalDetailScreen({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('КП №${quote.id}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quote.clientName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Адрес: ${quote.clientAddress}'),
            if (quote.clientPhone.isNotEmpty)
              Text('Телефон: ${quote.clientPhone}'),
            if (quote.clientEmail.isNotEmpty)
              Text('Email: ${quote.clientEmail}'),
            const SizedBox(height: 16),
            const Divider(),
            const Text(
              'Позиции:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: quote.items.length,
                itemBuilder: (context, index) {
                  final item = quote.items[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('${item.quantity} ${item.unit} × ${item.price} ₽'),
                    trailing: Text(
                      '${(item.quantity * item.price).toStringAsFixed(2)} ₽',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ИТОГО:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${quote.totalAmount.toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
