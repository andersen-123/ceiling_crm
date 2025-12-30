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
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'ceiling_crm.db');
    return await openDatabase(path, version: 3, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _insertDefaultCompanyProfile(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE line_items ADD COLUMN price_per_unit REAL');
      await db.execute('UPDATE line_items SET price_per_unit = price');
      await db.execute('ALTER TABLE line_items DROP COLUMN price');
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        client_name TEXT NOT NULL,
        client_email TEXT,
        client_phone TEXT,
        client_address TEXT,
        project_name TEXT,
        status TEXT DEFAULT 'черновик',
        total_amount REAL DEFAULT 0,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS line_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        price_per_unit REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (quote_id) REFERENCES quotes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS company_profiles (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        company_name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        website TEXT,
        inn TEXT,
        logo_path TEXT
      )
    ''');
  }

  Future<void> _insertDefaultCompanyProfile(Database db) async {
    await db.insert('company_profiles', {
      'id': 1,
      'company_name': 'Моя компания',
      'email': 'info@company.com',
      'phone': '+7 (999) 123-45-67',
      'address': 'г. Москва, ул. Примерная, д. 1',
      'inn': '1234567890',
    });
  }

  Future<Quote> createQuote(Quote quote) async {
    final db = await database;
    return await db.transaction((txn) async {
      final quoteId = await txn.insert('quotes', quote.toMap());
      for (final item in quote.items) {
        await txn.insert('line_items', {
          'quote_id': quoteId,
          'name': item.name,
          'description': item.description,
          'quantity': item.quantity,
          'unit': item.unit,
          'price_per_unit': item.pricePerUnit,
          'total': item.total,
        });
      }
      return await getQuote(quoteId)!;
    });
  }

  Future<List<Quote>> getAllQuotes() async {
    final db = await database;
    final quoteMaps = await db.query('quotes', orderBy: 'updated_at DESC');
    final quotes = <Quote>[];
    for (final map in quoteMaps) {
      final quoteId = map['id'] as int;
      final items = await getLineItemsForQuote(quoteId);
      quotes.add(Quote.fromMap(map, items: items));
    }
    return quotes;
  }

  Future<Quote?> getQuote(int id) async {
    final db = await database;
    final quoteMaps = await db.query('quotes', where: 'id = ?', whereArgs: [id]);
    if (quoteMaps.isEmpty) return null;
    final items = await getLineItemsForQuote(id);
    return Quote.fromMap(quoteMaps.first, items: items);
  }

  Future<List<LineItem>> getLineItemsForQuote(int quoteId) async {
    final db = await database;
    final maps = await db.query('line_items', where: 'quote_id = ?', whereArgs: [quoteId]);
    return maps.map((map) => LineItem.fromMap(map)).toList();
  }

  Future<void> createTestData() async {
    final testQuote = Quote(
      title: 'Тестовое КП #1',
      customerName: 'ООО "Тест"',
      customerPhone: '+7 (999) 123-45-67',
      projectNameField: 'Офисное помещение',
      items: [
        LineItem.quick(name: 'Натяжной потолок матовый', quantity: 25.0, unit: 'м²', pricePerUnit: 400.0),
        LineItem.quick(name: 'Точечные светильники', quantity: 12.0, unit: 'шт', pricePerUnit: 300.0),
        LineItem.quick(name: 'Светодиодная лента', quantity: 20.0, unit: 'м.п.', pricePerUnit: 350.0),
      ],
      date: DateTime.now(),
    );
    await createQuote(testQuote);
  }
}
