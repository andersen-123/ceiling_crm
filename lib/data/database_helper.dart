// Главный класс для работы с локальной базой данных SQLite.
// Реализует singleton-паттерн для безопасного доступа к БД.
// Управляет созданием таблиц, миграциями и всеми операциями с данными.

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company_profile.dart';

class DatabaseHelper {
  // Singleton-экземпляр
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // База данных
  static Database? _database;

  // Константы для имен таблиц и версии БД
  static const String _dbName = 'ceiling_crm.db';
  static const int _dbVersion = 1;
  // В разделе констант добавьте:
  static const String tableTemplates = 'templates';

  // Названия таблиц
  static const String tableQuotes = 'quotes';
  static const String tableLineItems = 'line_items';
  static const String tableCompanies = 'companies';
  static const String tableSettings = 'settings';

  // Получение экземпляра базы данных (с ленивой инициализацией)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Инициализация базы данных: создание файла и таблиц
  Future<Database> _initDatabase() async {
    final String dbPath = await getDatabasesPath();
    final String path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onConfigure: (db) async {
        // Включаем поддержку внешних ключей
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // Создание всех таблиц (выполняется при первом запуске приложения)
  Future<void> _createTables(Database db, int version) async {
    // Таблица companies (данные компании)
    await db.execute('''
      CREATE TABLE $tableCompanies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        website TEXT,
        address TEXT,
        logo_path TEXT,
        footer_note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Таблица quotes (коммерческие предложения)
    await db.execute('''
      CREATE TABLE $tableQuotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        customer_email TEXT,
        object_name TEXT,
        address TEXT,
        area_s REAL,
        perimeter_p REAL,
        height_h REAL,
        ceiling_system TEXT,
        status TEXT NOT NULL DEFAULT 'draft',
        payment_terms TEXT,
        installation_terms TEXT,
        notes TEXT,
        currency_code TEXT NOT NULL DEFAULT 'RUB',
        subtotal_work REAL NOT NULL DEFAULT 0,
        subtotal_equipment REAL NOT NULL DEFAULT 0,
        total_amount REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (company_id) REFERENCES $tableCompanies(id)
      )
    ''');

    // Таблица line_items (позиции работ и оборудования)
    await db.execute('''
      CREATE TABLE $tableLineItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        section TEXT NOT NULL,
        description TEXT NOT NULL,
        unit TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 0,
        price REAL NOT NULL DEFAULT 0,
        amount REAL NOT NULL DEFAULT 0,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (quote_id) REFERENCES $tableQuotes(id) ON DELETE CASCADE
      )
    ''');

    // Таблица settings (настройки приложения)
    await db.execute('''
      CREATE TABLE $tableSettings (
        setting_key TEXT PRIMARY KEY,
        setting_value TEXT NOT NULL
      )
    ''');

    // Таблица templates (шаблоны условий оплаты и работ)
    await db.execute('''
      CREATE TABLE $tableTemplates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Индекс для поиска по типу
    await db.execute('''
      CREATE INDEX idx_templates_type 
      ON $tableTemplates(type)
    ''');

    // Создаем индексы для ускорения поиска и фильтрации
    await db.execute('''
      CREATE INDEX idx_quotes_status 
      ON $tableQuotes(status)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_quotes_customer 
      ON $tableQuotes(customer_name)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_line_items_quote_id 
      ON $tableLineItems(quote_id)
    ''');
    
    // Вставляем запись компании по умолчанию
    final defaultCompany = CompanyProfile(
      name: 'Моя компания',
      phone: '+7 (999) 123-45-67',
      email: 'info@example.com',
      address: 'г. Москва, ул. Примерная, д. 1',
      footerNote: 'Спасибо за выбор нашей компании!',
    );
    
    await insertCompany(defaultCompany);
    
    // Вставляем настройки по умолчанию
    await db.insert(tableSettings, {
      'setting_key': 'currency_code',
      'setting_value': 'RUB'
    });
    
    await db.insert(tableSettings, {
      'setting_key': 'default_company_id',
      'setting_value': '1'
    });
  }

  // ==================== CRUD-операции для Quote ====================

  // Вставка нового коммерческого предложения
  Future<int> insertQuote(Quote quote) async {
    final db = await database;
    
    // Устанавливаем временные метки
    final now = DateTime.now();
    quote = quote.copyWith(createdAt: now, updatedAt: now);
    
    final id = await db.insert(tableQuotes, quote.toMap());
    
    // Обновляем ID в объекте
    return id;
  }

  // Получение всех КП (без удаленных)
  Future<List<Quote>> getAllQuotes({bool includeDeleted = false}) async {
    final db = await database;
    final where = includeDeleted ? null : 'deleted_at IS NULL';
    final orderBy = 'created_at DESC';
    
    final List<Map<String, dynamic>> maps = await db.query(
      tableQuotes,
      where: where,
      orderBy: orderBy,
    );
    
    return List.generate(maps.length, (i) => Quote.fromMap(maps[i]));
  }

  // Получение КП по ID
  Future<Quote?> getQuoteById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableQuotes,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Quote.fromMap(maps.first);
    }
    return null;
  }

  // Обновление КП
  Future<int> updateQuote(Quote quote) async {
    final db = await database;
    
    // Обновляем временную метку
    quote = quote.copyWith(updatedAt: DateTime.now());
    
    return await db.update(
      tableQuotes,
      quote.toMap(),
      where: 'id = ?',
      whereArgs: [quote.id],
    );
  }

  // Мягкое удаление КП (устанавливаем deleted_at)
  Future<int> softDeleteQuote(int id) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    return await db.update(
      tableQuotes,
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Полное удаление КП (с каскадным удалением line_items)
  Future<int> deleteQuote(int id) async {
    final db = await database;
    return await db.delete(
      tableQuotes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== CRUD-операции для LineItem ====================

  // Вставка позиции
  Future<int> insertLineItem(LineItem item) async {
    final db = await database;
    
    // Устанавливаем временные метки
    final now = DateTime.now();
    item = item.copyWith(createdAt: now, updatedAt: now);
    
    // Рассчитываем сумму, если не указана
    if (item.amount != item.quantity * item.price) {
      item = item.copyWith(amount: item.quantity * item.price);
    }
    
    final id = await db.insert(tableLineItems, item.toMap());
    
    // После добавления позиции обновляем итоги в родительском Quote
    await _updateQuoteTotals(item.quoteId);
    
    return id;
  }

  // Получение всех позиций для конкретного КП
  Future<List<LineItem>> getLineItemsForQuote(int quoteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableLineItems,
      where: 'quote_id = ?',
      whereArgs: [quoteId],
      orderBy: 'section, position',
    );
    
    return List.generate(maps.length, (i) => LineItem.fromMap(maps[i]));
  }

  // Обновление позиции
  Future<int> updateLineItem(LineItem item) async {
    final db = await database;
    
    // Обновляем временную метку и пересчитываем сумму
    final now = DateTime.now();
    item = item.copyWith(
      updatedAt: now,
      amount: item.quantity * item.price,
    );
    
    final result = await db.update(
      tableLineItems,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
    
    // После обновления позиции обновляем итоги в родительском Quote
    if (result > 0) {
      await _updateQuoteTotals(item.quoteId);
    }
    
    return result;
  }

  // Удаление позиции
  Future<int> deleteLineItem(int id) async {
    final db = await database;
    
    // Сначала получаем quote_id для обновления итогов
    final item = await getLineItemById(id);
    if (item == null) return 0;
    
    final result = await db.delete(
      tableLineItems,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // После удаления позиции обновляем итоги в родительском Quote
    if (result > 0) {
      await _updateQuoteTotals(item.quoteId);
    }
    
    return result;
  }

  // Получение позиции по ID
  Future<LineItem?> getLineItemById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableLineItems,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return LineItem.fromMap(maps.first);
    }
    return null;
  }

  // Вспомогательный метод для обновления итогов в Quote
  Future<void> _updateQuoteTotals(int quoteId) async {
    final db = await database;
    
    // Рассчитываем суммы по разделам
    final totals = await db.rawQuery('''
      SELECT 
        section,
        SUM(amount) as total
      FROM $tableLineItems
      WHERE quote_id = ?
      GROUP BY section
    ''', [quoteId]);
    
    double subtotalWork = 0.0;
    double subtotalEquipment = 0.0;
    
    for (final row in totals) {
      if (row['section'] == 'work') {
        subtotalWork = (row['total'] as num).toDouble();
      } else if (row['section'] == 'equipment') {
        subtotalEquipment = (row['total'] as num).toDouble();
      }
    }
    
    final totalAmount = subtotalWork + subtotalEquipment;
    
    // Обновляем Quote
    await db.update(
      tableQuotes,
      {
        'subtotal_work': subtotalWork,
        'subtotal_equipment': subtotalEquipment,
        'total_amount': totalAmount,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [quoteId],
    );
  }

  // ==================== Операции для CompanyProfile ====================

  // Вставка или обновление компании
  Future<int> insertCompany(CompanyProfile company) async {
    final db = await database;
    
    // Устанавливаем временные метки
    final now = DateTime.now();
    company = company.copyWith(createdAt: now, updatedAt: now);
    
    if (company.id == null) {
      // Новая компания
      return await db.insert(tableCompanies, company.toMap());
    } else {
      // Обновление существующей
      return await db.update(
        tableCompanies,
        company.toMap(),
        where: 'id = ?',
        whereArgs: [company.id],
      );
    }
  }

  // Получение компании по ID
  Future<CompanyProfile?> getCompanyById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableCompanies,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return CompanyProfile.fromMap(maps.first);
    }
    return null;
  }

  // Получение первой (основной) компании
  Future<CompanyProfile?> getDefaultCompany() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableCompanies,
      orderBy: 'id',
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      return CompanyProfile.fromMap(maps.first);
    }
    return null;
  }

  // ==================== Операции для настроек ====================

  // Сохранение настройки
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      tableSettings,
      {
        'setting_key': key,
        'setting_value': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Получение настройки
  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableSettings,
      where: 'setting_key = ?',
      whereArgs: [key],
    );
    
    if (maps.isNotEmpty) {
      return maps.first['setting_value'] as String;
    }
    return null;
  }

  // ==================== Вспомогательные методы ====================

  // Закрытие базы данных
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // Удаление базы данных (для тестов или сброса)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    await deleteDatabase(path);
  }

  // Резервное копирование (экспорт файла БД)
  Future<String> exportDatabase() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _dbName);
  }
}
