import 'package:flutter/material.dart';
import 'package:ceiling_crm/models/quote.dart';

class QuoteListTile extends StatelessWidget {
  final Quote quote;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onPreview;
  final VoidCallback? onDuplicate;

  const QuoteListTile({
    super.key,
    required this.quote,
    this.onEdit,
    this.onDelete,
    this.onShare,
    this.onPreview,
    this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    quote.clientName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${quote.totalAmount.toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              quote.clientAddress,
              style: TextStyle(color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
            if (quote.clientPhone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '📞 ${quote.clientPhone}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            if (quote.clientEmail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '✉️ ${quote.clientEmail}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text('Позиций: ${quote.items.length}'),
                  backgroundColor: Colors.blue[50],
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    'Создано: ${quote.createdAt.day}.${quote.createdAt.month}.${quote.createdAt.year}',
                  ),
                  backgroundColor: Colors.grey[100],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Редактировать'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPreview,
            icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.green),
            label: const Text('PDF', style: TextStyle(color: Colors.green)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share, size: 16, color: Colors.blue),
            label: const Text('Отправить', style: TextStyle(color: Colors.blue)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}
