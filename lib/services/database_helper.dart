import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:ceiling_crm/models/quote.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quotes.db');
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
    await db.execute('''
      CREATE TABLE quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientName TEXT NOT NULL,
        clientAddress TEXT NOT NULL,
        clientPhone TEXT NOT NULL,
        clientEmail TEXT,
        notes TEXT,
        items TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  // Создание нового КП
  Future<int> insertQuote(Quote quote) async {
    final db = await instance.database;
    return await db.insert('quotes', quote.toMap());
  }

  // Получение всех КП
  Future<List<Quote>> getAllQuotes() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quotes',
      orderBy: 'createdAt DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Quote.fromMap(maps[i]);
    });
  }

  // Получение одного КП по ID
  Future<Quote?> getQuote(int id) async {
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

  // Обновление КП
  Future<int> updateQuote(Quote quote) async {
    final db = await instance.database;
    return await db.update(
      'quotes',
      quote.toMap(),
      where: 'id = ?',
      whereArgs: [quote.id],
    );
  }

  // Удаление КП
  Future<int> deleteQuote(int id) async {
    final db = await instance.database;
    return await db.delete(
      'quotes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Закрытие базы данных
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
