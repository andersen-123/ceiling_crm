import 'dart:async';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart';
import '../models/client.dart';
import '../models/estimate.dart';
import '../models/estimate_item.dart' as custom_estimate_item;
import '../models/project.dart';
import '../models/project_worker.dart';
import '../models/transaction.dart' as custom_transaction;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static sqflite.Database? _database;

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<sqflite.Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ceiling_crm.db');
    return await sqflite.openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(sqflite.Database db, int version) async {
    // Таблица клиентов
    await db.execute('''
      CREATE TABLE clients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        object_address TEXT,
        notes TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Таблица смет
    await db.execute('''
      CREATE TABLE estimates(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE SET NULL
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
        is_custom INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        position_number INTEGER,
        FOREIGN KEY (estimate_id) REFERENCES estimates (id) ON DELETE CASCADE
      )
    ''');

    // Таблица проектов
    await db.execute('''
      CREATE TABLE projects(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        client_id INTEGER,
        contract_sum REAL NOT NULL DEFAULT 0,
        prepayment_received REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'plan',
        created_at INTEGER NOT NULL,
        deadline INTEGER,
        FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE SET NULL
      )
    ''');

    // Таблица участников проекта
    await db.execute('''
      CREATE TABLE project_workers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        has_car INTEGER NOT NULL DEFAULT 0,
        salary_calculated REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    // Таблица транзакций
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        comment TEXT,
        date INTEGER NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');
  }

  // =============== CRUD для Client ===============
  Future<int> insertClient(Client client) async {
    final db = await database;
    return await db.insert('clients', client.toMap());
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('clients');
    return List.generate(maps.length, (i) => Client.fromMap(maps[i]));
  }

  // =============== CRUD для Estimate ===============
  Future<int> insertEstimate(Estimate estimate) async {
    final db = await database;
    final estimateId = await db.insert('estimates', estimate.toMap());
    
    for (var item in estimate.items) {
      await db.insert('estimate_items', {
        ...item.toMap(),
        'estimate_id': estimateId,
      });
    }
    
    return estimateId;
  }

  Future<Estimate?> getEstimateById(int id) async {
    final db = await database;
    
    final estimateMaps = await db.query(
      'estimates',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (estimateMaps.isEmpty) return null;
    
    final estimate = Estimate.fromMap(estimateMaps.first);
    
    final itemMaps = await db.query(
      'estimate_items',
      where: 'estimate_id = ?',
      whereArgs: [id],
      orderBy: 'position_number ASC',
    );
    
    final items = itemMaps.map((map) => custom_estimate_item.EstimateItem.fromMap(map)).toList();
    
    return estimate.copyWith(items: items);
  }

  Future<List<Estimate>> getEstimates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('estimates');
    return List.generate(maps.length, (i) => Estimate.fromMap(maps[i]));
  }

  Future<int> deleteEstimate(int id) async {
    final db = await database;
    return await db.delete(
      'estimates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =============== CRUD для Project ===============
  Future<int> insertProject(Project project) async {
    final db = await database;
    final projectId = await db.insert('projects', project.toMap());
    
    for (var worker in project.workers) {
      await db.insert('project_workers', {
        ...worker.toMap(),
        'project_id': projectId,
      });
    }
    
    return projectId;
  }

  Future<Project?> getProjectById(int id) async {
    final db = await database;
    
    final projectMaps = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (projectMaps.isEmpty) return null;
    
    final project = Project.fromMap(projectMaps.first);
    
    final workerMaps = await db.query(
      'project_workers',
      where: 'project_id = ?',
      whereArgs: [id],
    );
    
    final workers = workerMaps.map((map) => ProjectWorker.fromMap(map)).toList();
    
    return project.copyWith(workers: workers);
  }

  Future<List<Project>> getAllProjects() async {
    final db = await database;
    final projectMaps = await db.query('projects', orderBy: 'created_at DESC');
    
    final projects = <Project>[];
    for (var map in projectMaps) {
      final project = await getProjectById(map['id'] as int);
      if (project != null) projects.add(project);
    }
    
    return projects;
  }

  // =============== CRUD для Transaction ===============
  Future<int> insertTransaction(custom_transactionimport 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/client.dart';
import '../models/estimate.dart';
import '../models/estimate_item.dart';
import '../models/project.dart';
import '../models/project_worker.dart';
import '../models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ceiling_crm.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Таблица клиентов
    await db.execute('''
      CREATE TABLE clients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        object_address TEXT,
        notes TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Таблица смет
    await db.execute('''
      CREATE TABLE estimates(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE SET NULL
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
        is_custom INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        position_number INTEGER,
        FOREIGN KEY (estimate_id) REFERENCES estimates (id) ON DELETE CASCADE
      )
    ''');

    // Таблица проектов
    await db.execute('''
      CREATE TABLE projects(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        client_id INTEGER,
        contract_sum REAL NOT NULL DEFAULT 0,
        prepayment_received REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'plan',
        created_at INTEGER NOT NULL,
        deadline INTEGER,
        FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE SET NULL
      )
    ''');

    // Таблица участников проекта
    await db.execute('''
      CREATE TABLE project_workers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        has_car INTEGER NOT NULL DEFAULT 0,
        salary_calculated REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    // Таблица транзакций
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        comment TEXT,
        date INTEGER NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');
  }

  // =============== CRUD для Client ===============
  Future<int> insertClient(Client client) async {
    final db = await database;
    return await db.insert('clients', client.toMap());
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('clients');
    return List.generate(maps.length, (i) => Client.fromMap(maps[i]));
  }

  Future<Client?> getClientById(int id) async {
    final db = await database;
    final maps = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Client.fromMap(maps.first);
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    return await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await database;
    return await db.delete(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =============== CRUD для Estimate ===============
  Future<int> insertEstimate(Estimate estimate) async {
    final db = await database;
    final estimateId = await db.insert('estimates', estimate.toMap());
    
    for (var item in estimate.items) {
      await db.insert('estimate_items', {
        ...item.toMap(),
        'estimate_id': estimateId,
      });
    }
    
    return estimateId;
  }

  Future<Estimate?> getEstimateById(int id) async {
    final db = await database;
    
    // Получаем смету
    final estimateMaps = await db.query(
      'estimates',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (estimateMaps.isEmpty) return null;
    
    final estimate = Estimate.fromMap(estimateMaps.first);
    
    // Получаем элементы сметы
    final itemMaps = await db.query(
      'estimate_items',
      where: 'estimate_id = ?',
      whereArgs: [id],
      orderBy: 'position_number ASC',
    );
    
    final items = itemMaps.map((map) => EstimateItem.fromMap(map)).toList();
    
    return estimate.copyWith(items: items);
  }

  Future<int> updateEstimate(Estimate estimate) async {
    final db = await database;
    
    // Обновляем смету
    await db.update(
      'estimates',
      estimate.toMap(),
      where: 'id = ?',
      whereArgs: [estimate.id],
    );
    
    // Удаляем старые элементы
    await db.delete(
      'estimate_items',
      where: 'estimate_id = ?',
      whereArgs: [estimate.id],
    );
    
    // Добавляем новые элементы
    for (var item in estimate.items) {
      await db.insert('estimate_items', {
        ...item.toMap(),
        'estimate_id': estimate.id,
      });
    }
    
    return estimate.id!;
  }

  // =============== CRUD для Project ===============
  Future<int> insertProject(Project project) async {
    final db = await database;
    final projectId = await db.insert('projects', project.toMap());
    
    for (var worker in project.workers) {
      await db.insert('project_workers', {
        ...worker.toMap(),
        'project_id': projectId,
      });
    }
    
    return projectId;
  }

  Future<Project?> getProjectById(int id) async {
    final db = await database;
    
    // Получаем проект
    final projectMaps = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (projectMaps.isEmpty) return null;
    
    final project = Project.fromMap(projectMaps.first);
    
    // Получаем работников
    final workerMaps = await db.query(
      'project_workers',
      where: 'project_id = ?',
      whereArgs: [id],
    );
    
    final workers = workerMaps.map((map) => ProjectWorker.fromMap(map)).toList();
    
    return project.copyWith(workers: workers);
  }

  Future<List<Project>> getAllProjects() async {
    final db = await database;
    final projectMaps = await db.query('projects', orderBy: 'created_at DESC');
    
    final projects = <Project>[];
    for (var map in projectMaps) {
      final project = await getProjectById(map['id'] as int);
      if (project != null) projects.add(project);
    }
    
    return projects;
  }

  Future<int> updateProject(Project project) async {
    final db = await database;
    
    // Обновляем проект
    await db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
    
    // Обновляем работников
    await db.delete(
      'project_workers',
      where: 'project_id = ?',
      whereArgs: [project.id],
    );
    
    for (var worker in project.workers) {
      await db.insert('project_workers', {
        ...worker.toMap(),
        'project_id': project.id,
      });
    }
    
    return project.id!;
  }

  // =============== CRUD для Transaction ===============
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
    
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  Future<Map<String, double>> getProjectExpensesByCategory(int projectId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM transactions
      WHERE project_id = ? AND type = 'expense'
      GROUP BY category
    ''', [projectId]);
    
    final result = <String, double>{};
    for (final map in maps) {
      result[map['category'] as String] = map['total'] as double;
    }
    
    return result;
  }

  Future<double> getProjectTotalExpenses(int projectId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE project_id = ? AND type = 'expense'
    ''', [projectId]);
    
    return result.first['total'] as double? ?? 0.0;
  }

  Future<double> getProjectTotalIncome(int projectId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE project_id = ? AND type = 'income'
    ''', [projectId]);
    
    return result.first['total'] as double? ?? 0.0;
  }

  // =============== Вспомогательные методы ===============
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('project_workers');
    await db.delete('projects');
    await db.delete('estimate_items');
    await db.delete('estimates');
    await db.delete('clients');
  }
}
