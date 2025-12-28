import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/quote.dart';
import '../models/line_item.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ceiling_crm.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Таблица КП
    await db.execute('''
      CREATE TABLE quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_name TEXT NOT NULL,
        client_phone TEXT NOT NULL,
        object_address TEXT NOT NULL,
        notes TEXT,
        status TEXT DEFAULT 'draft',
        created_at TEXT NOT NULL,
        updated_at TEXT,
        total REAL DEFAULT 0,
        vat_rate REAL DEFAULT 20.0
      )
    ''');

    // Таблица позиций
    await db.execute('''
      CREATE TABLE line_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        quantity REAL DEFAULT 1,
        unit TEXT DEFAULT 'шт.',
        price REAL NOT NULL,
        total REAL NOT NULL,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (quote_id) REFERENCES quotes (id) ON DELETE CASCADE
      )
    ''');

    // Индексы для производительности
    await db.execute('CREATE INDEX idx_quotes_status ON quotes(status)');
    await db.execute('CREATE INDEX idx_line_items_quote_id ON line_items(quote_id)');
    await db.execute('CREATE INDEX idx_quotes_created_at ON quotes(created_at DESC)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE quotes ADD COLUMN vat_rate REAL DEFAULT 20.0');
    }
  }

  // ============ QUOTE METHODS ============

  Future<int> insertQuote(Quote quote) async {
    final db = await database;
    
    // Убедимся, что updated_at актуален
    final quoteToInsert = quote.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final id = await db.insert('quotes', quoteToInsert.toMap());
    return id;
  }

  Future<List<Quote>> getAllQuotes() async {
    final db = await database;
    final maps = await db.query(
      'quotes',
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Quote.fromMap(maps[i]);
    });
  }

  Future<Quote?> getQuote(int id) async {
    final db = await database;
    final maps = await db.query(
      'quotes',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Quote.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateQuote(Quote quote) async {
    final db = await database;
    
    final quoteToUpdate = quote.copyWith(
      updatedAt: DateTime.now(),
    );
    
    return await db.update(
      'quotes',
      quoteToUpdate.toMap(),
      where: 'id = ?',
      whereArgs: [quote.id],
    );
  }

  Future<int> deleteQuote(int id) async {
    final db = await database;
    
    // Удаляем связанные позиции (CASCADE тоже сработает, но на всякий случай)
    await db.delete(
      'line_items',
      where: 'quote_id = ?',
      whereArgs: [id],
    );
    
    return await db.delete(
      'quotes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateQuoteTotal(int quoteId) async {
    final db = await database;
    
    // Получаем сумму всех позиций
    final result = await db.rawQuery('''
      SELECT SUM(total) as sum_total 
      FROM line_items 
      WHERE quote_id = ?
    ''', [quoteId]);
    
    final total = result.first['sum_total'] as double? ?? 0.0;
    
    // Обновляем total в quote
    await db.update(
      'quotes',
      {'total': total, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [quoteId],
    );
  }

  // ============ LINE ITEM METHODS ============

  Future<int> insertLineItem(LineItem item) async {
    final db = await database;
    
    final id = await db.insert('line_items', item.toMap());
    
    // Обновляем общую сумму КП
    await updateQuoteTotal(item.quoteId);
    
    return id;
  }

  Future<List<LineItem>> getLineItemsForQuote(int quoteId) async {
    final db = await database;
    final maps = await db.query(
      'line_items',
      where: 'quote_id = ?',
      whereArgs: [quoteId],
      orderBy: 'sort_order ASC, created_at ASC',
    );
    
    return List.generate(maps.length, (i) {
      return LineItem.fromMap(maps[i]);
    });
  }

  Future<int> updateLineItem(LineItem item) async {
    final db = await database;
    
    final result = await db.update(
      'line_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    
    // Обновляем общую сумму КП
    await updateQuoteTotal(item.quoteId);
    
    return result;
  }

  Future<int> deleteLineItem(int id) async {
    final db = await database;
    
    // Сначала получаем quote_id для обновления total
    final item = await getLineItem(id);
    if (item == null) return 0;
    
    final result = await db.delete(
      'line_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Обновляем общую сумму КП
    await updateQuoteTotal(item.quoteId);
    
    return result;
  }

  Future<LineItem?> getLineItem(int id) async {
    final db = await database;
    final maps = await db.query(
      'line_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return LineItem.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteAllLineItemsForQuote(int quoteId) async {
    final db = await database;
    final result = await db.delete(
      'line_items',
      where: 'quote_id = ?',
      whereArgs: [quoteId],
    );
    
    // Обновляем общую сумму КП
    await updateQuoteTotal(quoteId);
    
    return result;
  }

  // ============ UTILITY METHODS ============

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('line_items');
    await db.delete('quotes');
  }

  Future<int> getQuoteCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM quotes');
    return result.first['count'] as int? ?? 0;
  }

  Future<List<Quote>> searchQuotes(String query) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT * FROM quotes 
      WHERE client_name LIKE ? 
         OR client_phone LIKE ? 
         OR object_address LIKE ?
         OR notes LIKE ?
      ORDER BY created_at DESC
    ''', ['%$query%', '%$query%', '%$query%', '%$query%']);
    
    return List.generate(maps.length, (i) {
      return Quote.fromMap(maps[i]);
    });
  }

  Future<List<Quote>> getQuotesByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      'quotes',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Quote.fromMap(maps[i]);
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
