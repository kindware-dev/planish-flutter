import 'package:flutter/widgets.dart';

/// The example screen's texts, in the package's languages, so switching
/// language visibly changes the whole app and not only Planish's screens.
class ExampleStrings {
  const ExampleStrings({
    required this.appTitle,
    required this.toggleDark,
    required this.language,
    required this.heroTitle,
    required this.heroDebugOn,
    required this.heroDebugOff,
    required this.sendFeedback,
    required this.simulateShake,
    required this.sendVia,
    required this.email,
    required this.debugTools,
    required this.floatingButton,
    required this.allowTools,
    required this.allowToolsHint,
    required this.buttonVisible,
    required this.buttonHidden,
    required this.openConsole,
    required this.showTutorial,
    required this.activity,
    required this.writeLogs,
    required this.httpCall,
    required this.httpFail,
    required this.flutterError,
    required this.flutterErrorHint,
    required this.asyncError,
    required this.asyncErrorHint,
    required this.errorsHint,
    required this.footnote,
    required this.featureFlags,
    required this.clearCache,
    required this.cacheCleared,
  });

  static ExampleStrings of(BuildContext context) =>
      _all[Localizations.localeOf(context).languageCode] ?? _en;

  final String appTitle;
  final String toggleDark;
  final String language;
  final String heroTitle;
  final String heroDebugOn;
  final String heroDebugOff;
  final String sendFeedback;
  final String simulateShake;
  final String sendVia;
  final String email;
  final String debugTools;
  final String floatingButton;
  final String allowTools;
  final String allowToolsHint;
  final String buttonVisible;
  final String buttonHidden;
  final String openConsole;
  final String showTutorial;
  final String activity;
  final String writeLogs;
  final String httpCall;
  final String httpFail;
  final String flutterError;
  final String flutterErrorHint;
  final String asyncError;
  final String asyncErrorHint;
  final String errorsHint;
  final String footnote;
  final String featureFlags;
  final String clearCache;
  final String cacheCleared;
}

const Map<String, ExampleStrings> _all = <String, ExampleStrings>{
  'de': _de,
  'en': _en,
  'es': _es,
  'fr': _fr,
  'it': _it,
  'nl': _nl,
};

const ExampleStrings _en = ExampleStrings(
  appTitle: 'Feedback example',
  toggleDark: 'Toggle dark mode',
  language: 'Language',
  heroTitle: 'Shake to report a problem',
  heroDebugOn: 'Debug tools are on: shaking shows the debug button instead.',
  heroDebugOff: 'A small sheet asks what went wrong, then the form opens.',
  sendFeedback: 'Send feedback',
  simulateShake: 'Simulate shake',
  sendVia: 'Send reports via',
  email: 'Email',
  debugTools: 'Debug tools',
  floatingButton: 'Floating debug button',
  allowTools: 'Debug tools on this device',
  allowToolsHint: 'As for a tester: allowed by the app, kept across restarts',
  buttonVisible: 'Visible · shake hides it',
  buttonHidden: 'Hidden · shake shows it',
  openConsole: 'Open floating console',
  showTutorial: 'Show tutorial',
  activity: 'Produce some activity',
  writeLogs: 'Write logs',
  httpCall: 'HTTP call',
  httpFail: 'Failing call',
  flutterError: 'Flutter error',
  flutterErrorHint: 'Throws StateError',
  asyncError: 'Async error',
  asyncErrorHint: 'Unawaited Future fails',
  errorsHint:
      "After an error a card offers to report it: at most once every 3 seconds here (30 by default) and 3 times per launch.",
  footnote:
      'Warnings and errors are also forwarded to CrashReporterSink '
      '(senders.dart). Feature flags (plugins.dart) appear in the debug menu '
      'and in every report.',
  featureFlags: 'Feature flags',
  clearCache: 'Clear cache',
  cacheCleared: 'Cache cleared',
);

