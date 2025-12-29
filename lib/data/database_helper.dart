import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company_profile.dart';

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
    final String path = join(await getDatabasesPath(), 'ceiling_crm.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Таблица коммерческих предложений
    await db.execute('''
      CREATE TABLE quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        email TEXT,
        total_amount REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Таблица позиций (пунктов) в КП
    await db.execute('''
      CREATE TABLE line_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        quantity INTEGER DEFAULT 1,
        price_per_unit REAL NOT NULL,
        unit TEXT,
        total REAL NOT NULL,
        FOREIGN KEY (quote_id) REFERENCES quotes (id) ON DELETE CASCADE
      )
    ''');

    // Таблица профиля компании (единственная запись)
    await db.execute('''
      CREATE TABLE company_profiles (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        company_name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        email TEXT,
        website TEXT,
        logo_path TEXT,
        tax_number TEXT,
        bank_details TEXT
      )
    ''');

    // Вставляем профиль компании по умолчанию
    await db.insert('company_profiles', {
      'id': 1,
      'company_name': 'Моя компания',
      'address': 'г. Москва, ул. Примерная, д. 1',
      'phone': '+7 (999) 123-45-67',
      'email': 'info@company.com',
      'website': 'www.company.com',
      'tax_number': 'ИНН 1234567890',
      'bank_details': 'Банк: Пример Банк\nР/с: 40702810123456789012\nК/с: 30101810123456789012\nБИК: 044525123'
    });
  }

  // ========== CRUD для Quote ==========
  
  Future<int> insertQuote(Quote quote) async {
    final db = await database;
    return await db.insert('quotes', quote.toMap());
  }

  Future<List<Quote>> getAllQuotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quotes',
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Quote.fromMap(maps[i]));
  }

  Future<Quote?> getQuote(int id) async {
    final db = await database;
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
    return await db.delete(
      'quotes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== CRUD для LineItem ==========
  
  Future<List<LineItem>> getLineItemsForQuote(int quoteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'line_items',
      where: 'quote_id = ?',
      whereArgs: [quoteId],
      orderBy: 'id',
    );
    return List.generate(maps.length, (i) => LineItem.fromMap(maps[i]));
  }

  Future<void> updateQuoteWithItems(Quote quote, List<LineItem> items) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // 1. Обновляем сам квоут
      await txn.update(
        'quotes',
        quote.toMap(),
        where: 'id = ?',
        whereArgs: [quote.id],
      );
      
      // 2. Удаляем старые позиции
      await txn.delete(
        'line_items', 
        where: 'quote_id = ?', 
        whereArgs: [quote.id],
      );
      
      // 3. Добавляем новые позиции
      for (final item in items) {
        await txn.insert(
          'line_items',
          item.copyWith(quoteId: quote.id).toMap(),
        );
      }
    });
  }

  // ========== CRUD для CompanyProfile ==========
  
  Future<CompanyProfile?> getCompanyProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'company_profiles',
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return CompanyProfile.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCompanyProfile(CompanyProfile profile) async {
    final db = await database;
    return await db.update(
      'company_profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
