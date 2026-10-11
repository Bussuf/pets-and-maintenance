import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/task_log.dart';
import '../providers/database_provider.dart';
import '../providers/dashboard_tasks_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_delete_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  // חישוב תאריך היעד הבא מתוך רגע הביצוע הנוכחי
  DateTime _calculateNextDueDate(int amount, String unit) {
    final now = DateTime.now();
    switch (unit) {
      case 'days':
        return now.add(Duration(days: amount));
      case 'weeks':
        return now.add(Duration(days: amount * 7));
      case 'months':
        return DateTime(now.year, now.month + amount, now.day);
      case 'years':
        return DateTime(now.year + amount, now.month, now.day);
      default:
        return now.add(Duration(days: amount));
    }
  }

  // ביצוע משימה: יצירת לוג היסטוריה וחישוב מועד עתידי
  Future<void> _completeTask(BuildContext context, WidgetRef ref, String taskId) async {
    final db = ref.read(databaseProvider);
    final task = await db.readTask(taskId);
    if (task == null) return;

    final now = DateTime.now();
    final nextDate = _calculateNextDueDate(task.intervalAmount, task.intervalUnit);

    // 1. שמירת לוג במערכת לצורך מעקב עתידי
    final log = TaskLog(
      id: const Uuid().v4(),
      taskId: task.id,
      completedAt: now,
      notes: '{"source": "dashboard_quick_action"}',
    );
    await db.createTaskLog(log);

    // 2. עדכון המשימה עם תאריך ביצוע אחרון ותאריך יעד חדש
    final updatedTask = AppTask(
      id: task.id,
      itemId: task.itemId,
      name: task.name,
      description: task.description,
      intervalAmount: task.intervalAmount,
      intervalUnit: task.intervalUnit,
      endCondition: task.endCondition,
      lastCompletedDate: now,
      nextDueDate: nextDate,
    );
    await db.updateTask(updatedTask);

    // 3. ריענון הדאשבורד באופן ריאקטיבי
    ref.invalidate(dashboardTasksProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('המשימה סומנה כבוצעה בהצלחה! תאריך היעד עודכן.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // מחיקת משימה באופן מאובטח
  Future<void> _deleteTask(BuildContext context, WidgetRef ref, String taskId) async {
    final db = ref.read(databaseProvider);
    await db.deleteTask(taskId);
    ref.invalidate(dashboardTasksProvider);
  }

  // פתיחת תפריט פעולות תחתון למשימה
  void _showTaskActionsSheet(BuildContext context, WidgetRef ref, Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                task['name'] ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'שייך ל: ${task['item_name']}',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: const Text('בוצע עכשיו', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('יחשב את מועד היעד הבא ויתעד בלוגים'),
                onTap: () {
                  Navigator.pop(ctx);
                  _completeTask(context, ref, task['id']);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.dangerColor),
                title: const Text('מחק משימה', style: TextStyle(color: AppTheme.dangerColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  ConfirmDeleteDialog.show(
                    context,
                    title: 'מחיקת משימה',
                    content: 'האם אתה בטוח שברצונך למחוק משימה זו לצמיתות?',
                    onConfirm: () => _deleteTask(context, ref, task['id']),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(dashboardTasksProvider);

    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return const Center(
            child: Text(
              'אין משימות דחופות כרגע! 🎉',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardTasksProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: tasks.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildMetricsHeader(tasks.length);
              }

              final task = tasks[index - 1];
              return _buildTaskCard(context, ref, task);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('שגיאה בטעינת הנתונים: $err')),
    );
  }

  Widget _buildMetricsHeader(int totalTasks) {
    return Card(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '$totalTasks',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
              const Text('משימות פעילות', style: TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, Map<String, dynamic> task) {
    final dueDateStr = task['next_due_date'] != null
        ? task['next_due_date'].toString().split('T')[0]
        : 'לא נקבע';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(task['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('פריט: ${task['item_name']}  |  יעד: $dueDateStr'),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showTaskActionsSheet(context, ref, task),
        ),
        onTap: () => _showTaskActionsSheet(context, ref, task),
      ),
    );
  }
}