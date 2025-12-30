import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company_profile.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {import 'package:sqflite/sqflite.dart';
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
    
    return await openDatabase(
      path,
      version: 3,  // ✅ Увеличена до 3
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _insertDefaultCompanyProfile(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE quotes RENAME TO quotes_old');
      await _createTables(db);
      await db.execute('''
        INSERT INTO quotes (id, client_name, client_email, client_phone, client_address, 
                           project_name, project_description, notes, status, total_amount, 
                           created_at, updated_at)
        SELECT id, client_name, email, phone, address, 'Проект', '', '', 'draft', 
               total_amount, created_at, updated_at 
        FROM quotes_old
      ''');
      await db.execute('DROP TABLE quotes_old');
    }
    if (oldVersion < 3) {
      // ✅ Миграция v2 → v3: line_items.price → price_per_unit
      await db.execute('ALTER TABLE line_items ADD COLUMN price_per_unit REAL');
      await db.execute('''
        UPDATE line_items SET price_per_unit = price WHERE price_per_unit IS NULL
      ''');
      await db.execute('ALTER TABLE line_items DROP COLUMN price');
      await db.execute('ALTER TABLE line_items ADD COLUMN total REAL');
      await db.execute('''
        UPDATE line_items SET total = price_per_unit * quantity
      ''');
    }
  }

  Future<void> _createTables(Database db) async {
    // ✅ Таблица quotes
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        client_name TEXT NOT NULL,
        client_email TEXT,
        client_phone TEXT,
        client_address TEXT,
        project_name TEXT,
        project_description TEXT,
        notes TEXT,
        status TEXT DEFAULT 'черновик',
        total_amount REAL DEFAULT 0,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // ✅ Таблица line_items - НОВАЯ СХЕМА
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
        FOREIGN KEY (quote_id) REFERENCES quotes (id) ON DELETE CASCADE
      )
    ''');

    // ✅ Таблица company_profiles
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
      'website': 'www.company.com',
      'inn': '1234567890',
      'logo_path': null,
    });
  }

  // ========== CRUD для Quote ==========
  
  Future<Quote> createQuote(Quote quote) async {
    final db = await database;
    return await db.transaction((txn) async {
      final quoteId = await txn.insert('quotes', quote.toMap());
      
      for (final item in quote.items) {
        await txn.insert('line_items', {
          ...item.toMap(),
          'quote_id': quoteId,
        });
      }
      
      return (await getQuote(quoteId))!;
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

  Future<int> updateQuote(Quote quote) async {
    final db = await database;
    return await db.update('quotes', quote.toMap(), where: 'id = ?', whereArgs: [quote.id]);
  }

  Future<int> deleteQuote(int id) async {
    final db = await database;
    return await db.delete('quotes', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD для LineItem ==========
  
  Future<List<LineItem>> getLineItemsForQuote(int quoteId) async {
    final db = await database;
    final maps = await db.query(
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
      await txn.update('quotes', quote.toMap(), where: 'id = ?', whereArgs: [quote.id]);
      
      await txn.delete('line_items', where: 'quote_id = ?', whereArgs: [quote.id]);
      
      for (final item in items) {
        await txn.insert('line_items', {
          ...item.toMap(),
          'quote_id': quote.id,
        });
      }
    });
  }

  // ========== CRUD для CompanyProfile ==========
  
  Future<CompanyProfile> getCompanyProfile() async {
    final db = await database;
    final maps = await db.query('company_profiles', limit: 1);
    
    if (maps.isNotEmpty) {
      return CompanyProfile.fromMap(maps.first);
    }
    throw Exception('Профиль компании не найден');
  }

  Future<int> updateCompanyProfile(CompanyProfile profile) async {
    final db = await database;
    return await db.update(
      'company_profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id ?? 1],
    );
  }

  Future<void> saveCompanyProfile(CompanyProfile profile) async {
    await updateCompanyProfile(profile);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // ✅ ИСПРАВЛЕННЫЕ ТЕСТОВЫЕ ДАННЫЕ
  Future<void> createTestData() async {
    try {
      final testQuote = Quote(
        title: 'Тестовое КП #1',
        customerName: 'ООО "Тест"',
        customerPhone: '+7 (999) 123-45-67',
        customerEmail: 'test@company.ru',
        customerAddress: 'г. Москва, ул. Тестовая, д. 1',
        projectName: 'Офисное помещение',
        status: 'черновик',
        items: [
          LineItem(
            quoteId: 0,  // Будет заменен на реальный ID
            name: 'Натяжной потолок матовый',
            quantity: 25.0,
            unit: 'м²',
            pricePerUnit: 400.0,
          ),
          LineItem(
            quoteId: 0,
            name: 'Точечные светильники',
            quantity: 12.0,
            unit: 'шт',
            pricePerUnit: 300.0,
          ),
          LineItem(
            quoteId: 0,
            name: 'Светодиодная лента',
            quantity: 20.0,
            unit: 'м.п.',
            pricePerUnit: 350.0,
          ),
        ],
        date: DateTime.now(),
      );
      
      await createQuote(testQuote);
      print('✅ Тестовые данные созданы');
    } catch (e) {
      print('❌ Ошибка создания тестовых данных: $e');
    }
  }
}

    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'ceiling_crm.db');
    
    return await openDatabase(
      path,
      version: 2,  // ← Увеличена версия для миграции
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,  // ← Добавлена миграция
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _insertDefaultCompanyProfile(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Миграция v1 → v2: исправляем поля таблицы quotes
      await db.execute('ALTER TABLE quotes RENAME TO quotes_old');
      await _createTables(db);
      
      // Переносим данные
      await db.execute('''
        INSERT INTO quotes (id, client_name, client_email, client_phone, client_address, 
                           project_name, project_description, notes, status, total_amount, 
                           created_at, updated_at)
        SELECT id, client_name, email, phone, address, 'Проект', '', '', 'draft', 
               total_amount, created_at, updated_at 
        FROM quotes_old
      ''');
      
      await db.execute('DROP TABLE quotes_old');
    }
  }

  Future<void> _createTables(Database db) async {
    // ✅ Таблица quotes - ПОЛНАЯ СХЕМА
    await db.execute('''
      CREATE TABLE quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_name TEXT NOT NULL,
        client_email TEXT,
        client_phone TEXT,
        client_address TEXT,
        project_name TEXT NOT NULL,
        project_description TEXT,
        notes TEXT,
        status TEXT DEFAULT 'draft',
        total_amount REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // ✅ Таблица line_items - исправлена
    await db.execute('''
      CREATE TABLE line_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (quote_id) REFERENCES quotes (id) ON DELETE CASCADE
      )
    ''');

    // ✅ Таблица company_profiles - полная схема
    await db.execute('''
      CREATE TABLE company_profiles (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        companyName TEXT NOT NULL,
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
      'companyName': 'Моя компания',
      'email': 'info@company.com',
      'phone': '+7 (999) 123-45-67',
      'address': 'г. Москва, ул. Примерная, д. 1',
      'website': 'www.company.com',
      'inn': '1234567890',
      'logo_path': null,
    });
  }

  // ========== 🚀 CRUD для Quote ==========
  
  /// ✅ НОВЫЙ: createQuote (полная транзакция с позициями)
  Future<Quote> createQuote(Quote quote) async {
    final db = await database;
    return await db.transaction((txn) async {
      // 1. Создаем quote
      final quoteId = await txn.insert('quotes', quote.toMap());
      
      // 2. Создаем позиции
      for (final item in quote.items) {
        await txn.insert('line_items', item.copyWith(quoteId: quoteId).toMap());
      }
      
      // 3. Возвращаем quote с ID
      return (await getQuote(quoteId))!;
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

  Future<int> updateQuote(Quote quote) async {
    final db = await database;
    return await db.update('quotes', quote.toMap(), where: 'id = ?', whereArgs: [quote.id]);
  }

  Future<int> deleteQuote(int id) async {
    final db = await database;
    return await db.delete('quotes', where: 'id = ?', whereArgs: [id]);
  }

  // ========== CRUD для LineItem ==========
  
  Future<List<LineItem>> getLineItemsForQuote(int quoteId) async {
    final db = await database;
    final maps = await db.query(
      'line_items',
      where: 'quote_id = ?',
      whereArgs: [quoteId],
      orderBy: 'id',
    );
    return List.generate(maps.length, (i) => LineItem.fromMap(maps[i]));
  }

  /// ✅ updateQuoteWithItems (полная замена quote + items)
  Future<void> updateQuoteWithItems(Quote quote, List<LineItem> items) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Обновляем quote
      await txn.update('quotes', quote.toMap(), where: 'id = ?', whereArgs: [quote.id]);
      
      // Удаляем старые items
      await txn.delete('line_items', where: 'quote_id = ?', whereArgs: [quote.id]);
      
      // Добавляем новые items
      for (final item in items) {
        await txn.insert('line_items', item.copyWith(quoteId: quote.id).toMap());
      }
    });
  }

  // ========== CRUD для CompanyProfile ==========
  
  Future<CompanyProfile> getCompanyProfile() async {
    final db = await database;
    final maps = await db.query('company_profiles', limit: 1);
    
    if (maps.isNotEmpty) {
      return CompanyProfile.fromMap(maps.first);
    }
    throw Exception('Профиль компании не найден');
  }

  Future<int> updateCompanyProfile(CompanyProfile profile) async {
    final db = await database;
    return await db.update(
      'company_profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id ?? 1],
    );
  }

  /// ✅ Alias для совместимости
  Future<void> saveCompanyProfile(CompanyProfile profile) async {
    await updateCompanyProfile(profile);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // ✅ Тестовые данные (совместимые с новой моделью)
  Future<void> createTestData() async {
    try {
      final testQuote = Quote(
        clientName: 'ООО "Тест"',
        projectName: 'Офисное помещение',
        clientAddress: 'г. Москва, ул. Тестовая, д. 1',
        clientPhone: '+7 (999) 123-45-67',
        clientEmail: 'test@company.ru',
        items: [
          LineItem(name: 'Натяжной потолок матовый', quantity: 25.0, unit: 'м²', price: 400.0),
          LineItem(name: 'Точечные светильники', quantity: 12.0, unit: 'шт', price: 300.0),
          LineItem(name: 'Светодиодная лента', quantity: 20.0, unit: 'м.п.', price: 350.0),
        ],
      );
      
      await createQuote(testQuote);
      print('✅ Тестовые данные созданы');
    } catch (e) {
      print('❌ Ошибка создания тестовых данных: $e');
    }
  }
}
