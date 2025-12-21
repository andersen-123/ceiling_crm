import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/estimate.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'ceiling_crm.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE estimates(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            total REAL
          )
        ''');
      },
    );
  }

  Future<int> insertEstimate(Estimate estimate) async {
    final dbClient = await db;
    return await dbClient.insert('estimates', estimate.toMap());
  }

  Future<List<Estimate>> getEstimates() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query('estimates');
    return List.generate(maps.length, (i) => Estimate.fromMap(maps[i]));
  }

  Future<int> updateEstimate(Estimate estimate) async {
    final dbClient = await db;
    return await dbClient.update(
      'estimates',
      estimate.toMap(),
      where: 'id = ?',
      whereArgs: [estimate.id],
    );
  }

  Future<int> deleteEstimate(int id) async {
    final dbClient = await db;
    return await dbClient.delete('estimates', where: 'id = ?', whereArgs: [id]);
  }
}
