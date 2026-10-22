import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class SettingsState {
  final String notificationStyle; // 'none', 'grouped', 'separated'
  final TimeOfDay reminderTime;

  SettingsState({
    required this.notificationStyle,
    required this.reminderTime,
  });

  SettingsState copyWith({
    String? notificationStyle,
    TimeOfDay? reminderTime,
  }) {
    return SettingsState(
      notificationStyle: notificationStyle ?? this.notificationStyle,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(
    notificationStyle: 'separated',
    reminderTime: const TimeOfDay(hour: 9, minute: 0),
  )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final style = prefs.getString('notificationStyle') ?? 'separated';
    final timeStr = prefs.getString('reminderTime') ?? '09:00';
    
    final parts = timeStr.split(':');
    final time = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    state = SettingsState(notificationStyle: style, reminderTime: time);
  }

  Future<void> setNotificationStyle(String style) async {
    state = state.copyWith(notificationStyle: style);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notificationStyle', style);
    
    // תזמון מחדש של כל ההתראות לפי הסגנון החדש
    await NotificationService.instance.rescheduleAll();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    state = state.copyWith(reminderTime: time);
    final prefs = await SharedPreferences.getInstance();
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await prefs.setString('reminderTime', timeStr);
    
    // תזמון מחדש של כל ההתראות לשעה החדשה
    await NotificationService.instance.rescheduleAll();
  }
  
  String get formattedReminderTime {
    final h = state.reminderTime.hour.toString().padLeft(2, '0');
    final m = state.reminderTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});