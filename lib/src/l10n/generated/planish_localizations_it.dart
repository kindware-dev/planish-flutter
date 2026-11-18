// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'planish_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class PlanishLocalizationsIt extends PlanishLocalizations {
  PlanishLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get debugButtonLabel => 'Apri strumenti di debug';

  @override
  String get debugTools => 'Strumenti di debug';

  @override
  String get sendFeedback => 'Invia feedback';

  @override
  String get hideDebugButton => 'Nascondi pulsante di debug';

  @override
  String get console => 'Console';

  @override
  String get network => 'Rete';

  @override
  String get deviceInfo => 'Dispositivo e app';

  @override
  String get preferences => 'Preferenze condivise';

  @override
  String get close => 'Chiudi';

  @override
  String get copy => 'Copia';

  @override
  String get copied => 'Copiato negli appunti';

  @override
  String get clear => 'Cancella';

  @override
  String get filterHint => 'Filtra';

  @override
  String get noLogs => 'Ancora nessun log.';

  @override
  String get noNetworkCalls =>
      'Nessuna chiamata di rete registrata. Usa LoggingHttpClient per le richieste per vederle qui.';

  @override
  String get noPreferences => 'Nessuna preferenza salvata.';

  @override
  String get error => 'Errore';

  @override
  String get request => 'Richiesta';

  @override
  String get response => 'Risposta';

  @override
  String get headers => 'Intestazioni';

  @override
  String get body => 'Corpo';

  @override
  String get sendFeedbackTitle => 'Invia feedback';

  @override
  String get reportProblemTitle => 'Segnala un problema';

  @override
  String get cancel => 'Annulla';

  @override
  String get errorBanner =>
      'Qualcosa è andato storto. Raccontarci cosa stavi facendo ci aiuta a correggerlo.';

  @override
  String get category => 'Categoria';

  @override
  String get categoryBug => 'Bug';

  @override
  String get categoryIdea => 'Idea';

  @override
  String get categoryQuestion => 'Domanda';

  @override
  String get categoryOther => 'Altro';

  @override
  String get messageHint => 'Cosa è successo? Cosa ti aspettavi?';

  @override
  String get messageHintIdea =>
      'Cosa ti piacerebbe vedere e a cosa ti servirebbe?';

  @override
  String get messageHintQuestion => 'Cosa stai cercando di fare?';

  @override
  String get messageHintOther => 'Raccontaci tutto.';

  @override
  String get message => 'Messaggio';

  @override
  String get emptyMessage => '(vuoto)';

  @override
  String get includeLogs => 'Includi i log recenti';

  @override
  String get reviewData => 'Cosa verrà inviato?';

  @override
  String get send => 'Invia';

  @override
  String get retry => 'Riprova';

  @override
  String get sendCancelled =>
      'Non è stato inviato nulla. Il tuo messaggio è ancora qui.';

  @override
  String sendFailed(String reason) {
    return 'Invio non riuscito: $reason';
  }

  @override
  String get screenshot => 'Schermata';

  @override
  String get annotate => 'Annota';

  @override
  String get removeScreenshot => 'Rimuovi';

  @override
  String get undo => 'Annulla';

  @override
  String get done => 'Fatto';

  @override
  String get pen => 'Penna';

  @override
  String get rectangle => 'Rettangolo';

  @override
  String get color => 'Colore';

  @override
  String get reviewTitle => 'Cosa verrà inviato';

  @override
  String get nothingCollected => 'Niente.';

  @override
  String logsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Log ($count voci)',
      one: 'Log (1 voce)',
      zero: 'Log',
    );
    return '$_temp0';
  }

  @override
  String get attachments => 'Allegati';

  @override
  String get sentThanks => 'Grazie, il tuo feedback è stato inviato.';

  @override
  String get handedOff =>
      'Passato alla tua app di posta. Premi invia lì per inoltrarlo.';

  @override
  String get openFullScreen => 'Apri a schermo intero';

  @override
  String get tutorial => 'Come segnalare un problema';

  @override
  String get skip => 'Salta';

  @override
  String get next => 'Avanti';

  @override
  String get tutorialShakeTitle => 'Scuoti il telefono';

  @override
  String get tutorialShakeBody =>
      'Quando qualcosa non va, scuoti il dispositivo. Compare un piccolo pulsante; toccalo e scegli «Invia feedback».';

  @override
  String get tutorialShakeSheetBody =>
      'Scuoti il dispositivo quando qualcosa non va o ti viene un\'idea. Si apre un piccolo pannello, «Condividi un feedback»; scegli cosa vuoi dirci.';

  @override
  String get tutorialShakeFormBody =>
      'Quando qualcosa non va, scuoti il dispositivo. Il modulo si apre con uno screenshot dello schermo.';

  @override
  String get tutorialOpenTitle => 'Apri «Invia feedback»';

  @override
  String get tutorialOpenBody =>
      'Quando qualcosa non va, apri «Invia feedback» dal menu. Lo schermo viene catturato così com\'è.';

  @override
  String get tutorialAnnotateTitle => 'Cerchia il problema';

  @override
  String get tutorialAnnotateBody =>
      'Disegna sulla schermata per mostrare dove si blocca. Puoi anche rimuovere la schermata.';

  @override
  String get tutorialDescribeTitle => 'Racconta cosa è successo';

  @override
  String get tutorialDescribeBody =>
      'Scegli una categoria e descrivi cosa hai fatto e cosa ti aspettavi. «Cosa verrà inviato?» mostra il contenuto esatto.';

  @override
  String get tutorialSendTitle => 'Invia';

  @override
  String get tutorialSendBody =>
      'Premi Invia. Se qualcosa va storto, vedrai il motivo e potrai riprovare; il messaggio resta.';

  @override
  String get openFloating => 'Finestra flottante';

  @override
  String get yourEmail => 'La tua e-mail (facoltativa)';

  @override
  String get quickTitle => 'Condividi un feedback';

  @override
  String get quickSubtitle =>
      'Un problema, un\'idea, una domanda: raccontacelo. Verranno allegati una schermata e i log recenti.';

  @override
  String get quickReportProblem => 'Segnala un problema';

  @override
  String get quickShareIdea => 'Condividi un\'idea';

  @override
  String get quickAskQuestion => 'Fai una domanda';

  @override
  String get drafts => 'Bozze';

  @override
  String get unsentDraft => 'Bozza non inviata';

  @override
  String get continueDraft => 'Riprendi la bozza';

  @override
  String get notNow => 'Non ora';

  @override
  String get draftsNote => 'Conservate su questo dispositivo per 30 giorni.';

  @override
  String get continueAction => 'Riprendi';

  @override
  String get deleteAction => 'Elimina';

  @override
  String get discardDraft => 'Elimina bozza';

  @override
  String get automaticDraft => 'Automatica';

  @override
  String get afterAnError => 'dopo un errore';

  @override
  String get withScreenshot => 'screenshot';

  @override
  String get frozenHint => 'Da quando si è aperto il modulo';

  @override
  String get errorCardTitle => 'Qualcosa è andato storto';

  @override
  String get errorCardBody =>
      'È pronto un report con lo screenshot e ciò che l\'app stava facendo.';

  @override
  String draftsReminderTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count segnalazioni non inviate',
      one: '1 segnalazione non inviata',
    );
    return '$_temp0';
  }

  @override
  String get draftsReminderBody =>
      'Restano su questo dispositivo finché non le invii.';

  @override
  String get openDraft => 'Vedi';

  @override
  String get later => 'Più tardi';

  @override
  String get addDetails => 'Aggiungi dettagli';

  @override
  String get quietTitle => 'Restare discreti?';

  @override
  String get quietBody =>
      'Dopo un errore verrà comunque preparato un report. Lo troverai tra le bozze del modulo.';

  @override
  String get keepShowing => 'Continua a mostrare';

  @override
  String get keepQuiet => 'Resta discreto';
}
