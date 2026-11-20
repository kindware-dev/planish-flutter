import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'planish_localizations_de.dart';
import 'planish_localizations_en.dart';
import 'planish_localizations_es.dart';
import 'planish_localizations_fr.dart';
import 'planish_localizations_it.dart';
import 'planish_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of PlanishLocalizations
/// returned by `PlanishLocalizations.of(context)`.
///
/// Applications need to include `PlanishLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/planish_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: PlanishLocalizations.localizationsDelegates,
///   supportedLocales: PlanishLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the PlanishLocalizations.supportedLocales
/// property.
abstract class PlanishLocalizations {
  PlanishLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static PlanishLocalizations of(BuildContext context) {
    return Localizations.of<PlanishLocalizations>(
      context,
      PlanishLocalizations,
    )!;
  }

  static const LocalizationsDelegate<PlanishLocalizations> delegate =
      _PlanishLocalizationsDelegate();

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('nl'),
  ];

  /// No description provided for @debugButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Open debug tools'**
  String get debugButtonLabel;

  /// No description provided for @debugTools.
  ///
  /// In en, this message translates to:
  /// **'Debug tools'**
  String get debugTools;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @hideDebugButton.
  ///
  /// In en, this message translates to:
  /// **'Hide debug button'**
  String get hideDebugButton;

  /// No description provided for @console.
  ///
  /// In en, this message translates to:
  /// **'Console'**
  String get console;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @deviceInfo.
  ///
  /// In en, this message translates to:
  /// **'Device & app'**
  String get deviceInfo;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Shared preferences'**
  String get preferences;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copied;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @filterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterHint;

  /// No description provided for @noLogs.
  ///
  /// In en, this message translates to:
  /// **'No logs yet.'**
  String get noLogs;

  /// No description provided for @noNetworkCalls.
  ///
  /// In en, this message translates to:
  /// **'No network calls recorded. Make requests through LoggingHttpClient to see them here.'**
  String get noNetworkCalls;

  /// No description provided for @noPreferences.
  ///
  /// In en, this message translates to:
  /// **'No preferences stored.'**
  String get noPreferences;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @response.
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get response;

  /// No description provided for @headers.
  ///
  /// In en, this message translates to:
  /// **'Headers'**
  String get headers;

  /// No description provided for @body.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get body;

  /// No description provided for @sendFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedbackTitle;

  /// No description provided for @reportProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblemTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @errorBanner.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Telling us what you were doing helps us fix it.'**
  String get errorBanner;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryBug.
  ///
  /// In en, this message translates to:
  /// **'Bug'**
  String get categoryBug;

  /// No description provided for @categoryIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get categoryIdea;

  /// No description provided for @categoryQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get categoryQuestion;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'What happened? What did you expect instead?'**
  String get messageHint;

  /// No description provided for @messageHintIdea.
  ///
  /// In en, this message translates to:
  /// **'What would you like to see, and what would it help you do?'**
  String get messageHintIdea;

  /// No description provided for @messageHintQuestion.
  ///
  /// In en, this message translates to:
  /// **'What are you trying to do?'**
  String get messageHintQuestion;

  /// No description provided for @messageHintOther.
  ///
  /// In en, this message translates to:
  /// **'Tell us anything.'**
  String get messageHintOther;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @emptyMessage.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get emptyMessage;

  /// No description provided for @includeLogs.
  ///
  /// In en, this message translates to:
  /// **'Include recent logs'**
  String get includeLogs;

  /// No description provided for @reviewData.
  ///
  /// In en, this message translates to:
  /// **'What will be sent?'**
  String get reviewData;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @sendCancelled.
  ///
  /// In en, this message translates to:
  /// **'Nothing was sent. Your message is still here.'**
  String get sendCancelled;

  /// No description provided for @sendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send: {reason}'**
  String sendFailed(String reason);

  /// No description provided for @screenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get screenshot;

  /// No description provided for @annotate.
  ///
  /// In en, this message translates to:
  /// **'Annotate'**
  String get annotate;

  /// No description provided for @removeScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeScreenshot;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @pen.
  ///
  /// In en, this message translates to:
  /// **'Pen'**
  String get pen;

  /// No description provided for @rectangle.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get rectangle;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'What will be sent'**
  String get reviewTitle;

  /// No description provided for @nothingCollected.
  ///
  /// In en, this message translates to:
  /// **'Nothing.'**
  String get nothingCollected;

  /// No description provided for @logsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Logs} =1{Logs (1 entry)} other{Logs ({count} entries)}}'**
  String logsCount(int count);

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @sentThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks, your feedback was sent.'**
  String get sentThanks;

  /// No description provided for @handedOff.
  ///
  /// In en, this message translates to:
  /// **'Handed to your mail app. Press send there to deliver it.'**
  String get handedOff;

  /// No description provided for @openFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Open full screen'**
  String get openFullScreen;

  /// No description provided for @tutorial.
  ///
  /// In en, this message translates to:
  /// **'How to report a problem'**
  String get tutorial;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @tutorialShakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Shake your phone'**
  String get tutorialShakeTitle;

  /// No description provided for @tutorialShakeBody.
  ///
  /// In en, this message translates to:
  /// **'Whenever something looks wrong, shake the device. A small bug button appears; tap it and choose “Send feedback”.'**
  String get tutorialShakeBody;

  /// No description provided for @tutorialShakeSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Shake the device whenever something looks wrong or you have an idea. A small sheet opens, “Share feedback”; choose what you want to tell us.'**
  String get tutorialShakeSheetBody;

  /// No description provided for @tutorialShakeFormBody.
  ///
  /// In en, this message translates to:
  /// **'Whenever something looks wrong, shake the device. The report form opens with a screenshot of the screen.'**
  String get tutorialShakeFormBody;

  /// No description provided for @tutorialOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Open “Send feedback”'**
  String get tutorialOpenTitle;

  /// No description provided for @tutorialOpenBody.
  ///
  /// In en, this message translates to:
  /// **'Whenever something looks wrong, open “Send feedback” from the menu. The screen is captured as it is.'**
  String get tutorialOpenBody;

  /// No description provided for @tutorialAnnotateTitle.
  ///
  /// In en, this message translates to:
  /// **'Circle the problem'**
  String get tutorialAnnotateTitle;

  /// No description provided for @tutorialAnnotateBody.
  ///
  /// In en, this message translates to:
  /// **'Draw on the screenshot to show where things went wrong. You can also remove the screenshot entirely.'**
  String get tutorialAnnotateBody;

  /// No description provided for @tutorialDescribeTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened'**
  String get tutorialDescribeTitle;

  /// No description provided for @tutorialDescribeBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a category and describe what you did and what you expected. “What will be sent?” shows exactly what the report contains.'**
  String get tutorialDescribeBody;

  /// No description provided for @tutorialSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Send it'**
  String get tutorialSendTitle;

  /// No description provided for @tutorialSendBody.
  ///
  /// In en, this message translates to:
  /// **'Press Send. If something goes wrong, you see why and can try again; your message is kept.'**
  String get tutorialSendBody;

  /// No description provided for @openFloating.
  ///
  /// In en, this message translates to:
  /// **'Floating window'**
  String get openFloating;

  /// No description provided for @yourEmail.
  ///
  /// In en, this message translates to:
  /// **'Your email (optional)'**
  String get yourEmail;

  /// No description provided for @quickTitle.
  ///
  /// In en, this message translates to:
  /// **'Share feedback'**
  String get quickTitle;

  /// No description provided for @quickSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A screenshot of this screen and recent logs are attached.'**
  String get quickSubtitle;

  /// No description provided for @quickReportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get quickReportProblem;

  /// No description provided for @quickShareIdea.
  ///
  /// In en, this message translates to:
  /// **'Share an idea'**
  String get quickShareIdea;

  /// No description provided for @quickAskQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a question'**
  String get quickAskQuestion;

  /// No description provided for @quickProblemHint.
  ///
  /// In en, this message translates to:
  /// **'Something doesn\'t work as expected'**
  String get quickProblemHint;

  /// No description provided for @quickIdeaHint.
  ///
  /// In en, this message translates to:
  /// **'Something could work even better'**
  String get quickIdeaHint;

  /// No description provided for @quickQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'Something isn\'t clear'**
  String get quickQuestionHint;

  /// No description provided for @drafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get drafts;

  /// No description provided for @unsentDraft.
  ///
  /// In en, this message translates to:
  /// **'Unsent draft'**
  String get unsentDraft;

  /// No description provided for @continueDraft.
  ///
  /// In en, this message translates to:
  /// **'Continue the draft'**
  String get continueDraft;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @draftsNote.
  ///
  /// In en, this message translates to:
  /// **'Reports you started and did not send. Kept 30 days.'**
  String get draftsNote;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @discardDraft.
  ///
  /// In en, this message translates to:
  /// **'Discard draft'**
  String get discardDraft;

  /// No description provided for @automaticDraft.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automaticDraft;

  /// No description provided for @afterAnError.
  ///
  /// In en, this message translates to:
  /// **'after an error'**
  String get afterAnError;

  /// No description provided for @withScreenshot.
  ///
  /// In en, this message translates to:
  /// **'screenshot'**
  String get withScreenshot;

  /// No description provided for @frozenHint.
  ///
  /// In en, this message translates to:
  /// **'From when the form opened'**
  String get frozenHint;

  /// No description provided for @errorCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorCardTitle;

  /// No description provided for @errorCardBody.
  ///
  /// In en, this message translates to:
  /// **'A report is ready with the screenshot and what the app was doing.'**
  String get errorCardBody;

  /// No description provided for @draftsReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 report not sent} other{{count} reports not sent}}'**
  String draftsReminderTitle(int count);

  /// No description provided for @draftsReminderBody.
  ///
  /// In en, this message translates to:
  /// **'They wait on this device until you send them.'**
  String get draftsReminderBody;

  /// No description provided for @openDraft.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get openDraft;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @addDetails.
  ///
  /// In en, this message translates to:
  /// **'Add details'**
  String get addDetails;

  /// No description provided for @quietTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep these quiet?'**
  String get quietTitle;

  /// No description provided for @quietBody.
  ///
  /// In en, this message translates to:
  /// **'Reports after an error will still be prepared. You will find them under Drafts in the feedback form.'**
  String get quietBody;

  /// No description provided for @keepShowing.
  ///
  /// In en, this message translates to:
  /// **'Keep showing'**
  String get keepShowing;

  /// No description provided for @keepQuiet.
  ///
  /// In en, this message translates to:
  /// **'Keep quiet'**
  String get keepQuiet;

  /// No description provided for @errorsCaught.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 error caught} other{{count} errors caught}}'**
  String errorsCaught(int count);

  /// No description provided for @errorsCaughtHint.
  ///
  /// In en, this message translates to:
  /// **'Report one if you saw it happen'**
  String get errorsCaughtHint;

  /// No description provided for @errorOnScreen.
  ///
  /// In en, this message translates to:
  /// **'Error on {screen}'**
  String errorOnScreen(String screen);

  /// No description provided for @errorInApp.
  ///
  /// In en, this message translates to:
  /// **'Error in the app'**
  String get errorInApp;

  /// No description provided for @reportAction.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportAction;

  /// No description provided for @deleteAllDrafts.
  ///
  /// In en, this message translates to:
  /// **'Delete all drafts'**
  String get deleteAllDrafts;

  /// No description provided for @deleteAllDraftsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all drafts? They cannot be recovered.'**
  String get deleteAllDraftsConfirm;

  /// No description provided for @noMessageYet.
  ///
  /// In en, this message translates to:
  /// **'No message yet'**
  String get noMessageYet;
}

class _PlanishLocalizationsDelegate
    extends LocalizationsDelegate<PlanishLocalizations> {
  const _PlanishLocalizationsDelegate();

  @override
  Future<PlanishLocalizations> load(Locale locale) {
    return SynchronousFuture<PlanishLocalizations>(
      lookupPlanishLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'nl',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_PlanishLocalizationsDelegate old) => false;
}

PlanishLocalizations lookupPlanishLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return PlanishLocalizationsDe();
    case 'en':
      return PlanishLocalizationsEn();
    case 'es':
      return PlanishLocalizationsEs();
    case 'fr':
      return PlanishLocalizationsFr();
    case 'it':
      return PlanishLocalizationsIt();
    case 'nl':
      return PlanishLocalizationsNl();
  }

  throw FlutterError(
    'PlanishLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
