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
  /// **'Specific number of times'**
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
