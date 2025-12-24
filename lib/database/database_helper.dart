import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:ceiling_crm/models/estimate.dart';
import 'package:ceiling_crm/models/estimate_item.dart';
import 'package:ceiling_crm/models/project.dart';
import 'package:ceiling_crm/models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'ceiling_crm.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Таблица клиентов
    await db.execute('''
      CREATE TABLE clients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Таблица проектов
    await db.execute('''
      CREATE TABLE projects(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER,
        title TEXT NOT NULL,
        address TEXT,
        status TEXT NOT NULL,
        start_date TEXT,
        end_date TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        contract_sum REAL DEFAULT 0,
        prepayment_received REAL DEFAULT 0,
        total_expenses REAL DEFAULT 0,
        balance REAL DEFAULT 0,
        FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE SET NULL
      )
    ''');

    // Таблица транзакций
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        is_income INTEGER NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    // Таблица смет
    await db.execute('''
      CREATE TABLE estimates(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_name TEXT NOT NULL,
        address TEXT NOT NULL,
        area REAL NOT NULL,
        perimeter REAL NOT NULL,
        price_per_meter REAL NOT NULL,
        total_price REAL NOT NULL,
        created_date TEXT NOT NULL
      )
    ''');

    // Таблица элементов сметы
    await db.execute('''
      CREATE TABLE estimate_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        estimate_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        description TEXT,
        FOREIGN KEY (estimate_id) REFERENCES estimates (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Миграции базы данных при обновлении версии
  }

  // ============ МЕТОДЫ ДЛЯ РАБОТЫ С PROJECTS ============

  Future<int> insertProject(Project project) async {
    final db = await database;
    return await db.insert('projects', project.toMap());
  }

  Future<List<Project>> getAllProjects() async {
    final db = await database;
    final maps = await db.query('projects', orderBy: 'created_at DESC');
    return maps.map((map) => Project.fromMap(map)).toList();
  }

  Future<Project?> getProject(int id) async {
    final db = await database;
    final maps = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return Project.fromMap(maps.first);
  }

  Future<int> updateProject(Project project) async {
    final db = await database;
    return await db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> deleteProject(int id) async {
    final db = await database;
    return await db.delete(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ МЕТОДЫ ДЛЯ РАБОТЫ С TRANSACTIONS ============

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<Transaction>> getProjectTransactions(int projectId) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ МЕТОДЫ ДЛЯ РАБОТЫ С ESTIMATES ============

  Future<int> insertEstimate(Estimate estimate) async {
    final db = await database;
    return await db.insert('estimates', estimate.toMap());
  }

  Future<List<Estimate>> getAllEstimates() async {
    final db = await database;
    final maps = await db.query('estimates', orderBy: 'created_date DESC');
    return maps.map((map) => Estimate.fromMap(map)).toList();
  }

  Future<Estimate?> getEstimate(int id) async {
    final db = await database;
    final maps = await db.query(
      'estimates',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return Estimate.fromMap(maps.first);
  }

  Future<Estimate> getEstimateWithItems(int estimateId) async {
    final db = await database;
    
    // Получаем саму смету
    final estimateMaps = await db.query(
      'estimates',
      where: 'id = ?',
      whereArgs: [estimateId],
    );
    
    if (estimateMaps.isEmpty) {
      throw Exception('Estimate not found');
    }
    
    final estimate = Estimate.fromMap(estimateMaps.first);
    
    // Получаем элементы сметы
    final itemMaps = await db.query(
      'estimate_items',
      where: 'estimate_id = ?',
      whereArgs: [estimateId],
    );
    
    final items = itemMaps.map((map) => EstimateItem.fromMap(map)).toList();
    
    return estimate.copyWith(items: items);
  }

  Future<int> updateEstimate(Estimate estimate) async {
    final db = await database;
    return await db.update(
      'estimates',
      estimate.toMap(),
      where: 'id = ?',
      whereArgs: [estimate.id],
    );
  }

  Future<int> deleteEstimate(int id) async {
    final db = await database;
    return await db.delete(
      'estimates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ МЕТОДЫ ДЛЯ РАБОТЫ С ESTIMATE_ITEMS ============

  Future<int> insertEstimateItem(EstimateItem item) async {
    final db = await database;
    return await db.insert('estimate_items', item.toMap());
  }

  Future<List<EstimateItem>> getEstimateItems(int estimateId) async {
    final db = await database;
    final maps = await db.query(
      'estimate_items',
      where: 'estimate_id = ?',
      whereArgs: [estimateId],
    );
    return maps.map((map) => EstimateItem.fromMap(map)).toList();
  }

  Future<int> updateEstimateItem(EstimateItem item) async {
    final db = await database;
    return await db.update(
      'estimate_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteEstimateItem(int id) async {
    final db = await database;
    return await db.delete(
      'estimate_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllEstimateItems(int estimateId) async {
    final db = await database;
    await db.delete(
      'estimate_items',
      where: 'estimate_id = ?',
      whereArgs: [estimateId],
    );
  }

  // ============ СОХРАНЕНИЕ СМЕТЫ С ЭЛЕМЕНТАМИ ============

  Future<int> saveEstimateWithItems(Estimate estimate) async {
    final db = await database;
    
    // Начинаем транзакцию
    return await db.transaction((txn) async {
      int estimateId;
      
      // Сохраняем или обновляем смету
      if (estimate.id == null) {
        estimateId = await txn.insert('estimates', estimate.toMap());
      } else {
        await txn.update(
          'estimates',
          estimate.toMap(),
          where: 'id = ?',
          whereArgs: [estimate.id],
        );
        estimateId = estimate.id!;
        
        // Удаляем старые элементы
        await txn.delete(
          'estimate_items',
          where: 'estimate_id = ?',
          whereArgs: [estimateId],
        );
      }
      
      // Сохраняем элементы сметы
      for (var item in estimate.items) {
        final itemMap = item.toMap();
        itemMap['estimate_id'] = estimateId;
        await txn.insert('estimate_items', itemMap);
      }
      
      return estimateId;
    });
  }

  // ============ ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ============

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'ceiling_crm.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
