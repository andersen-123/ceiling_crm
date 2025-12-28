import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/services/database_helper.dart';

class QuoteRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ============ QUOTE OPERATIONS ============

  Future<int> createQuote({
    required String clientName,
    required String clientPhone,
    required String objectAddress,
    String? notes,
    double vatRate = 20.0,
  }) async {
    final quote = Quote(
      clientName: clientName,
      clientPhone: clientPhone,
      objectAddress: objectAddress,
      notes: notes,
      status: 'draft',
      createdAt: DateTime.now(),
      total: 0.0,
      vatRate: vatRate,
    );
    
    return await _dbHelper.insertQuote(quote);
  }

  Future<List<Quote>> getAllQuotes() async {
    return await _dbHelper.getAllQuotes();
  }

  Future<Quote?> getQuote(int id) async {
    final quote = await _dbHelper.getQuote(id);
    if (quote != null) {
      final lineItems = await _dbHelper.getLineItemsForQuote(id);
      // Здесь можно добавить lineItems в quote если нужно
    }
    return quote;
  }

  Future<void> updateQuote(Quote quote) async {
    await _dbHelper.updateQuote(quote);
  }

  Future<void> deleteQuote(int id) async {
    await _dbHelper.deleteQuote(id);
  }

  Future<List<Quote>> searchQuotes(String query) async {
    return await _dbHelper.searchQuotes(query);
  }

  Future<List<Quote>> getQuotesByStatus(String status) async {
    return await _dbHelper.getQuotesByStatus(status);
  }

  // ============ LINE ITEM OPERATIONS ============

  Future<int> addLineItem({
    required int quoteId,
    required String name,
    String? description,
    required double quantity,
    String unit = 'шт.',
    required double price,
  }) async {
    final total = price * quantity;
    
    final lineItem = LineItem(
      quoteId: quoteId,
      name: name,
      description: description,
      quantity: quantity,
      unit: unit,
      price: price,
      total: total,
      sortOrder: 0,
      createdAt: DateTime.now(),
    );
    
    return await _dbHelper.insertLineItem(lineItem);
  }

  Future<List<LineItem>> getLineItems(int quoteId) async {
    return await _dbHelper.getLineItemsForQuote(quoteId);
  }

  Future<void> updateLineItem(LineItem item) async {
    // Пересчитываем total перед сохранением
    final updatedItem = item.copyWith(
      total: item.price * item.quantity,
    );
    
    await _dbHelper.updateLineItem(updatedItem);
  }

  Future<void> deleteLineItem(int id) async {
    await _dbHelper.deleteLineItem(id);
  }

  Future<void> addLineItemsFromTemplates(
    int quoteId, 
    List<Map<String, dynamic>> templates
  ) async {
    for (final template in templates) {
      await addLineItem(
        quoteId: quoteId,
        name: template['name'] ?? '',
        description: template['description'],
        quantity: template['quantity']?.toDouble() ?? 1.0,
        unit: template['unit'] ?? 'шт.',
        price: template['price']?.toDouble() ?? 0.0,
      );
    }
  }

  // ============ BUSINESS LOGIC ============

  Future<double> calculateQuoteTotal(int quoteId) async {
    final lineItems = await getLineItems(quoteId);
    double total = 0;
    
    for (final item in lineItems) {
      total += item.total;
    }
    
    return total;
  }

  Future<void> updateQuoteStatus(int quoteId, String status) async {
    final quote = await getQuote(quoteId);
    if (quote != null) {
      final updatedQuote = quote.copyWith(status: status);
      await updateQuote(updatedQuote);
    }
  }

  Future<Map<String, dynamic>> getQuoteSummary(int quoteId) async {
    final quote = await getQuote(quoteId);
    final lineItems = await getLineItems(quoteId);
    
    double subtotal = 0;
    for (final item in lineItems) {
      subtotal += item.total;
    }
    
    final vatRate = quote?.vatRate ?? 20.0;
    final vatAmount = subtotal * (vatRate / 100);
    final total = subtotal + vatAmount;
    
    return {
      'quote': quote,
      'line_items': lineItems,
      'subtotal': subtotal,
      'vat_rate': vatRate,
      'vat_amount': vatAmount,
      'total': total,
      'item_count': lineItems.length,
    };
  }
}
