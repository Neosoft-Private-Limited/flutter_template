import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('es'),
  ];

  /// Application name shown in the task switcher and app bar.
  ///
  /// In en, this message translates to:
  /// **'Flutter Template'**
  String get appTitle;

  /// Bottom navigation label for the home tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation label for the posts tab.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get navPosts;

  /// Bottom navigation label for the settings tab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Title of the design system showcase screen.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get homeTitle;

  /// Introductory text on the showcase screen.
  ///
  /// In en, this message translates to:
  /// **'A neutral starting point. Replace this screen with your first feature.'**
  String get homeIntro;

  /// Section heading for button examples.
  ///
  /// In en, this message translates to:
  /// **'Buttons'**
  String get buttonsSection;

  /// Label of the primary button example.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primaryAction;

  /// Label of the secondary button example.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get secondaryAction;

  /// Label of the text button example.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textAction;

  /// Accessibility label announced while content or an action is loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loadingLabel;

  /// Section heading for the form example.
  ///
  /// In en, this message translates to:
  /// **'Form validation'**
  String get formSection;

  /// Label of the email field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Hint text of the email field.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailHint;

  /// Label of the password field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Label of the form submit button.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitAction;

  /// Confirmation shown after a valid form submission.
  ///
  /// In en, this message translates to:
  /// **'Form is valid'**
  String get formValid;

  /// Validation error for an empty required field.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get validationRequired;

  /// Validation error for a malformed email.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validationInvalidEmail;

  /// Validation error for a value that is too short.
  ///
  /// In en, this message translates to:
  /// **'Use at least {min} characters'**
  String validationTooShort(int min);

  /// Section heading for the dialog example.
  ///
  /// In en, this message translates to:
  /// **'Dialogs'**
  String get dialogSection;

  /// Button that opens the example dialog.
  ///
  /// In en, this message translates to:
  /// **'Show dialog'**
  String get showDialogAction;

  /// Title of the example confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get dialogTitle;

  /// Body of the example confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'This example dialog has no side effects.'**
  String get dialogMessage;

  /// Confirm button label in dialogs.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmAction;

  /// Cancel button label in dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// Message shown after confirming the example dialog.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get dialogConfirmed;

  /// Message shown after cancelling the example dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get dialogCancelled;

  /// Section heading for empty/error state examples.
  ///
  /// In en, this message translates to:
  /// **'States'**
  String get statesSection;

  /// Title of the posts screen.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get postsTitle;

  /// Title shown when the posts list is empty.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get postsEmptyTitle;

  /// Message shown when the posts list is empty.
  ///
  /// In en, this message translates to:
  /// **'New posts will appear here.'**
  String get postsEmptyMessage;

  /// Banner shown when posts come from the offline cache.
  ///
  /// In en, this message translates to:
  /// **'Showing saved posts. Pull to refresh when you are back online.'**
  String get postsCachedNotice;

  /// Title of the post detail screen.
  ///
  /// In en, this message translates to:
  /// **'Post {id}'**
  String postTitle(int id);

  /// Button that retries a failed operation.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// Generic error title.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// Error shown when the device cannot reach the server.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Check your connection and try again.'**
  String get errorNetwork;

  /// Error shown when a request times out.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to respond. Please try again.'**
  String get errorTimeout;

  /// Error shown for unexpected server responses.
  ///
  /// In en, this message translates to:
  /// **'The server could not handle the request. Please try again later.'**
  String get errorServer;

  /// Error shown when a resource does not exist.
  ///
  /// In en, this message translates to:
  /// **'We could not find what you were looking for.'**
  String get errorNotFound;

  /// Error shown when the server rejects the credentials.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorUnauthorized;

  /// Error shown when a payload cannot be parsed.
  ///
  /// In en, this message translates to:
  /// **'We received an unexpected response from the server.'**
  String get errorParsing;

  /// Fallback error message.
  ///
  /// In en, this message translates to:
  /// **'Something unexpected happened. Please try again.'**
  String get errorUnknown;

  /// Title of the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Section heading for the theme selector.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSection;

  /// Theme option that follows the device setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Light theme option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Section heading for the language selector.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// Language option that follows the device locale.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageSystem;

  /// Section heading for build information.
  ///
  /// In en, this message translates to:
  /// **'About this build'**
  String get aboutSection;

  /// Label for the build environment (dev, staging, prod).
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environmentLabel;

  /// Label for the API base URL.
  ///
  /// In en, this message translates to:
  /// **'API'**
  String get apiLabel;

  /// Section heading for local data actions.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataSection;

  /// Button that removes local data.
  ///
  /// In en, this message translates to:
  /// **'Clear local data'**
  String get clearDataAction;

  /// Explanation shown before clearing local data.
  ///
  /// In en, this message translates to:
  /// **'Removes the saved session, cached content and preferences from this device.'**
  String get clearDataMessage;

  /// Confirmation after clearing local data.
  ///
  /// In en, this message translates to:
  /// **'Local data cleared'**
  String get clearDataDone;

  /// Title of the page shown for unknown links.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// Message shown for unknown links.
  ///
  /// In en, this message translates to:
  /// **'The link you followed may be broken or the page may have been removed.'**
  String get notFoundMessage;

  /// Button that navigates to the home screen.
  ///
  /// In en, this message translates to:
  /// **'Go to home'**
  String get goHomeAction;

  /// Name of the language in its own language (not translated).
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Name of the language in its own language (not translated).
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
