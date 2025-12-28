import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company_profile.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ceiling_crm.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Таблица quotes
    await db.execute('''
      CREATE TABLE quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        client_name TEXT NOT NULL,
        client_phone TEXT,
        client_email TEXT,
        client_address TEXT,
        created_at TEXT NOT NULL,
        valid_until TEXT,
        notes TEXT,
        total_price REAL NOT NULL,
        status TEXT DEFAULT 'draft',
        status_changed_at TEXT,
        status_comment TEXT
      )
    ''');

    // Таблица line_items
    await db.execute('''
      CREATE TABLE line_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        FOREIGN KEY (quote_id) REFERENCES quotes (id) ON DELETE CASCADE
      )
    ''');

    // Таблица company_profile
    await db.execute('''
      CREATE TABLE company_profile (
        id INTEGER PRIMARY KEY,
        company_name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        manager_name TEXT,
        position TEXT,
        vat_number TEXT,
        logo_path TEXT
      )
    ''');

    // Вставляем тестовый профиль компании
    await db.execute('''
      INSERT INTO company_profile (id, company_name, phone, email)
      VALUES (1, 'Ваша компания', '+7 (999) 123-45-67', 'info@company.ru')
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE quotes ADD COLUMN status TEXT DEFAULT "draft"');
      await db.execute('ALTER TABLE quotes ADD COLUMN status_changed_at TEXT');
      await db.execute('ALTER TABLE quotes ADD COLUMN status_comment TEXT');
    }
  }

  // ========== CRUD ДЛЯ QUOTES ==========

  Future<int> insertQuote(Quote quote) async {
    final db = await database;
    return await db.insert('quotes', quote.toMap());
  }

  Future<List<Quote>> getAllQuotes() async {
    final db = await database;
    final maps = await db.query('quotes', orderBy: 'created_at DESC');
    return maps.map((map) => Quote.fromMap(map)).toList();
  }

  Future<List<Quote>> getQuotesByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      'quotes',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Quote.fromMap(map)).toList();
  }

  Future<Quote?> getQuoteById(int id) async {
    final db = await database;
    final maps = await db.query(
      'quotes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return Quote.fromMap(maps.first);
    return null;
  }

  Future<int> updateQuote(Quote quote) async {
    final db = await database;
    return await db.update(
      'quotes',
      quote.toMap(),
      where: 'id = ?',
      whereArgs: [quote.id],
    );
  }

  Future<int> deleteQuote(int id) async {
    final db = await database;
    await db.delete('line_items', where: 'quote_id = ?', whereArgs: [id]);
    return await db.delete('quotes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Quote>> searchQuotes(String query) async {
    final db = await database;
    final maps = await db.query(
      'quotes',
      where: 'title LIKE ? OR client_name LIKE ? OR notes LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Quote.fromMap(map)).toList();
  }

  // ========== CRUD ДЛЯ LINE ITEMS ==========

  Future<int> insertLineItem(LineItem item) async {
    final db = await database;
    return await db.insert('line_items', item.toMap());
  }

  Future<List<LineItem>> getLineItemsByQuoteId(int quoteId) async {
    final db = await database;
    final maps = await db.query(
      'line_items',
      where: 'quote_id = ?',
      whereArgs: [quoteId],
      orderBy: 'id',
    );
    return maps.map((map) => LineItem.fromMap(map)).toList();
  }

  Future<int> updateLineItem(LineItem item) async {
    final db = await database;
    return await db.update(
      'line_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteLineItem(int id) async {
    final db = await database;
    return await db.delete('line_items', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD ДЛЯ COMPANY PROFILE ==========

  Future<CompanyProfile?> getCompanyProfile() async {
    final db = await database;
    final maps = await db.query('company_profile', where: 'id = 1');
    if (maps.isNotEmpty) return CompanyProfile.fromMap(maps.first);
    return null;
  }

  Future<int> updateCompanyProfile(CompanyProfile profile) async {
    final db = await database;
    
    // Создаем копию с правильным id
    final profileToUpdate = profile.copyWith(id: 1);
    
    return await db.update(
      'company_profile',
      profileToUpdate.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // ========== СТАТИСТИКА ==========

  Future<Map<String, int>> getQuotesStatistics() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT status, COUNT(*) as count 
      FROM quotes 
      GROUP BY status
    ''');
    
    final stats = <String, int>{};
    for (var map in maps) {
      stats[map['status'] as String] = map['count'] as int;
    }
    
    return stats;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