const ExampleStrings _fr = ExampleStrings(
  appTitle: 'Exemple de feedback',
  toggleDark: 'Basculer le mode sombre',
  language: 'Langue',
  heroTitle: 'Secouez pour signaler un problème',
  heroDebugOn:
      'Les outils de debug sont actifs : secouer affiche le bouton de debug.',
  heroDebugOff:
      'Une petite feuille demande ce qui ne va pas, puis le formulaire s’ouvre.',
  sendFeedback: 'Envoyer un retour',
  simulateShake: 'Secouer',
  sendVia: 'Envoyer les rapports par',
  email: 'E-mail',
  debugTools: 'Outils de debug',
  floatingButton: 'Bouton de debug flottant',
  allowTools: 'Outils de debug sur cet appareil',
  allowToolsHint:
      'Comme pour un testeur : autorisés par l\'app, gardés au redémarrage',
  buttonVisible: 'Visible · secouer le masque',
  buttonHidden: 'Masqué · secouer l’affiche',
  openConsole: 'Ouvrir la console flottante',
  showTutorial: 'Afficher le tutoriel',
  activity: 'Générer de l’activité',
  writeLogs: 'Écrire des logs',
  httpCall: 'Appel HTTP',
  httpFail: 'Appel en échec',
  flutterError: 'Erreur Flutter',
  flutterErrorHint: 'Lance une StateError',
  asyncError: 'Erreur asynchrone',
  asyncErrorHint: 'Un Future non attendu échoue',
  errorsHint:
      "Après une erreur, une carte propose de la signaler : au plus une fois toutes les 3 secondes ici (30 par défaut) et 3 fois par lancement.",
  footnote:
      'Les avertissements et les erreurs sont aussi transmis à '
      'CrashReporterSink (senders.dart). Les feature flags (plugins.dart) '
      'apparaissent dans le menu de debug et dans chaque rapport.',
  featureFlags: 'Feature flags',
  clearCache: 'Vider le cache',
  cacheCleared: 'Cache vidé',
);

const ExampleStrings _de = ExampleStrings(
  appTitle: 'Feedback-Beispiel',
  toggleDark: 'Dunkelmodus umschalten',
  language: 'Sprache',
  heroTitle: 'Schütteln, um ein Problem zu melden',
  heroDebugOn:
      'Die Debug-Werkzeuge sind aktiv: Schütteln zeigt stattdessen den '
      'Debug-Button.',
  heroDebugOff:
      'Ein kleines Blatt fragt, was nicht stimmt, dann öffnet sich das '
      'Formular.',
  sendFeedback: 'Feedback senden',
  simulateShake: 'Schütteln',
  sendVia: 'Berichte senden über',
  email: 'E-Mail',
  debugTools: 'Debug-Werkzeuge',
  floatingButton: 'Schwebender Debug-Button',
  allowTools: 'Debug-Tools auf diesem Gerät',
  allowToolsHint:
      'Wie für Tester: von der App freigegeben, bleiben nach Neustart',
  buttonVisible: 'Sichtbar · Schütteln blendet ihn aus',
  buttonHidden: 'Ausgeblendet · Schütteln zeigt ihn',
  openConsole: 'Schwebende Konsole öffnen',
  showTutorial: 'Anleitung zeigen',
  activity: 'Etwas Aktivität erzeugen',
  writeLogs: 'Logs schreiben',
  httpCall: 'HTTP-Aufruf',
  httpFail: 'Fehlschlagender Aufruf',
  flutterError: 'Flutter-Fehler',
  flutterErrorHint: 'Wirft einen StateError',
  asyncError: 'Asynchroner Fehler',
  asyncErrorHint: 'Nicht erwartetes Future schlägt fehl',
  errorsHint:
      "Nach einem Fehler bietet eine Karte an, ihn zu melden: hier höchstens alle 3 Sekunden (standardmäßig 30) und 3-mal pro Start.",
  footnote:
      'Warnungen und Fehler gehen auch an CrashReporterSink (senders.dart). '
      'Feature-Flags (plugins.dart) erscheinen im Debug-Menü und in jedem '
      'Bericht.',
  featureFlags: 'Feature-Flags',
  clearCache: 'Cache leeren',
  cacheCleared: 'Cache geleert',
);

const ExampleStrings _es = ExampleStrings(
  appTitle: 'Ejemplo de feedback',
  toggleDark: 'Cambiar el modo oscuro',
  language: 'Idioma',
  heroTitle: 'Agita para informar de un problema',
  heroDebugOn:
      'Las herramientas de depuración están activas: agitar muestra el botón '
      'de depuración.',
  heroDebugOff:
      'Una pequeña hoja pregunta qué ha fallado y luego se abre el formulario.',
  sendFeedback: 'Enviar comentario',
  simulateShake: 'Agitar',
  sendVia: 'Enviar informes por',
  email: 'Correo',
  debugTools: 'Herramientas de depuración',
  floatingButton: 'Botón de depuración flotante',
  allowTools: 'Herramientas de depuración en este dispositivo',
  allowToolsHint:
      'Como para un tester: las permite la app, se mantienen al reiniciar',
  buttonVisible: 'Visible · agitar lo oculta',
  buttonHidden: 'Oculto · agitar lo muestra',
  openConsole: 'Abrir la consola flotante',
  showTutorial: 'Mostrar el tutorial',
  activity: 'Generar algo de actividad',
  writeLogs: 'Escribir logs',
  httpCall: 'Llamada HTTP',
  httpFail: 'Llamada fallida',
  flutterError: 'Error de Flutter',
  flutterErrorHint: 'Lanza un StateError',
  asyncError: 'Error asíncrono',
  asyncErrorHint: 'Falla un Future no esperado',
  errorsHint:
      "Tras un error, una tarjeta propone notificarlo: como mucho cada 3 segundos aquí (30 por defecto) y 3 veces por inicio.",
  footnote:
      'Los avisos y errores también se envían a CrashReporterSink '
      '(senders.dart). Los feature flags (plugins.dart) aparecen en el menú de '
      'depuración y en cada informe.',
  featureFlags: 'Feature flags',
  clearCache: 'Vaciar la caché',
  cacheCleared: 'Caché vaciada',
);

