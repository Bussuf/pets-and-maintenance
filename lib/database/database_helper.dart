import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../models/task.dart';
import '../models/task_log.dart';

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

    // שדרוג לגרסה 3 לתמיכה בשדה התמונה בפריטים
    return await openDatabase(
      path,
      version: 3,
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
        icon TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

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
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE task_logs (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');
  }

  // מיגרציה בטוחה ושמירת נתונים קיימים
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE categories ADD COLUMN color INTEGER;');
      await db.execute('ALTER TABLE categories ADD COLUMN icon TEXT;');
      await db.execute('ALTER TABLE tasks ADD COLUMN end_condition_value TEXT;');
      await db.execute('ALTER TABLE tasks ADD COLUMN completed_count INTEGER DEFAULT 0;');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE items ADD COLUMN image_url TEXT;');
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

  Future<List<Map<String, dynamic>>> getDashboardTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT tasks.*, items.name AS item_name 
      FROM tasks 
      INNER JOIN items ON tasks.item_id = items.id 
      ORDER BY tasks.next_due_date ASC
    ''');
    return maps;
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
    final maps = await db.query('categories', orderBy: 'created_at ASC');
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
    final maps = await db.query('items', where: 'category_id = ?', whereArgs: [categoryId]);
    return maps.map((map) => Item.fromMap(map)).toList();
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
}