// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'planish_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class PlanishLocalizationsDe extends PlanishLocalizations {
  PlanishLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get debugButtonLabel => 'Debug-Werkzeuge öffnen';

  @override
  String get debugTools => 'Debug-Werkzeuge';

  @override
  String get sendFeedback => 'Feedback senden';

  @override
  String get hideDebugButton => 'Debug-Button ausblenden';

  @override
  String get console => 'Konsole';

  @override
  String get network => 'Netzwerk';

  @override
  String get deviceInfo => 'Gerät & App';

  @override
  String get preferences => 'Shared Preferences';

  @override
  String get close => 'Schließen';

  @override
  String get copy => 'Kopieren';

  @override
  String get copied => 'In die Zwischenablage kopiert';

  @override
  String get clear => 'Leeren';

  @override
  String get filterHint => 'Filtern';

  @override
  String get noLogs => 'Noch keine Logs.';

  @override
  String get noNetworkCalls =>
      'Keine Netzwerkaufrufe aufgezeichnet. Senden Sie Anfragen über LoggingHttpClient, um sie hier zu sehen.';

  @override
  String get noPreferences => 'Keine Einstellungen gespeichert.';

  @override
  String get error => 'Fehler';

  @override
  String get request => 'Anfrage';

  @override
  String get response => 'Antwort';

  @override
  String get headers => 'Header';

  @override
  String get body => 'Inhalt';

  @override
  String get sendFeedbackTitle => 'Feedback senden';

  @override
  String get reportProblemTitle => 'Problem melden';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get errorBanner =>
      'Etwas ist schiefgelaufen. Beschreiben Sie, was Sie gerade getan haben, damit wir es beheben können.';

  @override
  String get category => 'Kategorie';

  @override
  String get categoryBug => 'Fehler';

  @override
  String get categoryIdea => 'Idee';

  @override
  String get categoryQuestion => 'Frage';

  @override
  String get categoryOther => 'Sonstiges';

  @override
  String get messageHint => 'Was ist passiert? Was haben Sie erwartet?';

  @override
  String get messageHintIdea =>
      'Was wünschen Sie sich, und wobei würde es Ihnen helfen?';

  @override
  String get messageHintQuestion => 'Was möchten Sie tun?';

  @override
  String get messageHintOther => 'Erzählen Sie uns alles.';

  @override
  String get message => 'Nachricht';

  @override
  String get emptyMessage => '(leer)';

  @override
  String get includeLogs => 'Aktuelle Logs anhängen';

  @override
  String get reviewData => 'Was wird gesendet?';

  @override
  String get send => 'Senden';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get sendCancelled =>
      'Es wurde nichts gesendet. Ihre Nachricht ist noch da.';

  @override
  String sendFailed(String reason) {
    return 'Senden fehlgeschlagen: $reason';
  }

  @override
  String get screenshot => 'Screenshot';

  @override
  String get annotate => 'Markieren';

  @override
  String get removeScreenshot => 'Entfernen';

  @override
  String get undo => 'Rückgängig';

  @override
  String get done => 'Fertig';

  @override
  String get pen => 'Stift';

  @override
  String get rectangle => 'Rechteck';

  @override
  String get color => 'Farbe';

  @override
  String get reviewTitle => 'Was gesendet wird';

  @override
  String get nothingCollected => 'Nichts.';

  @override
  String logsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Logs ($count Einträge)',
      one: 'Logs (1 Eintrag)',
      zero: 'Logs',
    );
    return '$_temp0';
  }

  @override
  String get attachments => 'Anhänge';

  @override
  String get sentThanks => 'Danke, Ihr Feedback wurde gesendet.';

  @override
  String get handedOff =>
      'An Ihre Mail-App übergeben. Tippen Sie dort auf Senden.';

  @override
  String get openFullScreen => 'Vollbild öffnen';

  @override
  String get tutorial => 'So melden Sie ein Problem';

  @override
  String get skip => 'Überspringen';

  @override
  String get next => 'Weiter';

  @override
  String get tutorialShakeTitle => 'Schütteln Sie Ihr Telefon';

  @override
  String get tutorialShakeBody =>
      'Wenn etwas nicht stimmt, schütteln Sie das Gerät. Ein kleiner Button erscheint; tippen Sie darauf und wählen Sie „Feedback senden“.';

  @override
  String get tutorialShakeSheetBody =>
      'Schütteln Sie das Gerät, wenn etwas nicht stimmt oder Ihnen eine Idee kommt. Ein kleines Fenster öffnet sich, „Feedback geben“; wählen Sie, was Sie uns sagen möchten.';

  @override
  String get tutorialShakeFormBody =>
      'Wenn etwas nicht stimmt, schütteln Sie das Gerät. Das Formular öffnet sich mit einem Screenshot des Bildschirms.';

  @override
  String get tutorialOpenTitle => '„Feedback senden“ öffnen';

  @override
  String get tutorialOpenBody =>
      'Wenn etwas nicht stimmt, öffnen Sie „Feedback senden“ im Menü. Der Bildschirm wird so erfasst, wie er ist.';

  @override
  String get tutorialAnnotateTitle => 'Markieren Sie das Problem';

  @override
  String get tutorialAnnotateBody =>
      'Zeichnen Sie auf dem Screenshot, wo es hakt. Sie können den Screenshot auch ganz entfernen.';

  @override
  String get tutorialDescribeTitle => 'Beschreiben Sie, was passiert ist';

  @override
  String get tutorialDescribeBody =>
      'Wählen Sie eine Kategorie und beschreiben Sie, was Sie getan und was Sie erwartet haben. „Was wird gesendet?“ zeigt den genauen Inhalt.';

  @override
  String get tutorialSendTitle => 'Abschicken';

  @override
  String get tutorialSendBody =>
      'Tippen Sie auf Senden. Falls etwas schiefgeht, sehen Sie den Grund und können es erneut versuchen; Ihre Nachricht bleibt erhalten.';

  @override
  String get openFloating => 'Schwebendes Fenster';

  @override
  String get yourEmail => 'Ihre E-Mail (optional)';

  @override
  String get quickTitle => 'Feedback geben';

  @override
  String get quickSubtitle =>
      'Ein Screenshot dieses Bildschirms und die letzten Logs werden angehängt.';

  @override
  String get quickReportProblem => 'Problem melden';

  @override
  String get quickShareIdea => 'Idee teilen';

  @override
  String get quickAskQuestion => 'Frage stellen';

  @override
  String get quickProblemHint => 'Etwas funktioniert nicht wie erwartet';

  @override
  String get quickIdeaHint => 'Etwas könnte noch besser funktionieren';

  @override
  String get quickQuestionHint => 'Etwas ist unklar';

  @override
  String get drafts => 'Entwürfe';

  @override
  String get unsentDraft => 'Nicht gesendeter Entwurf';

  @override
  String get continueDraft => 'Entwurf fortsetzen';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get draftsNote =>
      'Begonnene, nicht gesendete Meldungen. 30 Tage gespeichert.';

  @override
  String get continueAction => 'Fortsetzen';

  @override
  String get deleteAction => 'Löschen';

  @override
  String get discardDraft => 'Entwurf verwerfen';

  @override
  String get automaticDraft => 'Automatisch';

  @override
  String get afterAnError => 'nach einem Fehler';

  @override
  String get withScreenshot => 'Screenshot';

  @override
  String get frozenHint => 'Vom Öffnen des Formulars';

  @override
  String get errorCardTitle => 'Etwas ist schiefgelaufen';

  @override
  String get errorCardBody =>
      'Ein Bericht mit Screenshot und dem, was die App gerade tat, ist bereit.';

  @override
  String draftsReminderTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Berichte nicht gesendet',
      one: '1 Bericht nicht gesendet',
    );
    return '$_temp0';
  }

  @override
  String get draftsReminderBody =>
      'Sie warten auf diesem Gerät, bis Sie sie senden.';

  @override
  String get openDraft => 'Ansehen';

  @override
  String get later => 'Später';

  @override
  String get addDetails => 'Details hinzufügen';

  @override
  String get quietTitle => 'Künftig still bleiben?';

  @override
  String get quietBody =>
      'Nach einem Fehler wird weiterhin ein Bericht vorbereitet. Sie finden ihn unter Entwürfe im Feedback-Formular.';

  @override
  String get keepShowing => 'Weiter anzeigen';

  @override
  String get keepQuiet => 'Still bleiben';

  @override
  String errorsCaught(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fehler erkannt',
      one: '1 Fehler erkannt',
    );
    return '$_temp0';
  }

  @override
  String get errorsCaughtHint => 'Melden Sie einen, wenn Sie ihn bemerkt haben';

  @override
  String errorOnScreen(String screen) {
    return 'Fehler auf $screen';
  }

  @override
  String get errorInApp => 'Fehler in der App';

  @override
  String get reportAction => 'Melden';

  @override
  String get deleteAllDrafts => 'Alle Entwürfe löschen';

  @override
  String get deleteAllDraftsConfirm =>
      'Alle Entwürfe löschen? Sie können nicht wiederhergestellt werden.';

  @override
  String get noMessageYet => 'Noch keine Nachricht';
}
