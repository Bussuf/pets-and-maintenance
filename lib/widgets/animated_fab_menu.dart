import 'package:flutter/material.dart';
import '../screens/create_entity_screen.dart';

class AnimatedFabMenu extends StatelessWidget {
  final String? currentCategoryId;
  final String? currentItemId;

  const AnimatedFabMenu({
    Key? key,
    this.currentCategoryId,
    this.currentItemId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'main_fab',
      onPressed: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black.withOpacity(0.6),
            barrierDismissible: true,
            transitionDuration: const Duration(milliseconds: 250),
            pageBuilder: (context, animation, secondaryAnimation) {
              return _FabMenuOverlay(
                animation: animation,
                currentCategoryId: currentCategoryId,
                currentItemId: currentItemId,
              );
            },
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}

class _FabMenuOverlay extends StatelessWidget {
  final Animation<double> animation;
  final String? currentCategoryId;
  final String? currentItemId;

  const _FabMenuOverlay({
    required this.animation,
    this.currentCategoryId,
    this.currentItemId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // לחיצה בכל שטח המסך או סביב הפילולות סוגרת את התפריט מיד
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildPill(context, 'קבוצה', Icons.folder_outlined, EntityType.category, 2),
            const SizedBox(height: 16),
            _buildPill(context, 'פריט', Icons.inventory_2_outlined, EntityType.item, 1),
            const SizedBox(height: 16),
            _buildPill(context, 'משימה', Icons.task_alt, EntityType.task, 0),
            const SizedBox(height: 24),
            RotationTransition(
              turns: Tween<double>(begin: 0.0, end: 0.125).animate(animation),
              child: ScaleTransition(
                scale: animation,
                child: FloatingActionButton(
                  heroTag: 'close_fab',
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  elevation: 4,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(BuildContext context, String label, IconData icon, EntityType type, int index) {
    final curvedAnim = CurvedAnimation(
      parent: animation,
      curve: Interval(0.2 + (index * 0.1), 1.0, curve: Curves.easeOutBack),
    );

    return ScaleTransition(
      scale: curvedAnim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(curvedAnim),
        child: FloatingActionButton.extended(
          heroTag: 'fab_pill_$index',
          elevation: 2,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.primary,
          onPressed: () {
            Navigator.pop(context);
            // העברת ההקשר המלא (גם קבוצה וגם פריט אם נבחר) מבלי לנעול אפשרות לשינוי
            CreateEntityScreen.show(
              context,
              type: type,
              categoryId: currentCategoryId,
              itemId: type == EntityType.task ? currentItemId : null,
            );
          },
          icon: Icon(icon),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}