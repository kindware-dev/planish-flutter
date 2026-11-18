// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'planish_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class PlanishLocalizationsEn extends PlanishLocalizations {
  PlanishLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get debugButtonLabel => 'Open debug tools';

  @override
  String get debugTools => 'Debug tools';

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get hideDebugButton => 'Hide debug button';

  @override
  String get console => 'Console';

  @override
  String get network => 'Network';

  @override
  String get deviceInfo => 'Device & app';

  @override
  String get preferences => 'Shared preferences';

  @override
  String get close => 'Close';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied to clipboard';

  @override
  String get clear => 'Clear';

  @override
  String get filterHint => 'Filter';

  @override
  String get noLogs => 'No logs yet.';

  @override
  String get noNetworkCalls =>
      'No network calls recorded. Make requests through LoggingHttpClient to see them here.';

  @override
  String get noPreferences => 'No preferences stored.';

  @override
  String get error => 'Error';

  @override
  String get request => 'Request';

  @override
  String get response => 'Response';

  @override
  String get headers => 'Headers';

  @override
  String get body => 'Body';

  @override
  String get sendFeedbackTitle => 'Send feedback';

  @override
  String get reportProblemTitle => 'Report a problem';

  @override
  String get cancel => 'Cancel';

  @override
  String get errorBanner =>
      'Something went wrong. Telling us what you were doing helps us fix it.';

  @override
  String get category => 'Category';

  @override
  String get categoryBug => 'Bug';

  @override
  String get categoryIdea => 'Idea';

  @override
  String get categoryQuestion => 'Question';

  @override
  String get categoryOther => 'Other';

  @override
  String get messageHint => 'What happened? What did you expect instead?';

  @override
  String get messageHintIdea =>
      'What would you like to see, and what would it help you do?';

  @override
  String get messageHintQuestion => 'What are you trying to do?';

  @override
  String get messageHintOther => 'Tell us anything.';

  @override
  String get message => 'Message';

  @override
  String get emptyMessage => '(empty)';

  @override
  String get includeLogs => 'Include recent logs';

  @override
  String get reviewData => 'What will be sent?';

  @override
  String get send => 'Send';

  @override
  String get retry => 'Retry';

  @override
  String get sendCancelled => 'Nothing was sent. Your message is still here.';

  @override
  String sendFailed(String reason) {
    return 'Could not send: $reason';
  }

  @override
  String get screenshot => 'Screenshot';

  @override
  String get annotate => 'Annotate';

  @override
  String get removeScreenshot => 'Remove';

  @override
  String get undo => 'Undo';

  @override
  String get done => 'Done';

  @override
  String get pen => 'Pen';

  @override
  String get rectangle => 'Rectangle';

  @override
  String get color => 'Color';

  @override
  String get reviewTitle => 'What will be sent';

  @override
  String get nothingCollected => 'Nothing.';

  @override
  String logsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Logs ($count entries)',
      one: 'Logs (1 entry)',
      zero: 'Logs',
    );
    return '$_temp0';
  }

  @override
  String get attachments => 'Attachments';

  @override
  String get sentThanks => 'Thanks, your feedback was sent.';

  @override
  String get handedOff =>
      'Handed to your mail app. Press send there to deliver it.';

  @override
  String get openFullScreen => 'Open full screen';

  @override
  String get tutorial => 'How to report a problem';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get tutorialShakeTitle => 'Shake your phone';

  @override
  String get tutorialShakeBody =>
      'Whenever something looks wrong, shake the device. A small bug button appears; tap it and choose “Send feedback”.';

  @override
  String get tutorialShakeSheetBody =>
      'Shake the device whenever something looks wrong or you have an idea. A small sheet opens, “Share feedback”; choose what you want to tell us.';

  @override
  String get tutorialShakeFormBody =>
      'Whenever something looks wrong, shake the device. The report form opens with a screenshot of the screen.';

  @override
  String get tutorialOpenTitle => 'Open “Send feedback”';

  @override
  String get tutorialOpenBody =>
      'Whenever something looks wrong, open “Send feedback” from the menu. The screen is captured as it is.';

  @override
  String get tutorialAnnotateTitle => 'Circle the problem';

  @override
  String get tutorialAnnotateBody =>
      'Draw on the screenshot to show where things went wrong. You can also remove the screenshot entirely.';

  @override
  String get tutorialDescribeTitle => 'Tell us what happened';

  @override
  String get tutorialDescribeBody =>
      'Pick a category and describe what you did and what you expected. “What will be sent?” shows exactly what the report contains.';

  @override
  String get tutorialSendTitle => 'Send it';

  @override
  String get tutorialSendBody =>
      'Press Send. If something goes wrong, you see why and can try again; your message is kept.';

  @override
  String get openFloating => 'Floating window';

  @override
  String get yourEmail => 'Your email (optional)';

  @override
  String get quickTitle => 'Share feedback';

  @override
  String get quickSubtitle =>
      'A problem, an idea, a question: tell us. A screenshot of this screen and recent logs are attached.';

  @override
  String get quickReportProblem => 'Report a problem';

  @override
  String get quickShareIdea => 'Share an idea';

  @override
  String get quickAskQuestion => 'Ask a question';

  @override
  String get drafts => 'Drafts';

  @override
  String get unsentDraft => 'Unsent draft';

  @override
  String get continueDraft => 'Continue the draft';

  @override
  String get notNow => 'Not now';

  @override
  String get draftsNote => 'Kept on this device for 30 days.';

  @override
  String get continueAction => 'Continue';

  @override
  String get deleteAction => 'Delete';

  @override
  String get discardDraft => 'Discard draft';

  @override
  String get automaticDraft => 'Automatic';

  @override
  String get afterAnError => 'after an error';

  @override
  String get withScreenshot => 'screenshot';

  @override
  String get frozenHint => 'From when the form opened';

  @override
  String get errorCardTitle => 'Something went wrong';

  @override
  String get errorCardBody =>
      'A report is ready with the screenshot and what the app was doing.';

  @override
  String draftsReminderTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports not sent',
      one: '1 report not sent',
    );
    return '$_temp0';
  }

  @override
  String get draftsReminderBody =>
      'They wait on this device until you send them.';

  @override
  String get openDraft => 'View';

  @override
  String get later => 'Later';

  @override
  String get addDetails => 'Add details';

  @override
  String get quietTitle => 'Keep these quiet?';

  @override
  String get quietBody =>
      'Reports after an error will still be prepared. You will find them under Drafts in the feedback form.';

  @override
  String get keepShowing => 'Keep showing';

  @override
  String get keepQuiet => 'Keep quiet';
}
