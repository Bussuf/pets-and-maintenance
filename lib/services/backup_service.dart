import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import 'notification_service.dart';

/// גיבוי ושחזור של כל נתוני האפליקציה לקובץ JSON מקומי
class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  static const _appId = 'pets_and_maintenance';
  static const _formatVersion = 1;
  // סדר הטבלאות חשוב: הורים לפני ילדים (בגלל FOREIGN KEY)
  static const _tables = ['categories', 'items', 'tasks', 'task_logs'];

  /// ייצוא כל הטבלאות לקובץ JSON ופתיחת חלון שיתוף (Drive, וואטסאפ, קבצים...)
  Future<void> exportToFile() async {
    final db = await DatabaseHelper.instance.database;
    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in _tables) {
      tables[table] = await db.query(table);
    }

    final data = {
      'app': _appId,
      'format_version': _formatVersion,
      'db_version': await db.getVersion(),
      'exported_at': DateTime.now().toIso8601String(),
      'tables': tables,
    };

    final bytes = Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(data)));
    final date = DateTime.now().toIso8601String().split('T').first;
    final fileName = 'pets_backup_$date.json';

    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'application/json', name: fileName)],
      fileNameOverrides: [fileName],
    ));
  }

  /// בחירת קובץ גיבוי ושחזור - מחליף את כל הנתונים הקיימים!
  /// מחזיר false אם המשתמש ביטל את בחירת הקובץ. זורק FormatException אם הקובץ לא תקין.
  Future<bool> importFromFile() async {
    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null) return false;
    final bytes = await file.readAsBytes();

    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> || decoded['app'] != _appId || decoded['tables'] is! Map) {
      throw const FormatException('Not a valid backup file');
    }

    final db = await DatabaseHelper.instance.database;
    if ((decoded['db_version'] as int? ?? 0) > await db.getVersion()) {
      throw const FormatException('Backup is from a newer app version');
    }
    final tables = decoded['tables'] as Map<String, dynamic>;

    // ביטול התראות של המשימות הקיימות לפני ההחלפה
    for (final task in await DatabaseHelper.instance.getAllTasks()) {
      try {
        await NotificationService.instance.cancelReminder(task.id);
      } catch (e) {
        debugPrint('Failed to cancel reminder: $e');
      }
    }

    // החלפה מלאה בטרנזקציה אחת: אם משהו נכשל - שום דבר לא נמחק
    await db.transaction((txn) async {
      for (final table in _tables.reversed) {
        await txn.delete(table);
      }
      final batch = txn.batch();
      for (final table in _tables) {
        for (final row in (tables[table] as List? ?? const [])) {
          batch.insert(table, Map<String, Object?>.from(row as Map));
        }
      }
      await batch.commit(noResult: true);
    });

    // תזמון מחדש של התראות למשימות המשוחזרות
    for (final task in await DatabaseHelper.instance.getAllTasks()) {
      try {
        await NotificationService.instance.scheduleTaskReminder(task);
      } catch (e) {
        debugPrint('Failed to schedule reminder: $e');
      }
    }
    return true;
  }
}