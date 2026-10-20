import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring Tasks'**
  String get appTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deletePermanently;

  /// No description provided for @newAction.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newAction;

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get category;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No urgent tasks right now!'**
  String get noTasks;

  /// No description provided for @activeTasks.
  ///
  /// In en, this message translates to:
  /// **'Active tasks'**
  String get activeTasks;

  /// No description provided for @overdueTasks.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueTasks;

  /// No description provided for @doneNow.
  ///
  /// In en, this message translates to:
  /// **'Done now'**
  String get doneNow;

  /// No description provided for @myGroups.
  ///
  /// In en, this message translates to:
  /// **'My groups'**
  String get myGroups;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get description;

  /// No description provided for @repeatEvery.
  ///
  /// In en, this message translates to:
  /// **'Repeat every'**
  String get repeatEvery;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get weeks;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get requiredField;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get selectCategory;

  /// No description provided for @selectItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get selectItem;

  /// No description provided for @addTaskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Add task title'**
  String get addTaskTitleHint;

  /// No description provided for @addItemTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get addItemTitleHint;

  /// No description provided for @addCategoryTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get addCategoryTitleHint;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color (optional)'**
  String get color;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon (optional)'**
  String get icon;

  /// No description provided for @addQuick.
  ///
  /// In en, this message translates to:
  /// **'+ New'**
  String get addQuick;

  /// No description provided for @endConditionTitle.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get endConditionTitle;

  /// No description provided for @endConditionAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get endConditionAlways;

  /// No description provided for @endConditionCount.
  ///
  /// In en, this message translates to:
  /// **'Number of times'**
  String get endConditionCount;

  /// No description provided for @endConditionUntil.
  ///
  /// In en, this message translates to:
  /// **'Until date'**
  String get endConditionUntil;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @times.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get times;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{entityName} saved to {repositoryName}'**
  String savedSuccessfully(String entityName, String repositoryName);

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System settings'**
  String get systemMode;

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String dueDateLabel(String date);

  /// No description provided for @overdueDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day overdue} other{{count} days overdue}}'**
  String overdueDays(int count);

  /// No description provided for @backupSection.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupSection;

  /// No description provided for @backupExport.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get backupExport;

  /// No description provided for @backupExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save all data to a file (Drive, WhatsApp, Files...)'**
  String get backupExportSubtitle;

  /// No description provided for @backupImport.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get backupImport;

  /// No description provided for @backupImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Load a backup file, replacing current data'**
  String get backupImportSubtitle;

  /// No description provided for @backupImportConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup?'**
  String get backupImportConfirmTitle;

  /// No description provided for @backupImportConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All current groups, items and tasks will be replaced by the file\'s content. Consider exporting a backup of the current data first.'**
  String get backupImportConfirmBody;

  /// No description provided for @backupImportConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get backupImportConfirmAction;

  /// No description provided for @backupImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully'**
  String get backupImportSuccess;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String backupFailed(String error);

  /// No description provided for @addItemToGroup.
  ///
  /// In en, this message translates to:
  /// **'Add item to group'**
  String get addItemToGroup;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @allGroups.
  ///
  /// In en, this message translates to:
  /// **'All groups'**
  String get allGroups;

  /// No description provided for @noGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get noGroupsYet;

  /// No description provided for @errorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetails(String error);

  /// No description provided for @deleteGroupWarning.
  ///
  /// In en, this message translates to:
  /// **'Deleting the group also deletes all of its items and tasks. Continue?'**
  String get deleteGroupWarning;

  /// No description provided for @deleteItemWarning.
  ///
  /// In en, this message translates to:
  /// **'Deleting the item also deletes all of its tasks. Continue?'**
  String get deleteItemWarning;

  /// No description provided for @deleteNamed.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String deleteNamed(String name);

  /// No description provided for @organizeGroups.
  ///
  /// In en, this message translates to:
  /// **'Organize groups'**
  String get organizeGroups;

  /// No description provided for @organizeNamed.
  ///
  /// In en, this message translates to:
  /// **'Organize: {name}'**
  String organizeNamed(String name);

  /// No description provided for @doneReordering.
  ///
  /// In en, this message translates to:
  /// **'Done reordering'**
  String get doneReordering;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add new'**
  String get addNew;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data to show.'**
  String get noData;

  /// No description provided for @editItemNamed.
  ///
  /// In en, this message translates to:
  /// **'Edit item: {name}'**
  String editItemNamed(String name);

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get deleteItem;

  /// No description provided for @deleteItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the item \"{name}\" and all of its tasks?'**
  String deleteItemConfirm(String name);

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @chooseGroupIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose group icon'**
  String get chooseGroupIcon;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get editGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroup;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the group \"{name}\"? All of its items and tasks will be permanently deleted.'**
  String deleteGroupConfirm(String name);

  /// No description provided for @groupIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Group icon:'**
  String get groupIconLabel;

  /// No description provided for @changeIcon.
  ///
  /// In en, this message translates to:
  /// **'Change icon'**
  String get changeIcon;

  /// No description provided for @groupColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Group color:'**
  String get groupColorLabel;

  /// No description provided for @groupNameExists.
  ///
  /// In en, this message translates to:
  /// **'A group with this name already exists'**
  String get groupNameExists;

  /// No description provided for @openMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get openMenu;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tasks, items or groups...'**
  String get searchHint;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type to search tasks, items or groups...'**
  String get searchPrompt;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @tasksHeader.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksHeader;

  /// No description provided for @itemsHeader.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsHeader;

  /// No description provided for @groupsHeader.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsHeader;

  /// No description provided for @searchTaskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Task • {item} • {group}'**
  String searchTaskSubtitle(String item, String group);

  /// No description provided for @searchItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Item • in group: {group}'**
  String searchItemSubtitle(String group);

  /// No description provided for @mainGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get mainGroup;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @allWithCount.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String allWithCount(int count);

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItem;

  /// No description provided for @noTasksInGroup.
  ///
  /// In en, this message translates to:
  /// **'No tasks to show in this group'**
  String get noTasksInGroup;

  /// No description provided for @goToGroupNamed.
  ///
  /// In en, this message translates to:
  /// **'Go to group \"{name}\"'**
  String goToGroupNamed(String name);

  /// No description provided for @pressAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press again to exit'**
  String get pressAgainToExit;

  /// No description provided for @allGroupsAndTasks.
  ///
  /// In en, this message translates to:
  /// **'All groups and tasks'**
  String get allGroupsAndTasks;

  /// No description provided for @summaryWithOverdue.
  ///
  /// In en, this message translates to:
  /// **'{active, plural, =1{1 active task} other{{active} active tasks}} • {overdue} overdue'**
  String summaryWithOverdue(int active, int overdue);

  /// No description provided for @summaryAllClear.
  ///
  /// In en, this message translates to:
  /// **'{active, plural, =1{1 active task} other{{active} active tasks}} • all up to date 🎉'**
  String summaryAllClear(int active);

  /// No description provided for @groupOptions.
  ///
  /// In en, this message translates to:
  /// **'Group options'**
  String get groupOptions;

  /// No description provided for @noTasksNow.
  ///
  /// In en, this message translates to:
  /// **'No tasks to show right now'**
  String get noTasksNow;

  /// No description provided for @frequencyDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Frequency: every day} other{Frequency: every {n} days}}'**
  String frequencyDays(int n);

  /// No description provided for @frequencyWeeks.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Frequency: every week} other{Frequency: every {n} weeks}}'**
  String frequencyWeeks(int n);

  /// No description provided for @frequencyMonths.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Frequency: every month} other{Frequency: every {n} months}}'**
  String frequencyMonths(int n);

  /// No description provided for @frequencyYears.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Frequency: every year} other{Frequency: every {n} years}}'**
  String frequencyYears(int n);

  /// No description provided for @calendarUpdatedOnCompletion.
  ///
  /// In en, this message translates to:
  /// **'Updated after task completion'**
  String get calendarUpdatedOnCompletion;

  /// No description provided for @taskCompletedNext.
  ///
  /// In en, this message translates to:
  /// **'Task \"{name}\" completed! Next due: {date}'**
  String taskCompletedNext(String name, String date);

  /// No description provided for @pickActualCompletionDate.
  ///
  /// In en, this message translates to:
  /// **'Pick the actual completion date'**
  String get pickActualCompletionDate;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @neverDone.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get neverDone;

  /// No description provided for @lastDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Last done: {date}'**
  String lastDoneLabel(String date);

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @manualCompletion.
  ///
  /// In en, this message translates to:
  /// **'Log past completion'**
  String get manualCompletion;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get newGroup;

  /// No description provided for @newItem.
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get newItem;

  /// No description provided for @calendarGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group: {name}'**
  String calendarGroupLabel(String name);

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(String error);

  /// No description provided for @createNew.
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get createNew;

  /// No description provided for @chooseIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose icon'**
  String get chooseIcon;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get quantity;

  /// No description provided for @remindMe.
  ///
  /// In en, this message translates to:
  /// **'Get a device reminder'**
  String get remindMe;

  /// No description provided for @reminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shown according to your notification settings'**
  String get reminderSubtitle;

  /// No description provided for @syncGoogleCalendar.
  ///
  /// In en, this message translates to:
  /// **'Sync to Google Calendar'**
  String get syncGoogleCalendar;

  /// No description provided for @willCreateAllDayEvent.
  ///
  /// In en, this message translates to:
  /// **'An all-day event will be created'**
  String get willCreateAllDayEvent;

  /// No description provided for @connectInSettings.
  ///
  /// In en, this message translates to:
  /// **'Sign in from the Settings screen'**
  String get connectInSettings;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get deleteTask;

  /// No description provided for @deleteTaskConfirm.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete the task \"{name}\"?'**
  String deleteTaskConfirm(String name);

  /// No description provided for @taskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get taskDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(String error);

  /// No description provided for @taskNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Task name'**
  String get taskNameLabel;

  /// No description provided for @errorLoadingGroups.
  ///
  /// In en, this message translates to:
  /// **'Failed to load groups'**
  String get errorLoadingGroups;

  /// No description provided for @errorLoadingItems.
  ///
  /// In en, this message translates to:
  /// **'Failed to load items'**
  String get errorLoadingItems;

  /// No description provided for @chooseGroupFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a group first'**
  String get chooseGroupFirst;

  /// No description provided for @eventWillUpdate.
  ///
  /// In en, this message translates to:
  /// **'The calendar event will be updated'**
  String get eventWillUpdate;

  /// No description provided for @fillNameAndItem.
  ///
  /// In en, this message translates to:
  /// **'Please enter a task name and choose an item'**
  String get fillNameAndItem;

  /// No description provided for @calendarAddedFromApp.
  ///
  /// In en, this message translates to:
  /// **'Added from Pets & Maintenance'**
  String get calendarAddedFromApp;

  /// No description provided for @calendarUpdatedFromApp.
  ///
  /// In en, this message translates to:
  /// **'Updated from the app'**
  String get calendarUpdatedFromApp;

  /// No description provided for @savedOk.
  ///
  /// In en, this message translates to:
  /// **'Saved!'**
  String get savedOk;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @notificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications & reminders'**
  String get notificationsSection;

  /// No description provided for @notifSeparated.
  ///
  /// In en, this message translates to:
  /// **'Separate'**
  String get notifSeparated;

  /// No description provided for @notifGrouped.
  ///
  /// In en, this message translates to:
  /// **'Grouped'**
  String get notifGrouped;

  /// No description provided for @notifNone.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notifNone;

  /// No description provided for @notifGroupedDesc.
  ///
  /// In en, this message translates to:
  /// **'One daily notification with all of the day\'s tasks'**
  String get notifGroupedDesc;

  /// No description provided for @notifSeparatedDesc.
  ///
  /// In en, this message translates to:
  /// **'A separate notification for each task'**
  String get notifSeparatedDesc;

  /// No description provided for @notifNoneDesc.
  ///
  /// In en, this message translates to:
  /// **'App notifications are off'**
  String get notifNoneDesc;

  /// No description provided for @dailyReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder time'**
  String get dailyReminderTime;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications off'**
  String get notificationsOff;

  /// No description provided for @reminderAt.
  ///
  /// In en, this message translates to:
  /// **'At {time} (tap to change)'**
  String reminderAt(String time);

  /// No description provided for @pickReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Pick reminder time'**
  String get pickReminderTime;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @reminderTimeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Reminder time updated'**
  String get reminderTimeUpdated;

  /// No description provided for @syncSection.
  ///
  /// In en, this message translates to:
  /// **'Sync & services'**
  String get syncSection;

  /// No description provided for @googleCalendarSync.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar sync'**
  String get googleCalendarSync;

  /// No description provided for @connectedAs.
  ///
  /// In en, this message translates to:
  /// **'Connected:\n{email}'**
  String connectedAs(String email);

  /// No description provided for @notConnectedGoogle.
  ///
  /// In en, this message translates to:
  /// **'Not connected to Google Calendar'**
  String get notConnectedGoogle;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @contentSection.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get contentSection;

  /// No description provided for @organizeGroupsItems.
  ///
  /// In en, this message translates to:
  /// **'Organize groups & items'**
  String get organizeGroupsItems;

  /// No description provided for @organizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Edit, delete and reorder content'**
  String get organizeSubtitle;

  /// No description provided for @notifChannelName.
  ///
  /// In en, this message translates to:
  /// **'Tasks & maintenance'**
  String get notifChannelName;

  /// No description provided for @notifChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminders for your home tasks'**
  String get notifChannelDesc;

  /// No description provided for @notifTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder: {name}'**
  String notifTaskTitle(String name);

  /// No description provided for @notifTaskDefaultBody.
  ///
  /// In en, this message translates to:
  /// **'Time to do this task'**
  String get notifTaskDefaultBody;

  /// No description provided for @notifGroupedTitle.
  ///
  /// In en, this message translates to:
  /// **'🏠 Today\'s tasks'**
  String get notifGroupedTitle;

  /// No description provided for @notifGroupedBody.
  ///
  /// In en, this message translates to:
  /// **'You have maintenance tasks due today. Open the app for details.'**
  String get notifGroupedBody;

  /// No description provided for @calendarEventTitle.
  ///
  /// In en, this message translates to:
  /// **'🏠 Maintenance: {name}'**
  String calendarEventTitle(String name);

  /// No description provided for @calendarAutoCreated.
  ///
  /// In en, this message translates to:
  /// **'Created automatically by Pets & Maintenance'**
  String get calendarAutoCreated;

  /// No description provided for @generalSection.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalSection;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get followSystem;

  /// No description provided for @notificationStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification style'**
  String get notificationStyleTitle;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @versionTitle.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionTitle;

  /// No description provided for @dateFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'Date format'**
  String get dateFormatTitle;

  /// No description provided for @dateFormatAuto.
  ///
  /// In en, this message translates to:
  /// **'By language'**
  String get dateFormatAuto;

  /// No description provided for @dateFormatDmy.
  ///
  /// In en, this message translates to:
  /// **'Day/Month/Year'**
  String get dateFormatDmy;

  /// No description provided for @dateFormatMdy.
  ///
  /// In en, this message translates to:
  /// **'Month/Day/Year'**
  String get dateFormatMdy;

  /// No description provided for @dateFormatYmd.
  ///
  /// In en, this message translates to:
  /// **'Year-Month-Day'**
  String get dateFormatYmd;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect to Google. Check your connection and try again.'**
  String get googleSignInFailed;

  /// No description provided for @googleConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to Google Calendar'**
  String get googleConnected;

  /// No description provided for @googleDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected from Google Calendar'**
  String get googleDisconnected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
