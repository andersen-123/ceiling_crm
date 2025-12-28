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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Таблица для коммерческих предложений
    await db.execute('''
      CREATE TABLE quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_name TEXT NOT NULL,
        client_phone TEXT,
        object_address TEXT,
        status TEXT NOT NULL DEFAULT 'draft',
        created_at TEXT NOT NULL,
        total REAL,
        vat_rate REAL,
        vat_amount REAL,
        total_with_vat REAL
      )
    ''');

    // Таблица для позиций (line items)
    await db.execute('''
      CREATE TABLE line_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        quantity REAL NOT NULL,
        total REAL,
        FOREIGN KEY (quote_id) REFERENCES quotes (id) ON DELETE CASCADE
      )
    ''');

    // Таблица для профиля компании
    await db.execute('''
      CREATE TABLE company_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_name TEXT NOT NULL,
        manager_name TEXT NOT NULL,
        position TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        website TEXT,
        vat_rate REAL DEFAULT 0,
        default_margin REAL DEFAULT 0,
        currency TEXT DEFAULT '₽'
      )
    ''');
  }

  // CRUD для Quote
  Future<int> insertQuote(Quote quote) async {
    final db = await instance.database;
    return await db.insert('quotes', quote.toMap());
  }

  Future<List<Quote>> getAllQuotes() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('quotes', orderBy: 'created_at DESC');
    return maps.map((map) => Quote.fromMap(map)).toList();
  }

  Future<Quote?> getQuoteById(int id) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
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
    final db = await instance.database;
    return await db.update(
      'quotes',
      quote.toMap(),
      where: 'id = ?',
      whereArgs: [quote.id],
    );
  }

  Future<int> deleteQuote(int id) async {
    final db = await instance.database;
    return await db.delete(
      'quotes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Метод для получения общей выручки (только принятые КП)
  Future<double> getTotalRevenue() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(total_with_vat) as revenue FROM quotes WHERE status = "accepted"'
    );
    final revenue = result.first['revenue'] as num?;
    return revenue?.toDouble() ?? 0.0;
  }

  // CRUD для LineItem
  Future<int> insertLineItem(LineItem item) async {
    final db = await instance.database;
    return await db.insert('line_items', item.toMap());
  }

  Future<List<LineItem>> getLineItems(int quoteId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'line_items',
      where: 'quote_id = ?',
      whereArgs: [quoteId],
    );
    return maps.map((map) => LineItem.fromMap(map)).toList();
  }

  Future<int> updateLineItem(LineItem item) async {
    final db = await instance.database;
    return await db.update(
      'line_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteLineItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'line_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD для CompanyProfile
  Future<int> insertCompanyProfile(CompanyProfile profile) async {
    final db = await instance.database;
    return await db.insert('company_profiles', profile.toMap());
  }

  Future<CompanyProfile?> getCompanyProfile() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('company_profiles');
    if (maps.isNotEmpty) {
      return CompanyProfile.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCompanyProfile(CompanyProfile profile) async {
    final db = await instance.database;
    // Если есть id, обновляем, иначе вставляем новый
    if (profile.id != null) {
      return await db.update(
        'company_profiles',
        profile.toMap(),
        where: 'id = ?',
        whereArgs: [profile.id],
      );
    } else {
      return await db.insert('company_profiles', profile.toMap());
    }
  }

  Future<int> deleteCompanyProfile(int id) async {
    final db = await instance.database;
    return await db.delete(
      'company_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Закрытие базы данных
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