const ExampleStrings _it = ExampleStrings(
  appTitle: 'Esempio di feedback',
  toggleDark: 'Attiva/disattiva tema scuro',
  language: 'Lingua',
  heroTitle: 'Scuoti per segnalare un problema',
  heroDebugOn:
      'Gli strumenti di debug sono attivi: scuotendo appare il pulsante di '
      'debug.',
  heroDebugOff:
      'Un piccolo pannello chiede cosa non va, poi si apre il modulo.',
  sendFeedback: 'Invia feedback',
  simulateShake: 'Scuoti',
  sendVia: 'Invia i report tramite',
  email: 'Email',
  debugTools: 'Strumenti di debug',
  floatingButton: 'Pulsante di debug mobile',
  allowTools: 'Strumenti di debug su questo dispositivo',
  allowToolsHint:
      'Come per un tester: consentiti dall\'app, restano dopo il riavvio',
  buttonVisible: 'Visibile · scuotere lo nasconde',
  buttonHidden: 'Nascosto · scuotere lo mostra',
  openConsole: 'Apri la console mobile',
  showTutorial: 'Mostra il tutorial',
  activity: 'Genera un po’ di attività',
  writeLogs: 'Scrivi log',
  httpCall: 'Chiamata HTTP',
  httpFail: 'Chiamata fallita',
  flutterError: 'Errore Flutter',
  flutterErrorHint: 'Lancia uno StateError',
  asyncError: 'Errore asincrono',
  asyncErrorHint: 'Un Future non atteso fallisce',
  errorsHint:
      "Dopo un errore una scheda propone di segnalarlo: al massimo ogni 3 secondi qui (30 di default) e 3 volte per avvio.",
  footnote:
      'Avvisi ed errori sono inoltrati anche a CrashReporterSink '
      '(senders.dart). I feature flag (plugins.dart) compaiono nel menu di '
      'debug e in ogni report.',
  featureFlags: 'Feature flag',
  clearCache: 'Svuota la cache',
  cacheCleared: 'Cache svuotata',
);

const ExampleStrings _nl = ExampleStrings(
  appTitle: 'Feedbackvoorbeeld',
  toggleDark: 'Donkere modus wisselen',
  language: 'Taal',
  heroTitle: 'Schud om een probleem te melden',
  heroDebugOn: 'De debugtools staan aan: schudden toont de debugknop.',
  heroDebugOff:
      'Een klein venster vraagt wat er misging, daarna opent het formulier.',
  sendFeedback: 'Feedback sturen',
  simulateShake: 'Schudden',
  sendVia: 'Rapporten sturen via',
  email: 'E-mail',
  debugTools: 'Debugtools',
  floatingButton: 'Zwevende debugknop',
  allowTools: 'Debugtools op dit apparaat',
  allowToolsHint:
      'Zoals voor een tester: door de app toegestaan, blijven na herstart',
  buttonVisible: 'Zichtbaar · schudden verbergt hem',
  buttonHidden: 'Verborgen · schudden toont hem',
  openConsole: 'Zwevende console openen',
  showTutorial: 'Uitleg tonen',
  activity: 'Wat activiteit maken',
  writeLogs: 'Logs schrijven',
  httpCall: 'HTTP-aanroep',
  httpFail: 'Mislukte aanroep',
  flutterError: 'Flutter-fout',
  flutterErrorHint: 'Gooit een StateError',
  asyncError: 'Asynchrone fout',
  asyncErrorHint: 'Niet-afgewachte Future mislukt',
  errorsHint:
      "Na een fout biedt een kaart aan om die te melden: hier hooguit elke 3 seconden (standaard 30) en 3 keer per start.",
  footnote:
      'Waarschuwingen en fouten gaan ook naar CrashReporterSink '
      '(senders.dart). Feature flags (plugins.dart) staan in het debugmenu en '
      'in elk rapport.',
  featureFlags: 'Feature flags',
  clearCache: 'Cache wissen',
  cacheCleared: 'Cache gewist',
);
