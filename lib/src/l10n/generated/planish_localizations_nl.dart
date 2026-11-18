// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'planish_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class PlanishLocalizationsNl extends PlanishLocalizations {
  PlanishLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get debugButtonLabel => 'Debugtools openen';

  @override
  String get debugTools => 'Debugtools';

  @override
  String get sendFeedback => 'Feedback versturen';

  @override
  String get hideDebugButton => 'Debugknop verbergen';

  @override
  String get console => 'Console';

  @override
  String get network => 'Netwerk';

  @override
  String get deviceInfo => 'Apparaat en app';

  @override
  String get preferences => 'Shared preferences';

  @override
  String get close => 'Sluiten';

  @override
  String get copy => 'Kopiëren';

  @override
  String get copied => 'Gekopieerd naar klembord';

  @override
  String get clear => 'Wissen';

  @override
  String get filterHint => 'Filteren';

  @override
  String get noLogs => 'Nog geen logs.';

  @override
  String get noNetworkCalls =>
      'Geen netwerkaanroepen vastgelegd. Doe verzoeken via LoggingHttpClient om ze hier te zien.';

  @override
  String get noPreferences => 'Geen voorkeuren opgeslagen.';

  @override
  String get error => 'Fout';

  @override
  String get request => 'Verzoek';

  @override
  String get response => 'Antwoord';

  @override
  String get headers => 'Headers';

  @override
  String get body => 'Inhoud';

  @override
  String get sendFeedbackTitle => 'Feedback versturen';

  @override
  String get reportProblemTitle => 'Probleem melden';

  @override
  String get cancel => 'Annuleren';

  @override
  String get errorBanner =>
      'Er ging iets mis. Vertel ons wat je aan het doen was, dan kunnen we het verhelpen.';

  @override
  String get category => 'Categorie';

  @override
  String get categoryBug => 'Bug';

  @override
  String get categoryIdea => 'Idee';

  @override
  String get categoryQuestion => 'Vraag';

  @override
  String get categoryOther => 'Overig';

  @override
  String get messageHint => 'Wat gebeurde er? Wat had je verwacht?';

  @override
  String get messageHintIdea =>
      'Wat zou je graag zien, en waarmee zou het je helpen?';

  @override
  String get messageHintQuestion => 'Wat probeer je te doen?';

  @override
  String get messageHintOther => 'Vertel ons alles.';

  @override
  String get message => 'Bericht';

  @override
  String get emptyMessage => '(leeg)';

  @override
  String get includeLogs => 'Recente logs bijvoegen';

  @override
  String get reviewData => 'Wat wordt er verzonden?';

  @override
  String get send => 'Versturen';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get sendCancelled => 'Er is niets verzonden. Je bericht staat er nog.';

  @override
  String sendFailed(String reason) {
    return 'Versturen mislukt: $reason';
  }

  @override
  String get screenshot => 'Schermafbeelding';

  @override
  String get annotate => 'Markeren';

  @override
  String get removeScreenshot => 'Verwijderen';

  @override
  String get undo => 'Ongedaan maken';

  @override
  String get done => 'Klaar';

  @override
  String get pen => 'Pen';

  @override
  String get rectangle => 'Rechthoek';

  @override
  String get color => 'Kleur';

  @override
  String get reviewTitle => 'Wat er wordt verzonden';

  @override
  String get nothingCollected => 'Niets.';

  @override
  String logsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Logs ($count regels)',
      one: 'Logs (1 regel)',
      zero: 'Logs',
    );
    return '$_temp0';
  }

  @override
  String get attachments => 'Bijlagen';

  @override
  String get sentThanks => 'Bedankt, je feedback is verzonden.';

  @override
  String get handedOff => 'Doorgegeven aan je mailapp. Druk daar op verzenden.';

  @override
  String get openFullScreen => 'Volledig scherm openen';

  @override
  String get tutorial => 'Zo meld je een probleem';

  @override
  String get skip => 'Overslaan';

  @override
  String get next => 'Volgende';

  @override
  String get tutorialShakeTitle => 'Schud je telefoon';

  @override
  String get tutorialShakeBody =>
      'Als er iets misgaat, schud je het apparaat. Er verschijnt een knopje; tik erop en kies “Feedback versturen”.';

  @override
  String get tutorialShakeSheetBody =>
      'Schud het apparaat als er iets misgaat of als je een idee hebt. Er opent een klein venster, “Feedback delen”; kies wat je ons wilt vertellen.';

  @override
  String get tutorialShakeFormBody =>
      'Als er iets misgaat, schud je het apparaat. Het formulier opent met een schermafbeelding.';

  @override
  String get tutorialOpenTitle => 'Open “Feedback versturen”';

  @override
  String get tutorialOpenBody =>
      'Als er iets misgaat, open je “Feedback versturen” via het menu. Het scherm wordt vastgelegd zoals het is.';

  @override
  String get tutorialAnnotateTitle => 'Omcirkel het probleem';

  @override
  String get tutorialAnnotateBody =>
      'Teken op de schermafbeelding waar het misgaat. Je kunt de schermafbeelding ook verwijderen.';

  @override
  String get tutorialDescribeTitle => 'Vertel wat er gebeurde';

  @override
  String get tutorialDescribeBody =>
      'Kies een categorie en beschrijf wat je deed en wat je verwachtte. “Wat wordt er verzonden?” toont de exacte inhoud.';

  @override
  String get tutorialSendTitle => 'Verstuur';

  @override
  String get tutorialSendBody =>
      'Druk op Versturen. Gaat er iets mis, dan zie je waarom en kun je het opnieuw proberen; je bericht blijft staan.';

  @override
  String get openFloating => 'Zwevend venster';

  @override
  String get yourEmail => 'Je e-mail (optioneel)';

  @override
  String get quickTitle => 'Feedback delen';

  @override
  String get quickSubtitle =>
      'Een probleem, een idee, een vraag: vertel het ons. Een schermafbeelding en de recente logs worden bijgevoegd.';

  @override
  String get quickReportProblem => 'Probleem melden';

  @override
  String get quickShareIdea => 'Idee delen';

  @override
  String get quickAskQuestion => 'Vraag stellen';

  @override
  String get drafts => 'Concepten';

  @override
  String get unsentDraft => 'Niet-verzonden concept';

  @override
  String get continueDraft => 'Concept hervatten';

  @override
  String get notNow => 'Niet nu';

  @override
  String get draftsNote => '30 dagen op dit apparaat bewaard.';

  @override
  String get continueAction => 'Hervatten';

  @override
  String get deleteAction => 'Verwijderen';

  @override
  String get discardDraft => 'Concept verwijderen';

  @override
  String get automaticDraft => 'Automatisch';

  @override
  String get afterAnError => 'na een fout';

  @override
  String get withScreenshot => 'schermafbeelding';

  @override
  String get frozenHint => 'Van toen het formulier openging';

  @override
  String get errorCardTitle => 'Er ging iets mis';

  @override
  String get errorCardBody =>
      'Er staat een rapport klaar met de schermafbeelding en wat de app deed.';

  @override
  String draftsReminderTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meldingen niet verzonden',
      one: '1 melding niet verzonden',
    );
    return '$_temp0';
  }

  @override
  String get draftsReminderBody =>
      'Ze wachten op dit apparaat tot je ze verstuurt.';

  @override
  String get openDraft => 'Bekijken';

  @override
  String get later => 'Later';

  @override
  String get addDetails => 'Details toevoegen';

  @override
  String get quietTitle => 'Voortaan stil houden?';

  @override
  String get quietBody =>
      'Na een fout wordt nog steeds een rapport voorbereid. Je vindt het onder Concepten in het formulier.';

  @override
  String get keepShowing => 'Blijven tonen';

  @override
  String get keepQuiet => 'Stil houden';
}
