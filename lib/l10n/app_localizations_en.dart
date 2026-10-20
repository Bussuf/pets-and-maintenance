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
  String get endConditionCount => 'Number of times';

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

  @override
  String get backupSection => 'Backup & restore';

  @override
  String get backupExport => 'Export backup';

  @override
  String get backupExportSubtitle =>
      'Save all data to a file (Drive, WhatsApp, Files...)';

  @override
  String get backupImport => 'Restore from backup';

  @override
  String get backupImportSubtitle =>
      'Load a backup file, replacing current data';

  @override
  String get backupImportConfirmTitle => 'Restore from backup?';

  @override
  String get backupImportConfirmBody =>
      'All current groups, items and tasks will be replaced by the file\'s content. Consider exporting a backup of the current data first.';

  @override
  String get backupImportConfirmAction => 'Choose file';

  @override
  String get backupImportSuccess => 'Data restored successfully';

  @override
  String backupFailed(String error) {
    return 'Operation failed: $error';
  }

  @override
  String get addItemToGroup => 'Add item to group';

  @override
  String get languageSection => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get allGroups => 'All groups';

  @override
  String get noGroupsYet => 'No groups yet';

  @override
  String errorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String get deleteGroupWarning =>
      'Deleting the group also deletes all of its items and tasks. Continue?';

  @override
  String get deleteItemWarning =>
      'Deleting the item also deletes all of its tasks. Continue?';

  @override
  String deleteNamed(String name) {
    return 'Delete $name';
  }

  @override
  String get organizeGroups => 'Organize groups';

  @override
  String organizeNamed(String name) {
    return 'Organize: $name';
  }

  @override
  String get doneReordering => 'Done reordering';

  @override
  String get reorder => 'Reorder';

  @override
  String get addNew => 'Add new';

  @override
  String get noData => 'No data to show.';

  @override
  String editItemNamed(String name) {
    return 'Edit item: $name';
  }

  @override
  String get deleteItem => 'Delete item';

  @override
  String deleteItemConfirm(String name) {
    return 'Delete the item \"$name\" and all of its tasks?';
  }

  @override
  String get saveChanges => 'Save changes';

  @override
  String get chooseGroupIcon => 'Choose group icon';

  @override
  String get editGroup => 'Edit group';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String deleteGroupConfirm(String name) {
    return 'Delete the group \"$name\"? All of its items and tasks will be permanently deleted.';
  }

  @override
  String get groupIconLabel => 'Group icon:';

  @override
  String get changeIcon => 'Change icon';

  @override
  String get groupColorLabel => 'Group color:';

  @override
  String get groupNameExists => 'A group with this name already exists';

  @override
  String get openMenu => 'Menu';

  @override
  String get searchHint => 'Search tasks, items or groups...';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get searchPrompt => 'Type to search tasks, items or groups...';

  @override
  String get noResults => 'No results found';

  @override
  String get tasksHeader => 'Tasks';

  @override
  String get itemsHeader => 'Items';

  @override
  String get groupsHeader => 'Groups';

  @override
  String searchTaskSubtitle(String item, String group) {
    return 'Task • $item • $group';
  }

  @override
  String searchItemSubtitle(String group) {
    return 'Item • in group: $group';
  }

  @override
  String get mainGroup => 'Group';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get later => 'Later';

  @override
  String allWithCount(int count) {
    return 'All ($count)';
  }

  @override
  String get editItem => 'Edit item';

  @override
  String get noTasksInGroup => 'No tasks to show in this group';

  @override
  String goToGroupNamed(String name) {
    return 'Go to group \"$name\"';
  }

  @override
  String get pressAgainToExit => 'Press again to exit';

  @override
  String get allGroupsAndTasks => 'All groups and tasks';

  @override
  String summaryWithOverdue(int active, int overdue) {
    String _temp0 = intl.Intl.pluralLogic(
      active,
      locale: localeName,
      other: '$active active tasks',
      one: '1 active task',
    );
    return '$_temp0 • $overdue overdue';
  }

  @override
  String summaryAllClear(int active) {
    String _temp0 = intl.Intl.pluralLogic(
      active,
      locale: localeName,
      other: '$active active tasks',
      one: '1 active task',
    );
    return '$_temp0 • all up to date 🎉';
  }

  @override
  String get groupOptions => 'Group options';

  @override
  String get noTasksNow => 'No tasks to show right now';

  @override
  String frequencyDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Frequency: every $n days',
      one: 'Frequency: every day',
    );
    return '$_temp0';
  }

  @override
  String frequencyWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Frequency: every $n weeks',
      one: 'Frequency: every week',
    );
    return '$_temp0';
  }

  @override
  String frequencyMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Frequency: every $n months',
      one: 'Frequency: every month',
    );
    return '$_temp0';
  }

  @override
  String frequencyYears(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Frequency: every $n years',
      one: 'Frequency: every year',
    );
    return '$_temp0';
  }

  @override
  String get calendarUpdatedOnCompletion => 'Updated after task completion';

  @override
  String taskCompletedNext(String name, String date) {
    return 'Task \"$name\" completed! Next due: $date';
  }

  @override
  String get pickActualCompletionDate => 'Pick the actual completion date';

  @override
  String get general => 'General';

  @override
  String get notSet => 'Not set';

  @override
  String get neverDone => 'Never';

  @override
  String lastDoneLabel(String date) {
    return 'Last done: $date';
  }

  @override
  String get complete => 'Complete';

  @override
  String get statistics => 'Statistics';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get manualCompletion => 'Log past completion';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get edit => 'Edit';

  @override
  String get newGroup => 'New group';

  @override
  String get newItem => 'New item';

  @override
  String calendarGroupLabel(String name) {
    return 'Group: $name';
  }

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get createNew => 'Create new';

  @override
  String get chooseIcon => 'Choose icon';

  @override
  String get quantity => 'Count';

  @override
  String get remindMe => 'Get a device reminder';

  @override
  String get reminderSubtitle =>
      'Shown according to your notification settings';

  @override
  String get syncGoogleCalendar => 'Sync to Google Calendar';

  @override
  String get willCreateAllDayEvent => 'An all-day event will be created';

  @override
  String get connectInSettings => 'Sign in from the Settings screen';

  @override
  String get editTask => 'Edit task';

  @override
  String get deleteTask => 'Delete task';

  @override
  String deleteTaskConfirm(String name) {
    return 'Permanently delete the task \"$name\"?';
  }

  @override
  String get taskDeleted => 'Task deleted';

  @override
  String deleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get taskNameLabel => 'Task name';

  @override
  String get errorLoadingGroups => 'Failed to load groups';

  @override
  String get errorLoadingItems => 'Failed to load items';

  @override
  String get chooseGroupFirst => 'Choose a group first';

  @override
  String get eventWillUpdate => 'The calendar event will be updated';

  @override
  String get fillNameAndItem => 'Please enter a task name and choose an item';

  @override
  String get calendarAddedFromApp => 'Added from Pets & Maintenance';

  @override
  String get calendarUpdatedFromApp => 'Updated from the app';

  @override
  String get savedOk => 'Saved!';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get notificationsSection => 'Notifications & reminders';

  @override
  String get notifSeparated => 'Separate';

  @override
  String get notifGrouped => 'Grouped';

  @override
  String get notifNone => 'Off';

  @override
  String get notifGroupedDesc =>
      'One daily notification with all of the day\'s tasks';

  @override
  String get notifSeparatedDesc => 'A separate notification for each task';

  @override
  String get notifNoneDesc => 'App notifications are off';

  @override
  String get dailyReminderTime => 'Daily reminder time';

  @override
  String get notificationsOff => 'Notifications off';

  @override
  String reminderAt(String time) {
    return 'At $time (tap to change)';
  }

  @override
  String get pickReminderTime => 'Pick reminder time';

  @override
  String get ok => 'OK';

  @override
  String get reminderTimeUpdated => 'Reminder time updated';

  @override
  String get syncSection => 'Sync & services';

  @override
  String get googleCalendarSync => 'Google Calendar sync';

  @override
  String connectedAs(String email) {
    return 'Connected:\n$email';
  }

  @override
  String get notConnectedGoogle => 'Not connected to Google Calendar';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get connect => 'Connect';

  @override
  String get contentSection => 'Content';

  @override
  String get organizeGroupsItems => 'Organize groups & items';

  @override
  String get organizeSubtitle => 'Edit, delete and reorder content';

  @override
  String get notifChannelName => 'Tasks & maintenance';

  @override
  String get notifChannelDesc => 'Reminders for your home tasks';

  @override
  String notifTaskTitle(String name) {
    return 'Reminder: $name';
  }

  @override
  String get notifTaskDefaultBody => 'Time to do this task';

  @override
  String get notifGroupedTitle => '🏠 Today\'s tasks';

  @override
  String get notifGroupedBody =>
      'You have maintenance tasks due today. Open the app for details.';

  @override
  String calendarEventTitle(String name) {
    return '🏠 Maintenance: $name';
  }

  @override
  String get calendarAutoCreated =>
      'Created automatically by Pets & Maintenance';

  @override
  String get generalSection => 'General';

  @override
  String get themeTitle => 'Theme';

  @override
  String get followSystem => 'System default';

  @override
  String get notificationStyleTitle => 'Notification style';

  @override
  String get aboutSection => 'About';

  @override
  String get versionTitle => 'Version';

  @override
  String get dateFormatTitle => 'Date format';

  @override
  String get dateFormatAuto => 'By language';

  @override
  String get dateFormatDmy => 'Day/Month/Year';

  @override
  String get dateFormatMdy => 'Month/Day/Year';

  @override
  String get dateFormatYmd => 'Year-Month-Day';

  @override
  String get googleSignInFailed =>
      'Couldn\'t connect to Google. Check your connection and try again.';

  @override
  String get googleConnected => 'Connected to Google Calendar';

  @override
  String get googleDisconnected => 'Disconnected from Google Calendar';

  @override
  String get finishedTasks => 'Finished';

  @override
  String get taskFinishedLabel => 'Finished';

  @override
  String get extraCompletionLogged => 'Additional completion logged ✓';

  @override
  String get calendarCreateFailed =>
      'Saved, but not added to Google Calendar. You can try again by editing the task.';

  @override
  String get calendarSyncFailed =>
      'Changes saved, but Google Calendar wasn\'t updated. Check your connection and try again.';

  @override
  String get calendarDeleteFailed =>
      'Task deleted, but the event is still in Google Calendar. You can delete it manually.';

  @override
  String get calendarNotUpdated => 'Google Calendar wasn\'t updated (offline?)';

  @override
  String durationDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get monthsApproxOne => 'about a month';

  @override
  String get monthsApproxTwo => 'about 2 months';

  @override
  String monthsApproxMany(String n) {
    return 'about $n months';
  }

  @override
  String overdueBy(String duration) {
    return '$duration overdue';
  }
}
