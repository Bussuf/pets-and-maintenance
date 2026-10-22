import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../providers/locale_provider.dart';

/// נתוני דוגמה (#75) - נוצרים פעם אחת, רק כשהמסד נוצר לראשונה (התקנה חדשה).
/// לא בעדכון גרסה ולא אחרי שחזור גיבוי. בלי תזכורות ובלי יומן.
/// המטרה: להבין את המבנה קבוצה ← פריט ← משימה, ולהראות דף ניתוח מלא.
class SampleData {
  SampleData._();

  static Future<void> seed(Database db) async {
    final l10n = LocaleNotifier.l10n; // שפת הטלפון (או השפה שנבחרה)
    const uuid = Uuid();
    final now = DateTime.now();
    // T = היום, בשעה קבועה של "אחרי הצהריים" - כל התאריכים יחסיים אליו
    final t = DateTime(now.year, now.month, now.day, 18, 0);
    DateTime day(int offset) => t.add(Duration(days: offset));

    // --- קבוצה: בית ---
    final homeId = uuid.v4();
    await db.insert('categories', {
      'id': homeId,
      'name': l10n.sampleGroupHome,
      'created_at': day(-24).toIso8601String(),
      'color': 0xFF009688, // teal
      'icon': 'home',
      'sort_order': 0,
    });

    final gardenId = uuid.v4();
    await db.insert('items', {'id': gardenId, 'category_id': homeId, 'name': l10n.sampleItemGarden, 'sort_order': 0});
    // פריט ריק - להראות שפריט יכול להתחיל בלי משימות
    await db.insert('items', {'id': uuid.v4(), 'category_id': homeId, 'name': l10n.sampleItemCleaning, 'sort_order': 1});

    // השקיית עציצים: כל 4 ימים, נוצרה T-24.
    // ביצועים: T-20 בזמן, T-16 בזמן, T-11 איחור יום, T-8 הקדמת יום, T-4 בזמן -> היעד הבא = היום
    final wateringId = uuid.v4();
    const completions = [-20, -16, -11, -8, -4];
    const dues = [-20, -16, -12, -7, -4]; // היעד שכל ביצוע סגר
    await db.insert('tasks', {
      'id': wateringId,
      'item_id': gardenId,
      'name': l10n.sampleTaskWatering,
      'interval_amount': 4,
      'interval_unit': 'days',
      'end_condition': 'always',
      'completed_count': completions.length,
      'last_completed_date': day(completions.last).toIso8601String(),
      'next_due_date': day(0).toIso8601String(),
      'is_reminder_enabled': 0,
      'created_at': day(-24).toIso8601String(),
    });
    for (var i = 0; i < completions.length; i++) {
      await db.insert('task_logs', {
        'id': uuid.v4(),
        'task_id': wateringId,
        'completed_at': day(completions[i]).toIso8601String(),
        'due_at': day(dues[i]).toIso8601String(),
      });
    }

    // --- קבוצה: חיות מחמד ---
    final petsId = uuid.v4();
    await db.insert('categories', {
      'id': petsId,
      'name': l10n.sampleGroupPets,
      'created_at': now.toIso8601String(),
      'color': 0xFFFF9800, // orange
      'icon': 'pets',
      'sort_order': 1,
    });

    final catId = uuid.v4();
    await db.insert('items', {'id': catId, 'category_id': petsId, 'name': '🐱', 'sort_order': 0});

    // ניקוי כלי מים: ברירות המחדל של טופס היצירה (כל 7 ימים, תמיד), בלי ביצועים
    await db.insert('tasks', {
      'id': uuid.v4(),
      'item_id': catId,
      'name': l10n.sampleTaskWaterBowl,
      'interval_amount': 7,
      'interval_unit': 'days',
      'end_condition': 'always',
      'completed_count': 0,
      'next_due_date': AppTask.addInterval(now, 7, 'days').toIso8601String(),
      'is_reminder_enabled': 0,
      'created_at': now.toIso8601String(),
    });
  }
}
