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

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deletePermanently;

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

  /// No description provided for @overdueTasks.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueTasks;

  /// No description provided for @myGroups.
  ///
  /// In en, this message translates to:
  /// **'My groups'**
  String get myGroups;

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

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{entityName} saved to {repositoryName}'**
  String savedSuccessfully(String entityName, String repositoryName);

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String dueDateLabel(String date);

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
  /// **'Device reminder'**
  String get remindMe;

  /// No description provided for @syncGoogleCalendar.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar'**
  String get syncGoogleCalendar;

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

  /// No description provided for @fillNameAndItem.
  ///
  /// In en, this message translates to:
  /// **'Please enter a task name and choose an item'**
  String get fillNameAndItem;

  /// No description provided for @calendarAddedFromApp.
  ///
  /// In en, this message translates to:
  /// **'Added from PETS'**
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
  /// **'🐾 Today\'s tasks'**
  String get notifGroupedTitle;

  /// No description provided for @notifGroupedBody.
  ///
  /// In en, this message translates to:
  /// **'You have maintenance tasks due today. Open the app for details.'**
  String get notifGroupedBody;

  /// No description provided for @calendarEventTitle.
  ///
  /// In en, this message translates to:
  /// **'🐾 Maintenance: {name}'**
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

  /// No description provided for @finishedTasks.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finishedTasks;

  /// No description provided for @taskFinishedLabel.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get taskFinishedLabel;

  /// No description provided for @extraCompletionLogged.
  ///
  /// In en, this message translates to:
  /// **'Additional completion logged ✓'**
  String get extraCompletionLogged;

  /// No description provided for @calendarCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Saved, but not added to Google Calendar. You can try again by editing the task.'**
  String get calendarCreateFailed;

  /// No description provided for @calendarSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Changes saved, but Google Calendar wasn\'t updated. Check your connection and try again.'**
  String get calendarSyncFailed;

  /// No description provided for @calendarDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Task deleted, but the event is still in Google Calendar. You can delete it manually.'**
  String get calendarDeleteFailed;

  /// No description provided for @calendarNotUpdated.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar wasn\'t updated (offline?)'**
  String get calendarNotUpdated;

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day} other{{n} days}}'**
  String durationDays(int n);

  /// No description provided for @monthsApproxOne.
  ///
  /// In en, this message translates to:
  /// **'about a month'**
  String get monthsApproxOne;

  /// No description provided for @monthsApproxTwo.
  ///
  /// In en, this message translates to:
  /// **'about 2 months'**
  String get monthsApproxTwo;

  /// No description provided for @monthsApproxMany.
  ///
  /// In en, this message translates to:
  /// **'about {n} months'**
  String monthsApproxMany(String n);

  /// No description provided for @overdueBy.
  ///
  /// In en, this message translates to:
  /// **'{duration} overdue'**
  String overdueBy(String duration);

  /// No description provided for @taskAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Task tracking analysis'**
  String get taskAnalysisTitle;

  /// No description provided for @everyDays.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{every day} other{every {n} days}}'**
  String everyDays(int n);

  /// No description provided for @everyWeeks.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{every week} other{every {n} weeks}}'**
  String everyWeeks(int n);

  /// No description provided for @everyMonths.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{every month} other{every {n} months}}'**
  String everyMonths(int n);

  /// No description provided for @everyHalfYear.
  ///
  /// In en, this message translates to:
  /// **'every 6 months'**
  String get everyHalfYear;

  /// No description provided for @everyYears.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{every year} other{every {n} years}}'**
  String everyYears(int n);

  /// No description provided for @detailReminder.
  ///
  /// In en, this message translates to:
  /// **'Task reminder'**
  String get detailReminder;

  /// No description provided for @detailCalendar.
  ///
  /// In en, this message translates to:
  /// **'Task event'**
  String get detailCalendar;

  /// No description provided for @detailNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due'**
  String get detailNextDue;

  /// No description provided for @detailLastDone.
  ///
  /// In en, this message translates to:
  /// **'Last done'**
  String get detailLastDone;

  /// No description provided for @detailActiveSince.
  ///
  /// In en, this message translates to:
  /// **'Active since'**
  String get detailActiveSince;

  /// No description provided for @endCountProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} times'**
  String endCountProgress(int done, int total);

  /// No description provided for @endUntilDate.
  ///
  /// In en, this message translates to:
  /// **'until {date}'**
  String endUntilDate(String date);

  /// No description provided for @reminderOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get reminderOff;

  /// No description provided for @reminderActive.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get reminderActive;

  /// No description provided for @calendarSynced.
  ///
  /// In en, this message translates to:
  /// **'In Google Calendar'**
  String get calendarSynced;

  /// No description provided for @calendarNotSynced.
  ///
  /// In en, this message translates to:
  /// **'Not in Google Calendar'**
  String get calendarNotSynced;

  /// No description provided for @healthOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get healthOnTrack;

  /// No description provided for @healthAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get healthAttention;

  /// No description provided for @statusNextIn.
  ///
  /// In en, this message translates to:
  /// **'Next due in {duration}'**
  String statusNextIn(String duration);

  /// No description provided for @statusDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get statusDueToday;

  /// No description provided for @statusStreak.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 on time} other{{n} on time in a row}}'**
  String statusStreak(int n);

  /// No description provided for @statusTendsLate.
  ///
  /// In en, this message translates to:
  /// **'lately tends to be late'**
  String get statusTendsLate;

  /// No description provided for @statusFinishedAfter.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Finished after 1 completion} other{Finished after {n} completions}}'**
  String statusFinishedAfter(int n);

  /// No description provided for @statCompletions.
  ///
  /// In en, this message translates to:
  /// **'Completions'**
  String get statCompletions;

  /// No description provided for @statOnTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get statOnTime;

  /// No description provided for @statActualEvery.
  ///
  /// In en, this message translates to:
  /// **'Avg. every'**
  String get statActualEvery;

  /// No description provided for @unitDay.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get unitDay;

  /// No description provided for @unitMonth.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get unitMonth;

  /// No description provided for @whenTitle.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get whenTitle;

  /// No description provided for @whenSentence.
  ///
  /// In en, this message translates to:
  /// **'Usually on {day}, mostly at the {part}'**
  String whenSentence(String day, String part);

  /// No description provided for @whenWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Days of the week'**
  String get whenWeekdays;

  /// No description provided for @whenMonthPart.
  ///
  /// In en, this message translates to:
  /// **'Part of the month'**
  String get whenMonthPart;

  /// No description provided for @monthPartStart.
  ///
  /// In en, this message translates to:
  /// **'start of the month'**
  String get monthPartStart;

  /// No description provided for @monthPartMiddle.
  ///
  /// In en, this message translates to:
  /// **'middle of the month'**
  String get monthPartMiddle;

  /// No description provided for @monthPartEnd.
  ///
  /// In en, this message translates to:
  /// **'end of the month'**
  String get monthPartEnd;

  /// No description provided for @monthPartStartShort.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get monthPartStartShort;

  /// No description provided for @monthPartMiddleShort.
  ///
  /// In en, this message translates to:
  /// **'Mid'**
  String get monthPartMiddleShort;

  /// No description provided for @monthPartEndShort.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get monthPartEndShort;

  /// No description provided for @noCompletionsYet.
  ///
  /// In en, this message translates to:
  /// **'No completions yet. The analysis will appear after the first one.'**
  String get noCompletionsYet;

  /// No description provided for @paceTitle.
  ///
  /// In en, this message translates to:
  /// **'Your pace'**
  String get paceTitle;

  /// No description provided for @paceLateInLast.
  ///
  /// In en, this message translates to:
  /// **'{late, plural, =1{1 late in the last {n}} other{{late} late in the last {n}}}'**
  String paceLateInLast(int late, int n);

  /// No description provided for @paceAllOnTime.
  ///
  /// In en, this message translates to:
  /// **'All on time in the last {n}'**
  String paceAllOnTime(int n);

  /// No description provided for @paceLastOnTime.
  ///
  /// In en, this message translates to:
  /// **'Last one on time'**
  String get paceLastOnTime;

  /// No description provided for @paceLastLate.
  ///
  /// In en, this message translates to:
  /// **'Last one late'**
  String get paceLastLate;

  /// No description provided for @paceCaptionDays.
  ///
  /// In en, this message translates to:
  /// **'Early (↓) or late (↑) vs. the {target}-day target'**
  String paceCaptionDays(String target);

  /// No description provided for @paceCaptionMonths.
  ///
  /// In en, this message translates to:
  /// **'Early (↓) or late (↑) vs. the {target}-month target'**
  String paceCaptionMonths(String target);

  /// No description provided for @paceFastest.
  ///
  /// In en, this message translates to:
  /// **'Fastest'**
  String get paceFastest;

  /// No description provided for @paceSlowest.
  ///
  /// In en, this message translates to:
  /// **'Slowest'**
  String get paceSlowest;

  /// No description provided for @paceNeedTwo.
  ///
  /// In en, this message translates to:
  /// **'At least 2 completions are needed to show a pace.'**
  String get paceNeedTwo;

  /// No description provided for @calTitle.
  ///
  /// In en, this message translates to:
  /// **'Task calendar'**
  String get calTitle;

  /// No description provided for @calChip.
  ///
  /// In en, this message translates to:
  /// **'{period}: {n, plural, =0{no completions} =1{1 completion} other{{n} completions}}'**
  String calChip(String period, int n);

  /// No description provided for @recordLongestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest streak'**
  String get recordLongestStreak;

  /// No description provided for @recordStreakValue.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{none yet} =1{1 on time} other{{n} on time in a row}}'**
  String recordStreakValue(int n);

  /// No description provided for @recordBiggestLate.
  ///
  /// In en, this message translates to:
  /// **'Biggest delay'**
  String get recordBiggestLate;

  /// No description provided for @recordNoLate.
  ///
  /// In en, this message translates to:
  /// **'No delays 🎉'**
  String get recordNoLate;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyChip.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 completion · {date}} other{{n} completions · last {date}}}'**
  String historyChip(int n, String date);

  /// No description provided for @historyShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all ({n})'**
  String historyShowAll(int n);

  /// No description provided for @historyShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get historyShowLess;

  /// No description provided for @fixCompletionDate.
  ///
  /// In en, this message translates to:
  /// **'Fix date'**
  String get fixCompletionDate;

  /// No description provided for @deleteCompletion.
  ///
  /// In en, this message translates to:
  /// **'Delete completion'**
  String get deleteCompletion;

  /// No description provided for @deleteCompletionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete the completion from {date}? The count and last-done date will update. The next due date won\'t change.'**
  String deleteCompletionConfirm(String date);

  /// No description provided for @completionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Completion date updated'**
  String get completionUpdated;

  /// No description provided for @completionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Completion deleted'**
  String get completionDeleted;

  /// No description provided for @crashReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Send error reports'**
  String get crashReportsTitle;

  /// No description provided for @crashReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anonymous, without your content'**
  String get crashReportsSubtitle;

  /// No description provided for @crashReportsInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Anonymous error reports'**
  String get crashReportsInfoTitle;

  /// No description provided for @crashReportsInfoIntro.
  ///
  /// In en, this message translates to:
  /// **'When something goes wrong in the app (a crash, or an action that failed, like syncing to the calendar), a short technical report is sent so the problem can be found and fixed.'**
  String get crashReportsInfoIntro;

  /// No description provided for @crashReportsInfoSentTitle.
  ///
  /// In en, this message translates to:
  /// **'What is sent'**
  String get crashReportsInfoSentTitle;

  /// No description provided for @crashReportsInfoSent.
  ///
  /// In en, this message translates to:
  /// **'A description of the error and where it happened in the code, the device model, the Android version and the app version.'**
  String get crashReportsInfoSent;

  /// No description provided for @crashReportsInfoNotSentTitle.
  ///
  /// In en, this message translates to:
  /// **'What is never sent'**
  String get crashReportsInfoNotSentTitle;

  /// No description provided for @crashReportsInfoNotSent.
  ///
  /// In en, this message translates to:
  /// **'Names of tasks, groups and items, dates, your email, or any other content you entered.'**
  String get crashReportsInfoNotSent;

  /// No description provided for @crashReportsInfoFooter.
  ///
  /// In en, this message translates to:
  /// **'Reports are stored in Google Firebase. You can turn sending off at any time with the switch.'**
  String get crashReportsInfoFooter;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @completionUndone.
  ///
  /// In en, this message translates to:
  /// **'Completion undone'**
  String get completionUndone;

  /// No description provided for @completionUndoneCalendarFailed.
  ///
  /// In en, this message translates to:
  /// **'Completion undone, but Google Calendar wasn\'t updated'**
  String get completionUndoneCalendarFailed;

  /// No description provided for @nextDueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Next due date'**
  String get nextDueDateLabel;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get openSourceLicenses;

  /// No description provided for @sampleGroupHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get sampleGroupHome;

  /// No description provided for @sampleItemGarden.
  ///
  /// In en, this message translates to:
  /// **'Garden 🌱'**
  String get sampleItemGarden;

  /// No description provided for @sampleItemCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning 🧹'**
  String get sampleItemCleaning;

  /// No description provided for @sampleTaskWatering.
  ///
  /// In en, this message translates to:
  /// **'Water the plants (example)'**
  String get sampleTaskWatering;

  /// No description provided for @sampleGroupPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get sampleGroupPets;

  /// No description provided for @sampleTaskWaterBowl.
  ///
  /// In en, this message translates to:
  /// **'Clean the water bowl (example)'**
  String get sampleTaskWaterBowl;

  /// No description provided for @obWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome! 👋'**
  String get obWelcomeTitle;

  /// No description provided for @obWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'PETS 🐾 is a simple app that helps you manage recurring tasks.\n\nEverything has 3 levels: at the top you define a group (like Home). Inside it you can define items or topics (Cleaning, Garden), and items get recurring tasks (clean the air conditioner screens every 3 months, water the plants every 4 days).\n\nThere is no right way to define items and assign them to groups - organize it however suits you.'**
  String get obWelcomeBody;

  /// No description provided for @obNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get obNext;

  /// No description provided for @obSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get obSkip;

  /// No description provided for @obGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get obGotIt;

  /// No description provided for @obGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Group and item buttons'**
  String get obGroupsTitle;

  /// No description provided for @obGroupsBody.
  ///
  /// In en, this message translates to:
  /// **'These buttons filter the tasks below to the selected group or item. On the main page you see all your groups - long-press a group to open, edit or delete it. On a group page you see all of its items.'**
  String get obGroupsBody;

  /// No description provided for @obFabTitle.
  ///
  /// In en, this message translates to:
  /// **'Add everything from here'**
  String get obFabTitle;

  /// No description provided for @obFabBody.
  ///
  /// In en, this message translates to:
  /// **'A top-level group, an item inside a group, and of course recurring tasks.'**
  String get obFabBody;

  /// No description provided for @obMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Organize and settings'**
  String get obMenuTitle;

  /// No description provided for @obMenuBody.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings and to the Organize groups and items screen: edit, delete and reorder there - including the examples when you are done with them.'**
  String get obMenuBody;

  /// No description provided for @obDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'All set! 🐾'**
  String get obDoneTitle;

  /// No description provided for @obDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Phone reminders and Google Calendar sync are turned on per task, when you create or edit it. The calendar gets a single event, on the next due date of the task. You can replay this tour in Settings → About.'**
  String get obDoneBody;

  /// No description provided for @obReplay.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get obReplay;

  /// No description provided for @obCardTitle.
  ///
  /// In en, this message translates to:
  /// **'This is today’s task'**
  String get obCardTitle;

  /// No description provided for @obCardBody.
  ///
  /// In en, this message translates to:
  /// **'This screen shows all your tasks in the order they are due: today first, then tomorrow, and so on. Tap the task card to open it and see more details and actions.'**
  String get obCardBody;

  /// No description provided for @obCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Done? Tap \"Complete\"'**
  String get obCompleteTitle;

  /// No description provided for @obCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Try it now - tap the button.'**
  String get obCompleteBody;

  /// No description provided for @obNextDueTitle.
  ///
  /// In en, this message translates to:
  /// **'The due date was updated'**
  String get obNextDueTitle;

  /// No description provided for @obAnalysisButtonTitle.
  ///
  /// In en, this message translates to:
  /// **'Want to see how you are doing?'**
  String get obAnalysisButtonTitle;

  /// No description provided for @obAnalysisButtonBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the highlighted button to open the task analysis page.'**
  String get obAnalysisButtonBody;

  /// No description provided for @obAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance analysis'**
  String get obAnalysisTitle;

  /// No description provided for @obAnalysisBody.
  ///
  /// In en, this message translates to:
  /// **'This page tracks one task and analyzes how you do it, with charts and metrics. Each section opens to show more - tap the different sections. When you are done, go back and the tour will continue.'**
  String get obAnalysisBody;

  /// No description provided for @obManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Log a completion date manually'**
  String get obManualTitle;

  /// No description provided for @obManualBody.
  ///
  /// In en, this message translates to:
  /// **'Forgot to mark it in time? Want to add past completions to the history? Pick the date you actually did it. (You can delete completions in the history at the bottom of the analysis page.)'**
  String get obManualBody;

  /// No description provided for @obDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Duplicate task'**
  String get obDuplicateTitle;

  /// No description provided for @obDuplicateBody.
  ///
  /// In en, this message translates to:
  /// **'Opens a new-task window with the same settings as this task, to edit and confirm. Handy when similar tasks belong to different items.'**
  String get obDuplicateBody;

  /// No description provided for @obEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get obEditTitle;

  /// No description provided for @obEditBody.
  ///
  /// In en, this message translates to:
  /// **'Name, frequency, reminder, calendar and the next due date - and deleting the task.'**
  String get obEditBody;

  /// No description provided for @sampleItemCat.
  ///
  /// In en, this message translates to:
  /// **'Cat 🐱'**
  String get sampleItemCat;

  /// No description provided for @obDrawerTitle.
  ///
  /// In en, this message translates to:
  /// **'The side menu'**
  String get obDrawerTitle;

  /// No description provided for @obDrawerBody.
  ///
  /// In en, this message translates to:
  /// **'Quick switching between pages: the All groups page, which is the main page with no filters, and a page for every group you create.'**
  String get obDrawerBody;

  /// No description provided for @obBrowse.
  ///
  /// In en, this message translates to:
  /// **'Got it, let me look'**
  String get obBrowse;

  /// No description provided for @obStartCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Want to get to know PETS 🐾?'**
  String get obStartCardTitle;

  /// No description provided for @obStartCardBody.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Start\" and we will create two example groups, Home and Pets, with a \"Garden\" item in the Home group and a plant-watering task that already has a few weeks of history. The guide walks through every action and takes about 2-3 minutes.\n\nPrefer to start on your own? ✕ closes this offer. You can always replay the tour in Settings → About.'**
  String get obStartCardBody;

  /// No description provided for @obStartCardButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get obStartCardButton;

  /// No description provided for @obTapHint.
  ///
  /// In en, this message translates to:
  /// **'👆 Tap the highlighted area to continue'**
  String get obTapHint;

  /// No description provided for @obEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You have no tasks yet.'**
  String get obEmptyTitle;

  /// No description provided for @obEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a new task with the + button, or watch the new-user guide again:'**
  String get obEmptyBody;

  /// No description provided for @obEmptyLink.
  ///
  /// In en, this message translates to:
  /// **'New-user guide'**
  String get obEmptyLink;

  /// No description provided for @obSkippedHint.
  ///
  /// In en, this message translates to:
  /// **'The tour is closed. You can return to it in Settings → About.'**
  String get obSkippedHint;

  /// No description provided for @obNextDueBody.
  ///
  /// In en, this message translates to:
  /// **'The next due date is in 4 days.'**
  String get obNextDueBody;

  /// No description provided for @sampleTaskWateringDesc.
  ///
  /// In en, this message translates to:
  /// **'Water all the plants on the balcony and in the living room. On very hot days, check whether the soil is dry between waterings too.'**
  String get sampleTaskWateringDesc;

  /// No description provided for @sampleTaskWaterBowlDesc.
  ///
  /// In en, this message translates to:
  /// **'Wash the bowl in hot water, dry it and fill it with fresh water. Worth checking the food bowl too.'**
  String get sampleTaskWaterBowlDesc;

  /// No description provided for @calendarDeleteManyFailed.
  ///
  /// In en, this message translates to:
  /// **'Deleted, but some events stayed in Google Calendar. You can delete them manually.'**
  String get calendarDeleteManyFailed;

  /// No description provided for @completionSameDayExists.
  ///
  /// In en, this message translates to:
  /// **'There is already a completion on this date.'**
  String get completionSameDayExists;

  /// No description provided for @historyCompletionAdded.
  ///
  /// In en, this message translates to:
  /// **'The completion from {date} was added to the history. The next due date did not change.'**
  String historyCompletionAdded(String date);

  /// No description provided for @historyCompletionFinished.
  ///
  /// In en, this message translates to:
  /// **'The completion from {date} was added to the history, and the task reached its set number of times.'**
  String historyCompletionFinished(String date);

  /// No description provided for @historyManualChip.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get historyManualChip;

  /// No description provided for @paceAverage.
  ///
  /// In en, this message translates to:
  /// **'Average pace'**
  String get paceAverage;
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
