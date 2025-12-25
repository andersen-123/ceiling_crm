// Виджет для отображения карточки коммерческого предложения в списке.
// Отображает основную информацию: клиент, объект, сумму, статус и дату.
// Поддерживает свайп-жесты для быстрых действий.

import 'package:flutter/material.dart';
import '../models/quote.dart';

class QuoteListTile extends StatelessWidget {
  final Quote quote;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const QuoteListTile({
    super.key,
    required this.quote,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicate,
  });

  // Метод для получения цвета статуса
  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey.shade600;
      case 'sent':
        return Colors.orange.shade600;
      case 'approved':
        return Colors.green.shade600;
      case 'completed':
        return Colors.blue.shade600;
      default:
        return Colors.grey;
    }
  }

  // Метод для получения текста статуса
  String _getStatusText(String status) {
    switch (status) {
      case 'draft':
        return 'Черновик';
      case 'sent':
        return 'Отправлено';
      case 'approved':
        return 'Согласовано';
      case 'completed':
        return 'Выполнено';
      default:
        return status;
    }
  }

  // Метод для форматирования даты
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    // Сегодня
    if (difference.inDays == 0) {
      return 'Сегодня, ${_formatTime(date)}';
    }
    // Вчера
    else if (difference.inDays == 1) {
      return 'Вчера, ${_formatTime(date)}';
    }
    // Неделя назад
    else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    }
    // Стандартное форматирование
    else {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }

  // Метод для форматирования времени
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Метод для форматирования суммы
  String _formatAmount(double amount, String currencyCode) {
    final formatted = amount.toStringAsFixed(2);
    
    switch (currencyCode) {
      case 'RUB':
        return '$formatted ₽';
      case 'USD':
        return '\$$formatted';
      case 'EUR':
        return '€$formatted';
      default:
        return '$formatted $currencyCode';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('quote_${quote.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Удалить',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 16),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        // Показываем подтверждение перед удалением
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Удалить КП?'),
            content: const Text('Коммерческое предложение будет перемещено в корзину.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Удалить', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        onDelete();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Индикатор статуса (цветная полоска)
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getStatusColor(quote.status),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Основное содержимое
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Первая строка: Клиент и сумма
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              quote.customerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatAmount(quote.totalAmount, quote.currencyCode),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Вторая строка: Объект и статус
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              quote.objectName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(quote.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getStatusColor(quote.status).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getStatusText(quote.status),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getStatusColor(quote.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Третья строка: Адрес и дата
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              quote.address ?? 'Адрес не указан',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(quote.updatedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      
                      // Четвертая строка: Дополнительная информация (если есть)
                      if (quote.notes != null && quote.notes!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              quote.notes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Кнопка дополнительных действий
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'duplicate') {
                      onDuplicate();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 8),
                          Text('Дублировать'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Удалить', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
