import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company_profile.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  
  factory DatabaseHelper() {
    return _instance;
  }
  
  DatabaseHelper._internal();
  
  static Database? _database;

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
    // Таблица коммерческих предложений
    await db.execute('''
      CREATE TABLE quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_name TEXT NOT NULL,
        client_email TEXT,
        client_phone TEXT,
        client_address TEXT,
        project_name TEXT,
        project_description TEXT,
        total_amount REAL NOT NULL,
        status TEXT DEFAULT 'черновик',
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Таблица позиций в КП
    await db.execute('''
      CREATE TABLE line_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        quantity REAL NOT NULL,
        price REAL NOT NULL,
        unit TEXT DEFAULT 'шт',
        name TEXT,
        FOREIGN KEY (quote_id) REFERENCES quotes (id) ON DELETE CASCADE
      )
    ''');

    // Таблица профиля компании
    await db.execute('''
      CREATE TABLE company_profile (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT,
        website TEXT,
        tax_id TEXT,
        logo_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Вставляем профиль компании по умолчанию
    final defaultProfile = CompanyProfile(
      id: 1,
      name: 'Ваша компания',
      email: 'info@company.com',
      phone: '+7 (999) 123-45-67',
      address: 'г. Москва, ул. Примерная, д. 1',
      website: 'www.company.com',
      taxId: '1234567890',
      logoPath: '',
      createdAt: DateTime.now(),
    );

    await db.insert('company_profile', defaultProfile.toMap());
  }

  // CRUD для Quote
  Future<int> insertQuote(Quote quote) async {
    final db = await database;
    return await db.insert('quotes', quote.toMap());
  }

  Future<List<Quote>> getAllQuotes() async {
    final db = await database;
    final maps = await db.query('quotes', orderBy: 'created_at DESC');
    return maps.map((map) => Quote.fromMap(map)).toList();
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

  // CRUD для LineItem
  Future<int> insertLineItem(LineItem item) async {
    final db = await database;
    return await db.insert('line_items', item.toMap());
  }

  Future<List<LineItem>> getLineItemsForQuote(int quoteId) async {
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
    return await db.delete(
      'line_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CompanyProfile
  Future<int> saveCompanyProfile(CompanyProfile profile) async {
    final db = await database;
    return await db.insert(
      'company_profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<CompanyProfile?> getCompanyProfile() async {
    final db = await database;
    final maps = await db.query(
      'company_profile',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (maps.isNotEmpty) {
      return CompanyProfile.fromMap(maps.first);
    }
    return null;
  }

  // Резервное копирование
  Future<File> exportDatabase() async {
    final dbPath = await getDatabasesPath();
    final source = File(join(dbPath, 'ceiling_crm.db'));
    final tempDir = await getTemporaryDirectory();
    final destination = File(join(tempDir.path, 'ceiling_crm_backup_${DateTime.now().millisecondsSinceEpoch}.db'));
    
    if (await source.exists()) {
      await source.copy(destination.path);
    }
    
    return destination;
  }

  Future<void> importDatabase(File sourceFile) async {
    final dbPath = await getDatabasesPath();
    final destination = File(join(dbPath, 'ceiling_crm.db'));
    
    if (await sourceFile.exists()) {
      await sourceFile.copy(destination.path);
    }
  }

  // Тестовые данные
  Future<void> createTestData() async {
    final quote = Quote(
      clientName: 'Тестовый клиент',
      clientEmail: 'test@example.com',
      clientPhone: '+7 (999) 123-45-67',
      clientAddress: 'г. Москва, ул. Тестовая, д. 1',
      projectName: 'Тестовый проект',
      projectDescription: 'Натяжные потолки в квартире',
      totalAmount: 25000.0,
      status: 'черновик',
      notes: 'Тестовое КП',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final quoteId = await insertQuote(quote);
    
    final items = [
      LineItem(
        quoteId: quoteId,
        description: 'Натяжной потолок глянцевый',
        quantity: 20.0,
        price: 850.0,
        unit: 'м²',
        name: 'Потолок глянцевый',
      ),
      LineItem(
        quoteId: quoteId,
        description: 'Монтаж светильников',
        quantity: 8.0,
        price: 500.0,
        unit: 'шт',
        name: 'Светильники',
      ),
      LineItem(
        quoteId: quoteId,
        description: 'Демонтаж старого потолка',
        quantity: 1.0,
        price: 3000.0,
        unit: 'комплект',
        name: 'Демонтаж',
      ),
    ];

    for (final item in items) {
      await insertLineItem(item);
    }
  }
}
