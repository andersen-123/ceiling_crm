import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/company_profile.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
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
    // Таблица quotes с ВСЕМИ полями
    await db.execute('''
      CREATE TABLE quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_name TEXT NOT NULL,
        client_email TEXT,
        client_phone TEXT,
        client_address TEXT,
        project_name TEXT,
        project_description TEXT,
        total_amount REAL NOT NULL DEFAULT 0,
        status TEXT DEFAULT 'черновик',
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Таблица line_items с ВСЕМИ полями
    await db.execute('''
      CREATE TABLE line_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 1,
        price REAL NOT NULL DEFAULT 0,
        unit TEXT DEFAULT 'шт',
        name TEXT,
        FOREIGN KEY (quote_id) REFERENCES quotes (id) ON DELETE CASCADE
      )
    ''');

    // Таблица company_profile с ВСЕМИ полями
    await db.execute('''
      CREATE TABLE company_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL DEFAULT 'Моя компания',
        email TEXT,
        phone TEXT,
        address TEXT,
        website TEXT,
        tax_id TEXT,
        logo_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Инициализируем профиль компании
    final defaultProfile = CompanyProfile(
      id: 1,
      name: 'Моя компания',
      email: '',
      phone: '',
      address: '',
      website: '',
      taxId: '',
      logoPath: '',
      createdAt: DateTime.now(),
    );
    
    await db.insert('company_profile', defaultProfile.toMap());
  }

  // ========== CRUD ДЛЯ QUOTE ==========
  Future<int> insertQuote(Quote quote) async {
    final db = await database;
    return await db.insert('quotes', quote.toMap());
  }

  Future<List<Quote>> getAllQuotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quotes',
      orderBy: 'created_at DESC'
    );
    return List.generate(maps.length, (i) {
      return Quote.fromMap(maps[i]);
    });
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

  // ========== CRUD ДЛЯ LINE ITEM ==========
  Future<int> insertLineItem(LineItem item) async {
    final db = await database;
    return await db.insert('line_items', item.toMap());
  }

  Future<List<LineItem>> getLineItemsForQuote(int quoteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'line_items',
      where: 'quote_id = ?',
      whereArgs: [quoteId],
      orderBy: 'id',
    );
    return List.generate(maps.length, (i) {
      return LineItem.fromMap(maps[i]);
    });
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

  Future<int> deleteLineItemsForQuote(int quoteId) async {
    final db = await database;
    return await db.delete(
      'line_items',
      where: 'quote_id = ?',
      whereArgs: [quoteId],
    );
  }

  // ========== COMPANY PROFILE ==========
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
    final List<Map<String, dynamic>> maps = await db.query('company_profile');
    if (maps.isNotEmpty) {
      return CompanyProfile.fromMap(maps.first);
    }
    return null;
  }

  // ========== ТЕСТОВЫЕ ДАННЫЕ ==========
  Future<void> createTestData() async {
    try {
      print('🔄 Начинаю создание тестовых данных...');
      
      // 1. Создаем тестовое КП
      final quote = Quote(
        clientName: 'Тестовый клиент',
        clientEmail: 'test@example.com',
        clientPhone: '+7 (999) 123-45-67',
        clientAddress: 'г. Москва, ул. Тестовая, д. 1',
        projectName: 'Натяжные потолки в 3-х комнатной квартире',
        projectDescription: 'Установка глянцевых потолков в зале и спальнях',
        totalAmount: 0.0,
        status: 'черновик',
        notes: 'Тестовое КП для проверки',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('📝 Создаю КП...');
      final quoteId = await insertQuote(quote);
      print('✅ КП создано с ID: $quoteId');

      // 2. Создаем тестовые позиции
      final testItems = [
        LineItem(
          quoteId: quoteId,
          description: 'Натяжной потолок ПВХ глянцевый (Германия)',
          quantity: 25.5,
          price: 610.0,
          unit: 'м²',
          name: 'Потолок глянцевый',
        ),
        LineItem(
          quoteId: quoteId,
          description: 'Точечный светильник LED (хром)',
          quantity: 8.0,
          price: 450.0,
          unit: 'шт',
          name: 'Светильник LED',
        ),
        LineItem(
          quoteId: quoteId,
          description: 'Монтаж светильника (проход через полотно)',
          quantity: 8.0,
          price: 300.0,
          unit: 'шт',
          name: 'Монтаж светильника',
        ),
      ];

      print('📦 Добавляю позиции...');
      for (final item in testItems) {
        await insertLineItem(item);
      }
      print('✅ Позиции добавлены');

      // 3. Рассчитываем и обновляем общую сумму
      final items = await getLineItemsForQuote(quoteId);
      double total = 0;
      for (final item in items) {
        total += (item.quantity * item.price);
      }
      
      print('💰 Рассчитываю сумму: $total руб.');
      
      final updatedQuote = Quote(
        id: quoteId,
        clientName: quote.clientName,
        clientEmail: quote.clientEmail,
        clientPhone: quote.clientPhone,
        clientAddress: quote.clientAddress,
        projectName: quote.projectName,
        projectDescription: quote.projectDescription,
        totalAmount: total,
        status: quote.status,
        notes: quote.notes,
        createdAt: quote.createdAt,
        updatedAt: DateTime.now(),
      );

      await updateQuote(updatedQuote);
      print('🎉 Тестовые данные успешно созданы!');

    } catch (e) {
      print('❌ Ошибка создания тестовых данных: $e');
      rethrow;
    }
  }

  // ========== ЭКСПОРТ/ИМПОРТ ==========
  Future<File> exportDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final source = File(join(dbPath, 'ceiling_crm.db'));
      
      if (await source.exists()) {
        print('📁 Файл базы найден: ${source.path}');
        return source;
      } else {
        throw Exception('Файл базы данных не найден по пути: ${source.path}');
      }
    } catch (e) {
      print('❌ Ошибка экспорта: $e');
      rethrow;
    }
  }

  Future<void> importDatabase(File sourceFile) async {
    try {
      if (!await sourceFile.exists()) {
        throw Exception('Исходный файл не существует');
      }

      final dbPath = await getDatabasesPath();
      final destination = File(join(dbPath, 'ceiling_crm.db'));
      
      print('🔄 Начинаю импорт базы...');
      print('📥 Источник: ${sourceFile.path}');
      print('📤 Назначение: ${destination.path}');

      // Закрываем текущее соединение
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Копируем файл
      await sourceFile.copy(destination.path);
      
      print('✅ Файл скопирован успешно');
      
      // Переоткрываем базу
      await database;
      
      print('🎉 Импорт базы завершен успешно!');

    } catch (e) {
      print('❌ Ошибка импорта: $e');
      rethrow;
    }
  }
}
