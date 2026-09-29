// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Template';

  @override
  String get navHome => 'Home';

  @override
  String get navPosts => 'Posts';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeTitle => 'Components';

  @override
  String get homeIntro =>
      'A neutral starting point. Replace this screen with your first feature.';

  @override
  String get buttonsSection => 'Buttons';

  @override
  String get primaryAction => 'Primary';

  @override
  String get secondaryAction => 'Secondary';

  @override
  String get textAction => 'Text';

  @override
  String get loadingLabel => 'Loading';

  @override
  String get formSection => 'Form validation';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get submitAction => 'Submit';

  @override
  String get formValid => 'Form is valid';

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationInvalidEmail => 'Enter a valid email address';

  @override
  String validationTooShort(int min) {
    return 'Use at least $min characters';
  }

  @override
  String get dialogSection => 'Dialogs';

  @override
  String get showDialogAction => 'Show dialog';

  @override
  String get dialogTitle => 'Discard changes?';

  @override
  String get dialogMessage => 'This example dialog has no side effects.';

  @override
  String get confirmAction => 'Confirm';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get dialogConfirmed => 'Confirmed';

  @override
  String get dialogCancelled => 'Cancelled';

  @override
  String get statesSection => 'States';

  @override
  String get postsTitle => 'Posts';

  @override
  String get postsEmptyTitle => 'No posts yet';

  @override
  String get postsEmptyMessage => 'New posts will appear here.';

  @override
  String get postsCachedNotice =>
      'Showing saved posts. Pull to refresh when you are back online.';

  @override
  String postTitle(int id) {
    return 'Post $id';
  }

  @override
  String get retryAction => 'Retry';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get errorNetwork =>
      'You appear to be offline. Check your connection and try again.';

  @override
  String get errorTimeout =>
      'The server took too long to respond. Please try again.';

  @override
  String get errorServer =>
      'The server could not handle the request. Please try again later.';

  @override
  String get errorNotFound => 'We could not find what you were looking for.';

  @override
  String get errorUnauthorized =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorParsing =>
      'We received an unexpected response from the server.';

  @override
  String get errorUnknown => 'Something unexpected happened. Please try again.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeSection => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageSection => 'Language';

  @override
  String get languageSystem => 'Device language';

  @override
  String get aboutSection => 'About this build';

  @override
  String get environmentLabel => 'Environment';

  @override
  String get apiLabel => 'API';

  @override
  String get graphQLLabel => 'GraphQL';

  @override
  String get dataSection => 'Data';

  @override
  String get clearDataAction => 'Clear local data';

  @override
  String get clearDataMessage =>
      'Removes the saved session, cached content and preferences from this device.';

  @override
  String get clearDataDone => 'Local data cleared';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundMessage =>
      'The link you followed may be broken or the page may have been removed.';

  @override
  String get goHomeAction => 'Go to home';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';
}
