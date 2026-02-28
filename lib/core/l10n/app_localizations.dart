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
  /// **'VoiceSewa'**
  String get appName;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to VoiceSewa!'**
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

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @voiceBotTitle.
  ///
  /// In en, this message translates to:
  /// **'VoiceBot'**
  String get voiceBotTitle;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @bookCTA.
  ///
  /// In en, this message translates to:
  /// **'Book a Service'**
  String get bookCTA;

  /// No description provided for @activeBookingsCTA.
  ///
  /// In en, this message translates to:
  /// **'Active Bookings'**
  String get activeBookingsCTA;

  /// No description provided for @offersCTA.
  ///
  /// In en, this message translates to:
  /// **'Check Offers'**
  String get offersCTA;

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

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @trackRecentRequests.
  ///
  /// In en, this message translates to:
  /// **'Track Recent Requests'**
  String get trackRecentRequests;

  /// No description provided for @worker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get worker;

  /// No description provided for @eTA.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get eTA;

  /// No description provided for @quickBookServices.
  ///
  /// In en, this message translates to:
  /// **'Quick Book Services'**
  String get quickBookServices;

  /// No description provided for @bookAgain.
  ///
  /// In en, this message translates to:
  /// **'Book Again'**
  String get bookAgain;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @offers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offers;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @yrsExperience.
  ///
  /// In en, this message translates to:
  /// **'yrs experience'**
  String get yrsExperience;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @playVoiceIntro.
  ///
  /// In en, this message translates to:
  /// **'Play voice intro'**
  String get playVoiceIntro;

  /// No description provided for @oldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get oldestFirst;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get newestFirst;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @noJobsMatchTheSelectedFilters.
  ///
  /// In en, this message translates to:
  /// **'No jobs match the selected filters.'**
  String get noJobsMatchTheSelectedFilters;

  /// No description provided for @activeJobs.
  ///
  /// In en, this message translates to:
  /// **'Active Jobs'**
  String get activeJobs;

  /// No description provided for @completedJobs.
  ///
  /// In en, this message translates to:
  /// **'Completed Jobs'**
  String get completedJobs;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your Rating'**
  String get yourRating;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @five.
  ///
  /// In en, this message translates to:
  /// **'5'**
  String get five;

  /// No description provided for @userPreferences.
  ///
  /// In en, this message translates to:
  /// **'User Preferences'**
  String get userPreferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectYourPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get selectYourPreferredLanguage;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @manageSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Manage Saved Addresses'**
  String get manageSavedAddresses;

  /// No description provided for @dataUsageAndOfflineCache.
  ///
  /// In en, this message translates to:
  /// **'Data Usage & Offline Cache'**
  String get dataUsageAndOfflineCache;

  /// No description provided for @configureDownloadAndCacheLimits.
  ///
  /// In en, this message translates to:
  /// **'Configure download and cache limits'**
  String get configureDownloadAndCacheLimits;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @supportAndHelp.
  ///
  /// In en, this message translates to:
  /// **'Support & Help'**
  String get supportAndHelp;

  /// No description provided for @speakWhatIsTheProblem.
  ///
  /// In en, this message translates to:
  /// **'Tell me, what is the problem?'**
  String get speakWhatIsTheProblem;

  /// No description provided for @quickAssistance.
  ///
  /// In en, this message translates to:
  /// **'Quick Assistance'**
  String get quickAssistance;

  /// No description provided for @paymentIssue.
  ///
  /// In en, this message translates to:
  /// **'Payment issue'**
  String get paymentIssue;

  /// No description provided for @workerNotArrived.
  ///
  /// In en, this message translates to:
  /// **'Worker not arrived'**
  String get workerNotArrived;

  /// No description provided for @fAQs.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get fAQs;

  /// No description provided for @chatWithSupport.
  ///
  /// In en, this message translates to:
  /// **'Chat with Support'**
  String get chatWithSupport;

  /// No description provided for @chatFunctionalityComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Chat functionality coming soon!'**
  String get chatFunctionalityComingSoon;

  /// No description provided for @oK.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get oK;

  /// No description provided for @cancelJob.
  ///
  /// In en, this message translates to:
  /// **'Cancel Job'**
  String get cancelJob;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get listening;

  /// No description provided for @voiceRecognition.
  ///
  /// In en, this message translates to:
  /// **'Voice Recognition'**
  String get voiceRecognition;

  /// No description provided for @speakNow.
  ///
  /// In en, this message translates to:
  /// **'Speak now'**
  String get speakNow;

  /// No description provided for @startSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Start speaking'**
  String get startSpeaking;

  /// No description provided for @noTextRecognized.
  ///
  /// In en, this message translates to:
  /// **'No text recognized'**
  String get noTextRecognized;

  /// No description provided for @loadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get loadingProfile;

  /// No description provided for @locationCapturedAddressAutofilled.
  ///
  /// In en, this message translates to:
  /// **'Location captured & address auto-filled ✓'**
  String get locationCapturedAddressAutofilled;

  /// No description provided for @houseFlatNoStreetName.
  ///
  /// In en, this message translates to:
  /// **'House/Flat No., Street Name'**
  String get houseFlatNoStreetName;

  /// No description provided for @addressLine2.
  ///
  /// In en, this message translates to:
  /// **'Address Line 2'**
  String get addressLine2;

  /// No description provided for @apartmentSuiteBuildingOptional.
  ///
  /// In en, this message translates to:
  /// **'Apartment, Suite, Building (Optional)'**
  String get apartmentSuiteBuildingOptional;

  /// No description provided for @landmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get landmark;

  /// No description provided for @nearbyLandmarkOptional.
  ///
  /// In en, this message translates to:
  /// **'Nearby landmark (Optional)'**
  String get nearbyLandmarkOptional;

  /// No description provided for @cityName.
  ///
  /// In en, this message translates to:
  /// **'City name'**
  String get cityName;

  /// No description provided for @sixDigits.
  ///
  /// In en, this message translates to:
  /// **'6 digits'**
  String get sixDigits;

  /// No description provided for @noJobsMatchTheSelectedFilters2.
  ///
  /// In en, this message translates to:
  /// **'No jobs match the selected filters'**
  String get noJobsMatchTheSelectedFilters2;

  /// No description provided for @noRecentRequests.
  ///
  /// In en, this message translates to:
  /// **'No recent requests'**
  String get noRecentRequests;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @jobDetails.
  ///
  /// In en, this message translates to:
  /// **'Job Details'**
  String get jobDetails;

  /// No description provided for @jobNotFound.
  ///
  /// In en, this message translates to:
  /// **'Job not found'**
  String get jobNotFound;

  /// No description provided for @thankYouForYourFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get thankYouForYourFeedback;

  /// No description provided for @areYouSureYouWantToCancelThisJob.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this job?'**
  String get areYouSureYouWantToCancelThisJob;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @jobCancelled.
  ///
  /// In en, this message translates to:
  /// **'Job cancelled'**
  String get jobCancelled;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @rescheduleJob.
  ///
  /// In en, this message translates to:
  /// **'Reschedule Job'**
  String get rescheduleJob;

  /// No description provided for @selectNewDate.
  ///
  /// In en, this message translates to:
  /// **'Select new date:'**
  String get selectNewDate;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @jobRescheduled.
  ///
  /// In en, this message translates to:
  /// **'Job rescheduled'**
  String get jobRescheduled;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @addressSavedForFutureUse.
  ///
  /// In en, this message translates to:
  /// **'Address saved for future use'**
  String get addressSavedForFutureUse;

  /// No description provided for @pleaseSelectAService.
  ///
  /// In en, this message translates to:
  /// **'Please select a service'**
  String get pleaseSelectAService;

  /// No description provided for @pleaseSelectWhenYouWantTheJobDone.
  ///
  /// In en, this message translates to:
  /// **'Please select when you want the job done'**
  String get pleaseSelectWhenYouWantTheJobDone;

  /// No description provided for @pleaseFillRequiredAddressFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill required address fields'**
  String get pleaseFillRequiredAddressFields;

  /// No description provided for @pleaseCaptureLocationForTheAddress.
  ///
  /// In en, this message translates to:
  /// **'Please capture location for the address'**
  String get pleaseCaptureLocationForTheAddress;

  /// No description provided for @pleaseSelectAnAddress.
  ///
  /// In en, this message translates to:
  /// **'Please select an address'**
  String get pleaseSelectAnAddress;

  /// No description provided for @createJobRequest.
  ///
  /// In en, this message translates to:
  /// **'Create Job Request'**
  String get createJobRequest;

  /// No description provided for @describeWhatYouNeedDone.
  ///
  /// In en, this message translates to:
  /// **'Describe what you need done...'**
  String get describeWhatYouNeedDone;

  /// No description provided for @selectAddress.
  ///
  /// In en, this message translates to:
  /// **'Select Address'**
  String get selectAddress;

  /// No description provided for @oTPCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'OTP copied to clipboard'**
  String get oTPCopiedToClipboard;

  /// No description provided for @copyOTP.
  ///
  /// In en, this message translates to:
  /// **'Copy OTP'**
  String get copyOTP;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @addFeedback.
  ///
  /// In en, this message translates to:
  /// **'Add Feedback'**
  String get addFeedback;

  /// No description provided for @pleaseSelectAStarRating.
  ///
  /// In en, this message translates to:
  /// **'Please select a star rating'**
  String get pleaseSelectAStarRating;

  /// No description provided for @writeACommentOptional.
  ///
  /// In en, this message translates to:
  /// **'Write a comment (optional)'**
  String get writeACommentOptional;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @voiceAssistant.
  ///
  /// In en, this message translates to:
  /// **'Voice Assistant'**
  String get voiceAssistant;

  /// No description provided for @assistantIsResponding.
  ///
  /// In en, this message translates to:
  /// **'Assistant is responding...'**
  String get assistantIsResponding;

  /// No description provided for @tapTheMicToStartTalking.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic to start talking'**
  String get tapTheMicToStartTalking;

  /// No description provided for @quotations.
  ///
  /// In en, this message translates to:
  /// **'Quotations'**
  String get quotations;

  /// No description provided for @acceptQuotation.
  ///
  /// In en, this message translates to:
  /// **'Accept Quotation'**
  String get acceptQuotation;

  /// No description provided for @quotationAcceptedOTPGenerated.
  ///
  /// In en, this message translates to:
  /// **'Quotation accepted! OTP generated.'**
  String get quotationAcceptedOTPGenerated;

  /// No description provided for @confirmAccept.
  ///
  /// In en, this message translates to:
  /// **'Confirm Accept'**
  String get confirmAccept;

  /// No description provided for @rejectQuotation.
  ///
  /// In en, this message translates to:
  /// **'Reject Quotation'**
  String get rejectQuotation;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonOptional;

  /// No description provided for @whyAreYouRejectingThis.
  ///
  /// In en, this message translates to:
  /// **'Why are you rejecting this?'**
  String get whyAreYouRejectingThis;

  /// No description provided for @quotationRejected.
  ///
  /// In en, this message translates to:
  /// **'Quotation rejected'**
  String get quotationRejected;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @callWorker.
  ///
  /// In en, this message translates to:
  /// **'Call worker'**
  String get callWorker;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get typeAMessage;

  /// No description provided for @estCost.
  ///
  /// In en, this message translates to:
  /// **'Est. Cost'**
  String get estCost;

  /// No description provided for @estTime.
  ///
  /// In en, this message translates to:
  /// **'Est. Time'**
  String get estTime;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason'**
  String get rejectionReason;

  /// No description provided for @withdrawalReason.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal Reason'**
  String get withdrawalReason;

  /// No description provided for @viewed.
  ///
  /// In en, this message translates to:
  /// **'Viewed'**
  String get viewed;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @withdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get withdrawn;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @contactWorker.
  ///
  /// In en, this message translates to:
  /// **'Contact Worker'**
  String get contactWorker;

  /// No description provided for @allServices.
  ///
  /// In en, this message translates to:
  /// **'All Services'**
  String get allServices;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @twoKm.
  ///
  /// In en, this message translates to:
  /// **'2 km'**
  String get twoKm;

  /// No description provided for @fiveKm.
  ///
  /// In en, this message translates to:
  /// **'5 km'**
  String get fiveKm;

  /// No description provided for @nameAndPhoneAreRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and phone are required'**
  String get nameAndPhoneAreRequired;

  /// No description provided for @profileCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile created successfully!'**
  String get profileCreatedSuccessfully;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfile;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name *'**
  String get fullName;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number *'**
  String get phoneNumber;

  /// No description provided for @tendigitMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'10-digit mobile number'**
  String get tendigitMobileNumber;

  /// No description provided for @serviceAddress.
  ///
  /// In en, this message translates to:
  /// **'Service Address'**
  String get serviceAddress;

  /// No description provided for @skipAddressAddLater.
  ///
  /// In en, this message translates to:
  /// **'Skip address (add later)'**
  String get skipAddressAddLater;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get loginSuccessful;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @accountCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get accountCreatedSuccessfully;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

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

  /// No description provided for @comingSoon2.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon ......'**
  String get comingSoon2;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @str_876667.
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get str_876667;

  /// No description provided for @str_147662.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get str_147662;

  /// No description provided for @str_112163.
  ///
  /// In en, this message translates to:
  /// **'ગુજરાતી'**
  String get str_112163;

  /// No description provided for @workerNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Worker not assigned'**
  String get workerNotAssigned;

  /// No description provided for @rescheduled.
  ///
  /// In en, this message translates to:
  /// **'Rescheduled'**
  String get rescheduled;

  /// No description provided for @quoted.
  ///
  /// In en, this message translates to:
  /// **'Quoted'**
  String get quoted;

  /// No description provided for @requested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get requested;
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
