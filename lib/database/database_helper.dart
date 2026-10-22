import 'package:flutter/foundation.dart' show debugPrint;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../models/task.dart';
import '../models/task_log.dart';
import 'sample_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pets_and_maintenance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // גרסה 7: תאריך יעד לכל ביצוע ותאריך יצירה למשימה (ניתוח מעקב משימה #25)
    return await openDatabase(
      path,
      version: 7,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // יצירת טבלאות מלאות עבור התקנה ראשונית חדשה
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        color INTEGER,
        icon TEXT,
        sort_order INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // תוקן סדר העמודות: FOREIGN KEY חייב להופיע בסוף ההגדרה
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        interval_amount INTEGER NOT NULL,
        interval_unit TEXT NOT NULL,
        end_condition TEXT NOT NULL,
        end_condition_value TEXT,
        completed_count INTEGER DEFAULT 0,
        last_completed_date TEXT,
        next_due_date TEXT,
        is_reminder_enabled INTEGER DEFAULT 0,
        reminder_time TEXT,
        google_event_id TEXT,
        created_at TEXT,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE task_logs (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        notes TEXT,
        due_at TEXT,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    // נתוני דוגמה (#75) - רק כאן: הפונקציה הזו רצה רק כשהמסד נוצר לראשונה (התקנה חדשה)
    await SampleData.seed(db);
  }

  // מיגרציה בטוחה ושמירת נתונים קיימים
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try { await db.execute('ALTER TABLE categories ADD COLUMN color INTEGER;'); } catch (_) {}
      try { await db.execute('ALTER TABLE categories ADD COLUMN icon TEXT;'); } catch (_) {}
      try { await db.execute('ALTER TABLE tasks ADD COLUMN end_condition_value TEXT;'); } catch (_) {}
      try { await db.execute('ALTER TABLE tasks ADD COLUMN completed_count INTEGER DEFAULT 0;'); } catch (_) {}
    }
    if (oldVersion < 3) {
      try { await db.execute('ALTER TABLE items ADD COLUMN image_url TEXT;'); } catch (_) {}
    }
    if (oldVersion < 4) {
      // מיגרציה בטוחה לגרסה 4 עם התעלמות משגיאה במקרה שהעמודה כבר קיימת מניסיון קודם
      try {
        await db.execute('ALTER TABLE categories ADD COLUMN sort_order INTEGER DEFAULT 0;');
      } catch (e) {
        debugPrint('Column sort_order already exists in categories or error: $e');
      }
      try {
        await db.execute('ALTER TABLE items ADD COLUMN sort_order INTEGER DEFAULT 0;');
      } catch (e) {
        debugPrint('Column sort_order already exists in items or error: $e');
      }
    }
    if (oldVersion < 5) {
      try { await db.execute('ALTER TABLE tasks ADD COLUMN is_reminder_enabled INTEGER DEFAULT 0;'); } catch (_) {}
      try { await db.execute('ALTER TABLE tasks ADD COLUMN reminder_time TEXT;'); } catch (_) {}
    }
    if (oldVersion < 6) {
      // מיגרציה לגרסה 6: הוספת עמודה למזהה אירוע יומן גוגל
      try { await db.execute('ALTER TABLE tasks ADD COLUMN google_event_id TEXT;'); } catch (_) {}
    }
    if (oldVersion < 7) {
      // מיגרציה לגרסה 7 (#25): תאריך יצירת משימה, ותאריך היעד שכל ביצוע סגר
      // ערכים קיימים נשארים ריקים - מנוע החישובים משחזר אותם בקירוב
      try { await db.execute('ALTER TABLE tasks ADD COLUMN created_at TEXT;'); } catch (_) {}
      try { await db.execute('ALTER TABLE task_logs ADD COLUMN due_at TEXT;'); } catch (_) {}
    }
  }

  // ----------------- השלמות עבור Providers (הפונקציות החסרות) -----------------

  Future<List<Category>> readAllCategories() async {
    return await getCategories();
  }

  Future<AppTask?> readTask(String id) async {
    final db = await database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return AppTask.fromMap(maps.first);
    }
    return null;
  }

  /// שליפת משימות דאשבורד כולל פרטי הפריט והקבוצה (מניעת NULL)
  Future<List<Map<String, dynamic>>> getDashboardTasks() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.*, 
             i.name AS item_name, 
             i.category_id AS category_id,
             c.name AS category_name, 
             c.color AS category_color, 
             c.icon AS category_icon
      FROM tasks t
      JOIN items i ON t.item_id = i.id
      JOIN categories c ON i.category_id = c.id
      ORDER BY t.next_due_date ASC
    ''');
  }

  // בדיקה למניעת כפילות בשם קבוצה (למעט הקבוצה הנוכחית אם אנחנו בעריכה)
  Future<bool> isCategoryNameExists(String name, {String? excludeId}) async {
    final db = await database;
    final res = await db.query(
      'categories',
      where: excludeId != null ? 'LOWER(name) = ? AND id != ?' : 'LOWER(name) = ?',
      whereArgs: excludeId != null ? [name.trim().toLowerCase(), excludeId] : [name.trim().toLowerCase()],
    );
    return res.isNotEmpty;
  }

  // שליפת כל המשימות השייכות לפריטים תחת קבוצה מסוימת
  Future<List<Map<String, dynamic>>> getTasksByCategory(String categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT tasks.*, items.name AS item_name 
      FROM tasks 
      INNER JOIN items ON tasks.item_id = items.id 
      WHERE items.category_id = ?
      ORDER BY tasks.next_due_date ASC
    ''', [categoryId]);
    return maps;
  }

  // ----------------- Categories CRUD -----------------
  Future<void> createCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    // שליפה לפי סדר המיון הידני, ובתוך כך לפי מועד יצירה
    final maps = await db.query('categories', orderBy: 'sort_order ASC, created_at ASC');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ----------------- Items CRUD -----------------
  Future<void> createItem(Item item) async {
    final db = await database;
    await db.insert('items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Item>> getItemsByCategory(String categoryId) async {
    final db = await database;
    // שליפה לפי סדר המיון הידני
    final maps = await db.query(
      'items',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'sort_order ASC',
    );
    return maps.map((map) => Item.fromMap(map)).toList();
  }

  Future<void> updateItem(Item item) async {
    final db = await database;
    await db.update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  /// עדכון סדר קבוצות באצווה אחת בטוחה ומהירה
  Future<void> reorderCategories(List<String> orderedIds) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < orderedIds.length; i++) {
      batch.update(
        'categories',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [orderedIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  /// עדכון סדר פריטים באצווה אחת בטוחה ומהירה
  Future<void> reorderItems(List<String> orderedIds) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < orderedIds.length; i++) {
      batch.update(
        'items',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [orderedIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  // ----------------- Tasks CRUD -----------------
  Future<void> createTask(AppTask task) async {
    final db = await database;
    await db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<AppTask>> getTasksByItem(String itemId) async {
    final db = await database;
    final maps = await db.query('tasks', where: 'item_id = ?', whereArgs: [itemId]);
    return maps.map((map) => AppTask.fromMap(map)).toList();
  }

  Future<List<AppTask>> getAllTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'next_due_date ASC');
    return maps.map((map) => AppTask.fromMap(map)).toList();
  }

  Future<void> updateTask(AppTask task) async {
    final db = await database;
    await db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ----------------- Task Logs CRUD -----------------
  Future<void> createTaskLog(TaskLog log) async {
    final db = await database;
    await db.insert('task_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TaskLog>> getLogsByTask(String taskId) async {
    final db = await database;
    final maps = await db.query('task_logs', where: 'task_id = ?', whereArgs: [taskId], orderBy: 'completed_at DESC');
    return maps.map((map) => TaskLog.fromMap(map)).toList();
  }

  /// תיקון תאריך של ביצוע (#25.9) - רק completed_at; תאריך היעד שסגר (due_at) נשאר
  Future<void> updateTaskLogDate(String logId, DateTime completedAt) async {
    final db = await database;
    await db.update('task_logs', {'completed_at': completedAt.toIso8601String()}, where: 'id = ?', whereArgs: [logId]);
  }

  Future<void> deleteTaskLog(String logId) async {
    final db = await database;
    await db.delete('task_logs', where: 'id = ?', whereArgs: [logId]);
  }

  /// עדכון המונה ו'בוצע לאחרונה' של משימה לפי הביצועים שנשארו. לא נוגע ביעד הבא (החלטת משתמש #25.9)
  Future<void> recalcTaskFromLogs(String taskId) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS cnt, MAX(completed_at) AS last FROM task_logs WHERE task_id = ?',
      [taskId],
    );
    await db.update(
      'tasks',
      {'completed_count': rows.first['cnt'] ?? 0, 'last_completed_date': rows.first['last']},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  /// חיפוש גלובלי בכל המאגר (משימות, פריטים וקבוצות) כולל מידע הקשרי
  Future<Map<String, List<Map<String, dynamic>>>> searchAll(String query) async {
    final db = await database;
    final sanitized = '%$query%';

    // 1. קבוצות
    final categories = await db.rawQuery('''
      SELECT id, name, description, color, icon, 'category' as type
      FROM categories
      WHERE name LIKE ? OR (description IS NOT NULL AND description LIKE ?)
      ORDER BY name ASC
    ''', [sanitized, sanitized]);

    // 2. פריטים עם שיוך לקבוצה
    final items = await db.rawQuery('''
      SELECT i.id, i.name, i.description, i.category_id,
             c.name as category_name, c.color as category_color, c.icon as category_icon,
             'item' as type
      FROM items i
      JOIN categories c ON i.category_id = c.id
      WHERE i.name LIKE ? OR (i.description IS NOT NULL AND i.description LIKE ?)
      ORDER BY i.name ASC
    ''', [sanitized, sanitized]);

    // 3. משימות עם שיוך לפריט ולקבוצה
    final tasks = await db.rawQuery('''
      SELECT t.id, t.name, t.description, t.item_id, t.next_due_date,
             t.interval_amount, t.interval_unit, t.end_condition, t.end_condition_value,
             i.name as item_name, i.category_id,
             c.name as category_name, c.color as category_color, c.icon as category_icon,
             'task' as type
      FROM tasks t
      JOIN items i ON t.item_id = i.id
      JOIN categories c ON i.category_id = c.id
      WHERE t.name LIKE ? OR (t.description IS NOT NULL AND t.description LIKE ?)
      ORDER BY t.name ASC
    ''', [sanitized, sanitized]);

    return {
      'categories': categories,
      'items': items,
      'tasks': tasks,
    };
  }
}