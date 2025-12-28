import '../models/quote.dart';
import '../models/line_item.dart';
import '../services/database_helper.dart';

class QuoteRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Получить все КП
  Future<List<Quote>> getAllQuotes() async {
    return await _dbHelper.getAllQuotes();
  }

  // Получить КП по ID
  Future<Quote?> getQuoteById(int id) async {
    return await _dbHelper.getQuoteById(id);
  }

  // Создать новое КП
  Future<int> createQuote({
    required String title,
    required String clientName,
    String? clientPhone,
    String? clientEmail,
    String? clientAddress,
    DateTime? validUntil,
    String notes = '',
  }) async {
    final quote = Quote(
      title: title,
      clientName: clientName,
      clientPhone: clientPhone,
      clientEmail: clientEmail,
      clientAddress: clientAddress,
      createdAt: DateTime.now(),
      validUntil: validUntil,
      notes: notes,
      totalPrice: 0.0,
    );
    
    return await _dbHelper.insertQuote(quote);
  }

  // Обновить КП
  Future<int> updateQuote(Quote quote) async {
    return await _dbHelper.updateQuote(quote);
  }

  // Удалить КП
  Future<int> deleteQuote(int id) async {
    return await _dbHelper.deleteQuote(id);
  }

  // Поиск КП
  Future<List<Quote>> searchQuotes(String query) async {
    return await _dbHelper.searchQuotes(query);
  }

  // Получить позиции КП
  Future<List<LineItem>> getLineItemsByQuoteId(int quoteId) async {
    return await _dbHelper.getLineItemsByQuoteId(quoteId);
  }

  // Добавить позицию
  Future<int> addLineItem(LineItem item) async {
    return await _dbHelper.insertLineItem(item);
  }

  // Обновить позицию
  Future<int> updateLineItem(LineItem item) async {
    return await _dbHelper.updateLineItem(item);
  }

  // Удалить позицию
  Future<int> deleteLineItem(int id) async {
    return await _dbHelper.deleteLineItem(id);
  }

  // Обновить статус КП
  Future<int> updateQuoteStatus(int quoteId, String status, {String? comment}) async {
    final quote = await _dbHelper.getQuoteById(quoteId);
    if (quote == null) return 0;
    
    final updatedQuote = quote.copyWith(
      status: status,
      statusChangedAt: DateTime.now(),
      statusComment: comment,
    );
    
    return await _dbHelper.updateQuote(updatedQuote);
  }

  // Получить статистику
  Future<Map<String, int>> getStatistics() async {
    return await _dbHelper.getQuotesStatistics();
  }
}
