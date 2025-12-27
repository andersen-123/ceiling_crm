// lib/services/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/quote.dart';

class DatabaseHelper {
  static const _databaseName = 'ceiling_crm.db';
  static const _databaseVersion = 1;
  
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE quotes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientName TEXT NOT NULL,
        address TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        notes TEXT,
        totalAmount REAL DEFAULT 0,
        positions TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE company_profile (
        id INTEGER PRIMARY KEY,
        companyName TEXT,
        address TEXT,
        phone TEXT,
        email TEXT,
        inn TEXT,
        bankDetails TEXT
      )
    ''');
  }
  
  // CRUD операции для Quote
  Future<int> saveQuote(Quote quote) async {
    final db = await database;
    
    final quoteMap = quote.toMap();
    
    if (quote.id == null) {
      // Вставка новой записи
      return await db.insert('quotes', quoteMap);
    } else {
      // Обновление существующей записи
      return await db.update(
        'quotes',
        quoteMap,
        where: 'id = ?',
        whereArgs: [quote.id],
      );
    }
  }
  
  Future<List<Quote>> getAllProposals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('quotes', orderBy: 'createdAt DESC');
    
    return List.generate(maps.length, (i) {
      return Quote.fromMap(maps[i]);
    });
  }
  
  Future<Quote?> getProposal(int id) async {
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
  
  Future<int> deleteProposal(int id) async {
    final db = await database;
    return await db.delete(
      'quotes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Закрытие базы данных (для тестов)
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
