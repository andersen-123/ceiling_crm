import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/models/company_profile.dart';

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
    final path = join(await getDatabasesPath(), 'ceiling_crm.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Таблица коммерческих предложений
    await db.execute('''
      CREATE TABLE quotes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientName TEXT NOT NULL,
        clientPhone TEXT,
        clientAddress TEXT,
        notes TEXT,
        totalAmount REAL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');

    // Таблица позиций
    await db.execute('''
      CREATE TABLE line_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quoteId INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        unitPrice REAL NOT NULL,
        quantity INTEGER NOT NULL,
        unit TEXT DEFAULT 'шт.',
        FOREIGN KEY (quoteId) REFERENCES quotes(id) ON DELETE CASCADE
      )
    ''');

    // Таблица профиля компании
    await db.execute('''
      CREATE TABLE company_profile(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        companyName TEXT,
        address TEXT,
        phone TEXT,
        email TEXT,
        website TEXT,
        bankDetails TEXT,
        directorName TEXT
      )
    ''');

    // Добавляем запись по умолчанию
    await db.insert('company_profile', CompanyProfile.defaultProfile().toMap());
  }

  // ========== CRUD для Quotes ==========
  Future<int> insertQuote(Quote quote) async {
    final db = await database;
    quote.id = await db.insert('quotes', quote.toMap());
    
    // Сохраняем все позиции
    for (var item in quote.items) {
      item.quoteId = quote.id!;
      await db.insert('line_items', item.toMap());
    }
    
    return quote.id!;
  }

  Future<List<Quote>> getAllQuotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('quotes', orderBy: 'createdAt DESC');
    
    final List<Quote> quotes = [];
    for (var map in maps) {
      final quote = Quote.fromMap(map);
      
      // Загружаем позиции для этого КП
      final items = await getLineItemsForQuote(quote.id!);
      quote.items.addAll(items);
      
      quotes.add(quote);
    }
    
    return quotes;
  }

  Future<Quote?> getQuoteById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quotes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    
    final quote = Quote.fromMap(maps.first);
    final items = await getLineItemsForQuote(id);
    quote.items.addAll(items);
    
    return quote;
  }

  Future<int> updateQuote(Quote quote) async {
    final db = await database;
    
    // Обновляем КП
    final result = await db.update(
      'quotes',
      quote.toMap(),
      where: 'id = ?',
      whereArgs: [quote.id],
    );
    
    // Удаляем старые позиции и добавляем новые
    await db.delete('line_items', where: 'quoteId = ?', whereArgs: [quote.id]);
    
    for (var item in quote.items) {
      item.quoteId = quote.id!;
      await db.insert('line_items', item.toMap());
    }
    
    return result;
  }

  Future<int> deleteQuote(int id) async {
    final db = await database;
    return await db.delete('quotes', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD для LineItems ==========
  Future<List<LineItem>> getLineItemsForQuote(int quoteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'line_items',
      where: 'quoteId = ?',
      whereArgs: [quoteId],
    );
    
    return List.generate(maps.length, (i) => LineItem.fromMap(maps[i]));
  }

  Future<int> insertLineItem(LineItem item) async {
    final db = await database;
    return await db.insert('line_items', item.toMap());
  }

  // ========== Company Profile ==========
  Future<CompanyProfile> getCompanyProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('company_profile');
    
    if (maps.isEmpty) {
      final defaultProfile = CompanyProfile.defaultProfile();
      await db.insert('company_profile', defaultProfile.toMap());
      return defaultProfile;
    }
    
    return CompanyProfile.fromMap(maps.first);
  }

  Future<int> updateCompanyProfile(CompanyProfile profile) async {
    final db = await database;
    return await db.update(
      'company_profile',
      profile.toMap(),
      where: 'id = 1',
    );
  }

  // ========== Утилиты ==========
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
