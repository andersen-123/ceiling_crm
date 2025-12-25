// Сервис для управления шаблонами условий оплаты и примечаний.
// Хранит шаблоны в локальной базе данных SQLite.

import '../data/database_helper.dart';

class TemplateService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Типы шаблонов
  static const String typePayment = 'payment';
  static const String typeInstallation = 'installation';
  static const String typeNote = 'note';
  static const String typeWork = 'work';
  static const String typeEquipment = 'equipment';

  // Таблица для хранения шаблонов
  static const String tableTemplates = 'templates';

  // Инициализация таблицы шаблонов
  Future<void> initializeTemplates() async {
    final db = await _dbHelper.database;
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableTemplates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Создаем индексы
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_templates_type 
      ON $tableTemplates(type)
    ''');

    // Добавляем стандартные шаблоны, если таблица пуста
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM $tableTemplates');
    final row = count.first;
    if (row['count'] == 0) {
      await _addDefaultTemplates();
    }
  }

  // Добавление стандартных шаблонов
  Future<void> _addDefaultTemplates() async {
    // Шаблоны условий оплаты
    await addTemplate(
      type: typePayment,
      title: '50% предоплата',
      content: '50% предоплата за 3 дня до начала работ. Оставшиеся 50% по завершению монтажа.',
    );

    await addTemplate(
      type: typePayment,
      title: '100% предоплата',
      content: '100% предоплата за 7 дней до начала работ.',
    );

    await addTemplate(
      type: typePayment,
      title: 'Рассрочка',
      content: '30% предоплата, 40% в день начала работ, 30% по завершению.',
    );

    // Шаблоны условий монтажа
    await addTemplate(
      type: typeInstallation,
      title: 'Стандартный монтаж',
      content: 'Монтаж производится в течение 1-3 рабочих дней с момента поступления предоплаты.',
    );

    await addTemplate(
      type: typeInstallation,
      title: 'Срочный монтаж',
      content: 'Срочный монтаж в течение 24 часов. Дополнительная плата 20%.',
    );

    // Шаблоны примечаний
    await addTemplate(
      type: typeNote,
      title: 'Замер бесплатный',
      content: 'Выезд замерщика бесплатный в пределах города.',
    );

    await addTemplate(
      type: typeNote,
      title: 'Гарантия',
      content: 'Гарантия на материалы и работы - 2 года.',
    );

    // Шаблоны работ
    await addTemplate(
      type: typeWork,
      title: 'Монтаж потолка',
      content: 'Монтаж натяжного потолка MSD Premium белый матовый',
    );

    await addTemplate(
      type: typeWork,
      title: 'Обход трубы',
      content: 'Обход трубы отопления/водоснабжения',
    );

    // Шаблоны оборудования
    await addTemplate(
      type: typeEquipment,
      title: 'Светильник LED',
      content: 'Светильник LED 12W 3000K врезной',
    );

    await addTemplate(
      type: typeEquipment,
      title: 'Профиль пристенный',
      content: 'Профиль пристенный алюминиевый 3м',
    );
  }

  // Добавление нового шаблона
  Future<int> addTemplate({
    required String type,
    required String title,
    required String content,
    int sortOrder = 0,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    
    return await db.insert(tableTemplates, {
      'type': type,
      'title': title,
      'content': content,
      'sort_order': sortOrder,
      'created_at': now,
      'updated_at': now,
    });
  }

  // Получение всех шаблонов определенного типа
  Future<List<Map<String, dynamic>>> getTemplatesByType(String type) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      tableTemplates,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'sort_order, title',
    );
    
    return result;
  }

  // Получение всех шаблонов (группированных по типу)
  Future<Map<String, List<Map<String, dynamic>>>> getAllTemplates() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      tableTemplates,
      orderBy: 'type, sort_order, title',
    );
    
    // Группируем по типу
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (final template in result) {
      final type = template['type'] as String;
      if (!grouped.containsKey(type)) {
        grouped[type] = [];
      }
      grouped[type]!.add(template);
    }
    
    return grouped;
  }

  // Обновление шаблона
  Future<int> updateTemplate({
    required int id,
    String? title,
    String? content,
    int? sortOrder,
  }) async {
    final db = await _dbHelper.database;
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (title != null) updates['title'] = title;
    if (content != null) updates['content'] = content;
    if (sortOrder != null) updates['sort_order'] = sortOrder;
    
    return await db.update(
      tableTemplates,
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Удаление шаблона
  Future<int> deleteTemplate(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      tableTemplates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Получение названия типа для отображения
  String getTypeDisplayName(String type) {
    switch (type) {
      case typePayment:
        return 'Условия оплаты';
      case typeInstallation:
        return 'Условия монтажа';
      case typeNote:
        return 'Примечания';
      case typeWork:
        return 'Работы';
      case typeEquipment:
        return 'Оборудование';
      default:
        return type;
    }
  }

  // Получение иконки для типа
  String getTypeIcon(String type) {
    switch (type) {
      case typePayment:
        return '💰';
      case typeInstallation:
        return '🔧';
      case typeNote:
        return '📝';
      case typeWork:
        return '👷';
      case typeEquipment:
        return '📦';
      default:
        return '📄';
    }
  }
}
