// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Recurring Tasks';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deletePermanently => 'Delete permanently';

  @override
  String get newAction => 'New';

  @override
  String get task => 'Task';

  @override
  String get item => 'Item';

  @override
  String get category => 'Group';

  @override
  String get all => 'All';

  @override
  String get noTasks => 'No urgent tasks right now!';

  @override
  String get activeTasks => 'Active tasks';

  @override
  String get overdueTasks => 'Overdue';

  @override
  String get doneNow => 'Done now';

  @override
  String get myGroups => 'My groups';

  @override
  String get name => 'Name';

  @override
  String get description => 'Description (optional)';

  @override
  String get repeatEvery => 'Repeat every';

  @override
  String get days => 'days';

  @override
  String get weeks => 'weeks';

  @override
  String get months => 'months';

  @override
  String get years => 'years';

  @override
  String get requiredField => 'Required field';

  @override
  String get selectCategory => 'Group';

  @override
  String get selectItem => 'Item';

  @override
  String get addTaskTitleHint => 'Add task title';

  @override
  String get addItemTitleHint => 'Item name';

  @override
  String get addCategoryTitleHint => 'Group name';

  @override
  String get color => 'Color (optional)';

  @override
  String get icon => 'Icon (optional)';

  @override
  String get addQuick => '+ New';

  @override
  String get endConditionTitle => 'Duration';

  @override
  String get endConditionAlways => 'Always';

  @override
  String get endConditionCount => 'Specific number of times';

  @override
  String get endConditionUntil => 'Until date';

  @override
  String get selectDate => 'Select date';

  @override
  String get times => 'times';

  @override
  String savedSuccessfully(String entityName, String repositoryName) {
    return '$entityName saved to $repositoryName';
  }

  @override
  String get lightMode => 'Light mode';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get systemMode => 'System settings';

  @override
  String dueDateLabel(String date) {
    return 'Due: $date';
  }

  @override
  String overdueDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }
}
