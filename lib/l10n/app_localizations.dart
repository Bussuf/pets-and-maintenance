import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  static const List<Locale> supportedLocales = <Locale>[Locale('he')];

  /// No description provided for @appTitle.
  ///
  /// In he, this message translates to:
  /// **'ניהול משימות חוזרות'**
  String get appTitle;

  /// No description provided for @save.
  ///
  /// In he, this message translates to:
  /// **'שמירה'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In he, this message translates to:
  /// **'ביטול'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In he, this message translates to:
  /// **'מחק'**
  String get delete;

  /// No description provided for @deletePermanently.
  ///
  /// In he, this message translates to:
  /// **'מחק לצמיתות'**
  String get deletePermanently;

  /// No description provided for @newAction.
  ///
  /// In he, this message translates to:
  /// **'חדש'**
  String get newAction;

  /// No description provided for @task.
  ///
  /// In he, this message translates to:
  /// **'משימה'**
  String get task;

  /// No description provided for @item.
  ///
  /// In he, this message translates to:
  /// **'פריט'**
  String get item;

  /// No description provided for @category.
  ///
  /// In he, this message translates to:
  /// **'קבוצה'**
  String get category;

  /// No description provided for @all.
  ///
  /// In he, this message translates to:
  /// **'הכל'**
  String get all;

  /// No description provided for @noTasks.
  ///
  /// In he, this message translates to:
  /// **'אין משימות דחופות כרגע!'**
  String get noTasks;

  /// No description provided for @activeTasks.
  ///
  /// In he, this message translates to:
  /// **'משימות פעילות'**
  String get activeTasks;

  /// No description provided for @overdueTasks.
  ///
  /// In he, this message translates to:
  /// **'באיחור'**
  String get overdueTasks;

  /// No description provided for @doneNow.
  ///
  /// In he, this message translates to:
  /// **'בוצע עכשיו'**
  String get doneNow;

  /// No description provided for @myGroups.
  ///
  /// In he, this message translates to:
  /// **'הקבוצות שלי'**
  String get myGroups;

  /// No description provided for @name.
  ///
  /// In he, this message translates to:
  /// **'שם'**
  String get name;

  /// No description provided for @description.
  ///
  /// In he, this message translates to:
  /// **'תיאור (אופציונלי)'**
  String get description;

  /// No description provided for @repeatEvery.
  ///
  /// In he, this message translates to:
  /// **'כל כמה זמן?'**
  String get repeatEvery;

  /// No description provided for @days.
  ///
  /// In he, this message translates to:
  /// **'ימים'**
  String get days;

  /// No description provided for @weeks.
  ///
  /// In he, this message translates to:
  /// **'שבועות'**
  String get weeks;

  /// No description provided for @months.
  ///
  /// In he, this message translates to:
  /// **'חודשים'**
  String get months;

  /// No description provided for @years.
  ///
  /// In he, this message translates to:
  /// **'שנים'**
  String get years;

  /// No description provided for @requiredField.
  ///
  /// In he, this message translates to:
  /// **'שדה חובה'**
  String get requiredField;

  /// No description provided for @selectCategory.
  ///
  /// In he, this message translates to:
  /// **'שייך לקבוצה'**
  String get selectCategory;

  /// No description provided for @selectItem.
  ///
  /// In he, this message translates to:
  /// **'שייך לפריט'**
  String get selectItem;

  /// No description provided for @addTaskTitleHint.
  ///
  /// In he, this message translates to:
  /// **'הוספת שם למשימה'**
  String get addTaskTitleHint;

  /// No description provided for @addItemTitleHint.
  ///
  /// In he, this message translates to:
  /// **'שם הפריט'**
  String get addItemTitleHint;

  /// No description provided for @addCategoryTitleHint.
  ///
  /// In he, this message translates to:
  /// **'שם הקבוצה'**
  String get addCategoryTitleHint;

  /// No description provided for @color.
  ///
  /// In he, this message translates to:
  /// **'צבע (אופציונלי)'**
  String get color;

  /// No description provided for @icon.
  ///
  /// In he, this message translates to:
  /// **'סמל (אופציונלי)'**
  String get icon;

  /// No description provided for @addQuick.
  ///
  /// In he, this message translates to:
  /// **'+ חדש'**
  String get addQuick;

  /// No description provided for @endConditionTitle.
  ///
  /// In he, this message translates to:
  /// **'משך'**
  String get endConditionTitle;

  /// No description provided for @endConditionAlways.
  ///
  /// In he, this message translates to:
  /// **'תמיד'**
  String get endConditionAlways;

  /// No description provided for @endConditionCount.
  ///
  /// In he, this message translates to:
  /// **'מספר פעמים ספציפי'**
  String get endConditionCount;

  /// No description provided for @endConditionUntil.
  ///
  /// In he, this message translates to:
  /// **'עד תאריך'**
  String get endConditionUntil;

  /// No description provided for @selectDate.
  ///
  /// In he, this message translates to:
  /// **'בחר תאריך'**
  String get selectDate;

  /// No description provided for @times.
  ///
  /// In he, this message translates to:
  /// **'פעמים'**
  String get times;

  /// No description provided for @savedSuccessfully.
  ///
  /// In he, this message translates to:
  /// **'{entityName} נשמר בהצלחה ב{repositoryName}'**
  String savedSuccessfully(String entityName, String repositoryName);

  /// No description provided for @lightMode.
  ///
  /// In he, this message translates to:
  /// **'מצב בהיר'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In he, this message translates to:
  /// **'מצב כהה'**
  String get darkMode;

  /// No description provided for @systemMode.
  ///
  /// In he, this message translates to:
  /// **'הגדרות מערכת'**
  String get systemMode;
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
      <String>['he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
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
