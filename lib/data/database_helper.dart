// lib/data/database_helper.dart

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/quote.dart';
import '../models/line_item.dart';

class DatabaseHelper {
  // 1. Делаем класс Singleton (единственный экземпляр)
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // 2. Переменная для базы данных
  static Database? _database;

  // 3. Название базы данных и версия
  final String _databaseName = 'ceiling_crm.db';
  final int _databaseVersion = 1;

  // 4. Имена таблиц
  final String tableQuotes = 'quotes';
  final String tableLineItems = 'line_items';

  // 5. Получаем базу данных (создаём при первом обращении)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 6. Инициализация базы данных - создание таблиц
  Future<Database> _initDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // 7. SQL-скрипт для создания таблиц (важнейшая часть!)
  Future<void> _onCreate(Database db, int version) async {
    // Таблица quotes (коммерческие предложения)
    await db.execute('''
      CREATE TABLE $tableQuotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerName TEXT NOT NULL,
        customerPhone TEXT NOT NULL,
        address TEXT NOT NULL,
        quoteDate TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        prepayment REAL DEFAULT 0,
        status TEXT DEFAULT 'Черновик',
        notes TEXT DEFAULT ''
      )
    ''');

    // Таблица line_items (позиции в КП)
    await db.execute('''
      CREATE TABLE $tableLineItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quoteId INTEGER NOT NULL,
        section TEXT NOT NULL,
        description TEXT NOT NULL,
        unit TEXT NOT NULL,
        quantity REAL NOT NULL,
        unitPrice REAL NOT NULL,
        FOREIGN KEY (quoteId) REFERENCES $tableQuotes(id) ON DELETE CASCADE
      )
    ''');
  }

  // ================ МЕТОДЫ ДЛЯ РАБОТЫ С QUOTES (КП) ================

  // 1. Добавить новое КП
  Future<int> insertQuote(Quote quote) async {
    final db = await database;
    return await db.insert(tableQuotes, quote.toMap());
  }

  // 2. Получить все КП
  Future<List<Quote>> getAllQuotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableQuotes,
      orderBy: 'quoteDate DESC', // Сначала новые
    );
    return List.generate(maps.length, (i) => Quote.fromMap(maps[i]));
  }

  // 3. Получить одно КП по ID
  Future<Quote?> getQuoteById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableQuotes,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Quote.fromMap(maps.first);
    }
    return null;
  }

  // 4. Обновить КП
  Future<int> updateQuote(Quote quote) async {
    final db = await database;
    return await db.update(
      tableQuotes,
      quote.toMap(),
      where: 'id = ?',
      whereArgs: [quote.id],
    );
  }

  // 5. Удалить КП
  Future<int> deleteQuote(int id) async {
    final db = await database;
    return await db.delete(
      tableQuotes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================ МЕТОДЫ ДЛЯ РАБОТЫ С LINE ITEMS ================

  // 1. Добавить позицию
  Future<int> insertLineItem(LineItem item) async {
    final db = await database;
    return await db.insert(tableLineItems, item.toMap());
  }

  // 2. Получить все позиции для конкретного КП
  Future<List<LineItem>> getLineItemsForQuote(int quoteId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableLineItems,
      where: 'quoteId = ?',
      whereArgs: [quoteId],
      orderBy: 'section, id',
    );
    return List.generate(maps.length, (i) => LineItem.fromMap(maps[i]));
  }

  // 3. Обновить позицию
  Future<int> updateLineItem(LineItem item) async {
    final db = await database;
    return await db.update(
      tableLineItems,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // 4. Удалить позицию
  Future<int> deleteLineItem(int id) async {
    final db = await database;
    return await db.delete(
      tableLineItems,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 5. Удалить ВСЕ позиции для КП (при удалении самого КП)
  Future<int> deleteAllLineItemsForQuote(int quoteId) async {
    final db = await database;
    return await db.delete(
      tableLineItems,
      where: 'quoteId = ?',
      whereArgs: [quoteId],
    );
  }

  // ================ ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ================

  // Закрыть базу данных (для тестов или пересоздания)
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
