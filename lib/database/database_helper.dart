import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/estimate_templates.dart';

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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'estimates.db');
    
    return await openDatabase(
      path,
      version: 3, // Увеличили до версии 3
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE estimates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        total_price REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE estimate_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        estimate_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        quantity REAL NOT NULL,
        FOREIGN KEY (estimate_id) REFERENCES estimates (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE estimate_templates (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        base_price REAL,
        description TEXT,
        min_quantity REAL DEFAULT 0,
        is_required INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        code TEXT,
        material_type TEXT
      )
    ''');
    
    // Заполняем таблицу шаблонов начальными данными
    await _populateTemplates(db);
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    print('📊 Миграция БД: с версии $oldVersion на $newVersion');
    
    if (oldVersion < 2) {
      // Добавляем таблицу шаблонов
      await db.execute('''
        CREATE TABLE IF NOT EXISTS estimate_templates (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          unit TEXT NOT NULL,
          price REAL NOT NULL,
          base_price REAL,
          description TEXT,
          min_quantity REAL DEFAULT 0,
          is_required INTEGER DEFAULT 0,
          sort_order INTEGER DEFAULT 0,
          is_active INTEGER DEFAULT 1,
          code TEXT,
          material_type TEXT
        )
      ''');
      
      await _populateTemplates(db);
    }
    
    if (oldVersion < 3) {
      // В версии 3 полностью обновляем шаблоны с реальными данными из Excel
      print('🔄 Обновление шаблонов до версии 3');
      
      // Удаляем старые данные
      await db.delete('estimate_templates');
      
      // Заполняем новыми данными
      await _populateTemplates(db);
      
      // Добавляем столбец base_price если его нет
      try {
        await db.execute('ALTER TABLE estimate_templates ADD COLUMN base_price REAL');
      } catch (e) {
        print('Столбец base_price уже существует: $e');
      }
    }
  }

  Future<void> _populateTemplates(Database db) async {
    print('📥 Заполнение таблицы шаблонов...');
    
    for (var template in EstimateTemplate.allTemplates) {
      await db.insert('estimate_templates', template.toMap(), 
        conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    print('✅ Заполнено ${EstimateTemplate.allTemplates.length} шаблонов');
  }

  // Метод для инициализации базы данных (публичный интерфейс)
  Future<void> initDatabase() async {
    await database; // Просто обращаемся к database, чтобы инициализировать
  }

  // Метод для обновления таблицы шаблонов (можно вызывать извне)
  Future<void> updateTemplatesTable() async {
    final db = await database;
    
    // Проверяем существование таблицы
    await db.execute('''
      CREATE TABLE IF NOT EXISTS estimate_templates (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        base_price REAL,
        description TEXT,
        min_quantity REAL DEFAULT 0,
        is_required INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        code TEXT,
        material_type TEXT
      )
    ''');
    
    // Обновляем данные
    await _populateTemplates(db);
  }

  // Методы для работы с шаблонами
  Future<List<Map<String, dynamic>>> getTemplates() async {
    final db = await database;
    return await db.query('estimate_templates', orderBy: 'sort_order');
  }

  Future<List<Map<String, dynamic>>> getTemplatesByCategory(String category) async {
    final db = await database;
    return await db.query(
      'estimate_templates',
      where: 'category = ? AND is_active = 1',
      whereArgs: [category],
      orderBy: 'sort_order',
    );
  }

  Future<void> insertTemplate(Map<String, dynamic> template) async {
    final db = await database;
    await db.insert('estimate_templates', template);
  }

  Future<void> updateTemplate(int id, Map<String, dynamic> template) async {
    final db = await database;
    await db.update(
      'estimate_templates',
      template,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTemplate(int id) async {
    final db = await database;
    await db.delete(
      'estimate_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Методы для работы со сметами
  Future<int> insertEstimate(Map<String, dynamic> estimate) async {
    final db = await database;
    return await db.insert('estimates', estimate);
  }

  Future<List<Map<String, dynamic>>> getEstimates() async {
    final db = await database;
    return await db.query('estimates', orderBy: 'updated_at DESC');
  }

  Future<Map<String, dynamic>?> getEstimate(int id) async {
    final db = await database;
    final result = await db.query(
      'estimates',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updateEstimate(int id, Map<String, dynamic> estimate) async {
    final db = await database;
    await db.update(
      'estimates',
      estimate,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteEstimate(int id) async {
    final db = await database;
    await db.delete(
      'estimates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Методы для работы с позициями смет
  Future<List<Map<String, dynamic>>> getEstimateItems(int estimateId) async {
    final db = await database;
    return await db.query(
      'estimate_items',
      where: 'estimate_id = ?',
      whereArgs: [estimateId],
      orderBy: 'id',
    );
  }

  Future<void> insertEstimateItem(Map<String, dynamic> item) async {
    final db = await database;
    await db.insert('estimate_items', item);
  }

  Future<void> updateEstimateItem(int id, Map<String, dynamic> item) async {
    final db = await database;
    await db.update(
      'estimate_items',
      item,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteEstimateItem(int id) async {
    final db = await database;
    await db.delete(
      'estimate_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteEstimateItems(int estimateId) async {
    final db = await database;
    await db.delete(
      'estimate_items',
      where: 'estimate_id = ?',
      whereArgs: [estimateId],
    );
  }

  // Получение статистики
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;
    
    final estimatesCount = (await db.query('estimates')).length;
    final itemsCount = (await db.query('estimate_items')).length;
    final templatesCount = (await db.query('estimate_templates')).length;
    
    return {
      'estimates': estimatesCount,
      'items': itemsCount,
      'templates': templatesCount,
    };
  }

  // Закрытие базы данных
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
