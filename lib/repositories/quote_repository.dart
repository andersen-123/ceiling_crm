import '../services/database_helper.dart';
import '../models/quote.dart';
import '../models/line_item.dart';

class QuoteRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> addQuote(Quote quote) async {
    return await _dbHelper.insertQuote(quote);
  }

  Future<List<Quote>> getAllQuotes() async {
    return await _dbHelper.getAllQuotes();
  }

  Future<Quote?> getQuoteById(int id) async {
    return await _dbHelper.getQuoteById(id);
  }

  Future<int> updateQuote(Quote quote) async {
    return await _dbHelper.updateQuote(quote);
  }

  Future<int> deleteQuote(int id) async {
    return await _dbHelper.deleteQuote(id);
  }

  Future<double> getTotalRevenue() async {
    return await _dbHelper.getTotalRevenue();
  }

  // Методы для работы с позициями (LineItem)
  Future<int> addLineItem(LineItem item) async {
    return await _dbHelper.insertLineItem(item);
  }

  Future<List<LineItem>> getLineItems(int quoteId) async {
    return await _dbHelper.getLineItems(quoteId);
  }

  Future<int> updateLineItem(LineItem item) async {
    return await _dbHelper.updateLineItem(item);
  }

  Future<int> deleteLineItem(int id) async {
    return await _dbHelper.deleteLineItem(id);
  }
}
