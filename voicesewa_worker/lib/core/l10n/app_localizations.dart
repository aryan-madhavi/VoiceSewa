import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

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
    Locale('gu'),
    Locale('hi'),
    Locale('mr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'VoiceSewa Partner'**
  String get appName;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to VoiceSewa Partner!'**
  String get welcomeMessage;

  /// No description provided for @loginPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please log in to continue.'**
  String get loginPrompt;

  /// No description provided for @signUpPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up now.'**
  String get signUpPrompt;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'An error has occurred. Please try again.'**
  String get errorMessage;

  /// No description provided for @loadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading, please wait...'**
  String get loadingMessage;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmation;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Login / Sign Up'**
  String get authTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @jobsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Jobs'**
  String get jobsTitle;

  /// No description provided for @earningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earningsTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @helpCTA.
  ///
  /// In en, this message translates to:
  /// **'Get Help'**
  String get helpCTA;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @feedbackPrompt.
  ///
  /// In en, this message translates to:
  /// **'We value your feedback!'**
  String get feedbackPrompt;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new update is available.'**
  String get updateAvailable;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get noInternetConnection;

  /// No description provided for @findWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Work'**
  String get findWorkTitle;

  /// No description provided for @onlineAndVisible.
  ///
  /// In en, this message translates to:
  /// **'Online & Visible'**
  String get onlineAndVisible;

  /// No description provided for @youAreOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get youAreOffline;

  /// No description provided for @youAreNowReceivingJobNotifications.
  ///
  /// In en, this message translates to:
  /// **'You are now receiving job notifications!'**
  String get youAreNowReceivingJobNotifications;

  /// No description provided for @yearlyEarnings.
  ///
  /// In en, this message translates to:
  /// **'Yearly Earnings'**
  String get yearlyEarnings;

  /// No description provided for @growthOverTheLastFiveYears.
  ///
  /// In en, this message translates to:
  /// **'Growth over the last 5 years'**
  String get growthOverTheLastFiveYears;

  /// No description provided for @applyNow.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get applyNow;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @yourCurrentRating.
  ///
  /// In en, this message translates to:
  /// **'Your Current Rating'**
  String get yourCurrentRating;

  /// No description provided for @excellentJob.
  ///
  /// In en, this message translates to:
  /// **'Excellent Job!'**
  String get excellentJob;

  /// No description provided for @activeJobs.
  ///
  /// In en, this message translates to:
  /// **'Active Jobs'**
  String get activeJobs;

  /// No description provided for @recentHistory.
  ///
  /// In en, this message translates to:
  /// **'Recent History'**
  String get recentHistory;

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View Receipt'**
  String get viewReceipt;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark As Completed'**
  String get markAsCompleted;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @monthlyGoal.
  ///
  /// In en, this message translates to:
  /// **'Monthly Goal'**
  String get monthlyGoal;

  /// No description provided for @youRe.
  ///
  /// In en, this message translates to:
  /// **'You\'re'**
  String get youRe;

  /// No description provided for @thereKeepItUp.
  ///
  /// In en, this message translates to:
  /// **'there! Keep it up!'**
  String get thereKeepItUp;

  /// No description provided for @availableForWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Available for Withdrawal'**
  String get availableForWithdrawal;

  /// No description provided for @withdrawMoney.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Money'**
  String get withdrawMoney;

  /// No description provided for @totalEarned.
  ///
  /// In en, this message translates to:
  /// **'Total Earned'**
  String get totalEarned;

  /// No description provided for @workHistory.
  ///
  /// In en, this message translates to:
  /// **'Work History'**
  String get workHistory;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @callSupport.
  ///
  /// In en, this message translates to:
  /// **'Call Support'**
  String get callSupport;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @helpADRATEVoicesewaDOTCom.
  ///
  /// In en, this message translates to:
  /// **'help@voicesewa.com'**
  String get helpADRATEVoicesewaDOTCom;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @receiveJobAlerts.
  ///
  /// In en, this message translates to:
  /// **'Receive job alerts'**
  String get receiveJobAlerts;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @reduceEyeStrain.
  ///
  /// In en, this message translates to:
  /// **'Reduce eye strain'**
  String get reduceEyeStrain;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @privacyNotificationsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Privacy, notifications, language'**
  String get privacyNotificationsLanguage;

  /// No description provided for @viewPastJobsAndEarnings.
  ///
  /// In en, this message translates to:
  /// **'View past jobs and earnings'**
  String get viewPastJobsAndEarnings;

  /// No description provided for @bankDetails.
  ///
  /// In en, this message translates to:
  /// **'Bank Details'**
  String get bankDetails;

  /// No description provided for @managePayoutsAndAccounts.
  ///
  /// In en, this message translates to:
  /// **'Manage payouts and accounts'**
  String get managePayoutsAndAccounts;

  /// No description provided for @fAQsContactUs.
  ///
  /// In en, this message translates to:
  /// **'FAQs, Contact us'**
  String get fAQsContactUs;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @primaryAccount.
  ///
  /// In en, this message translates to:
  /// **'Primary Account'**
  String get primaryAccount;

  /// No description provided for @addNewBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Add New Bank Account'**
  String get addNewBankAccount;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @speak.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get speak;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;
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
      <String>['en', 'gu', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
