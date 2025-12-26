// lib/widgets/quote_list_tile.dart

import 'package:flutter/material.dart';
import '../models/quote.dart';

class QuoteListTile extends StatelessWidget {
  final Quote quote;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const QuoteListTile({
    Key? key,
    required this.quote,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  // Функция для цвета статуса
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Подписан':
        return Colors.green;
      case 'Отправлен':
        return Colors.blue;
      case 'В работе':
        return Colors.orange;
      case 'Черновик':
      default:
        return Colors.grey;
    }
  }

  // Форматирование даты
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // Форматирование суммы
  String _formatAmount(double amount) {
    return '${amount.toStringAsFixed(2)} ₽';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getStatusColor(quote.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              quote.customerName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(quote.status),
              ),
            ),
          ),
        ),
        title: Text(
          quote.customerName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              quote.address,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(quote.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    quote.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(quote.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(quote.quoteDate),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatAmount(quote.totalAmount),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            if (quote.prepayment > 0)
              Text(
                'Аванс: ${_formatAmount(quote.prepayment)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
