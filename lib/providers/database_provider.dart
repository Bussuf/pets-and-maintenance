import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';

// חושף את ה-DatabaseHelper לכל שאר ה-Providers באפליקציה
final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});