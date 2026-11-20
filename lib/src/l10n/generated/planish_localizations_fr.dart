// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'planish_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class PlanishLocalizationsFr extends PlanishLocalizations {
  PlanishLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get debugButtonLabel => 'Ouvrir les outils de debug';

  @override
  String get debugTools => 'Outils de debug';

  @override
  String get sendFeedback => 'Envoyer un retour';

  @override
  String get hideDebugButton => 'Masquer le bouton de debug';

  @override
  String get console => 'Console';

  @override
  String get network => 'Réseau';

  @override
  String get deviceInfo => 'Appareil et application';

  @override
  String get preferences => 'Préférences partagées';

  @override
  String get close => 'Fermer';

  @override
  String get copy => 'Copier';

  @override
  String get copied => 'Copié dans le presse-papiers';

  @override
  String get clear => 'Effacer';

  @override
  String get filterHint => 'Filtrer';

  @override
  String get noLogs => 'Aucun log pour le moment.';

  @override
  String get noNetworkCalls =>
      'Aucun appel réseau enregistré. Passez vos requêtes par LoggingHttpClient pour les voir ici.';

  @override
  String get noPreferences => 'Aucune préférence enregistrée.';

  @override
  String get error => 'Erreur';

  @override
  String get request => 'Requête';

  @override
  String get response => 'Réponse';

  @override
  String get headers => 'En-têtes';

  @override
  String get body => 'Corps';

  @override
  String get sendFeedbackTitle => 'Envoyer un retour';

  @override
  String get reportProblemTitle => 'Signaler un problème';

  @override
  String get cancel => 'Annuler';

  @override
  String get errorBanner =>
      'Une erreur s\'est produite. Décrire ce que vous faisiez nous aide à la corriger.';

  @override
  String get category => 'Catégorie';

  @override
  String get categoryBug => 'Bug';

  @override
  String get categoryIdea => 'Idée';

  @override
  String get categoryQuestion => 'Question';

  @override
  String get categoryOther => 'Autre';

  @override
  String get messageHint => 'Que s\'est-il passé ? Qu\'attendiez-vous ?';

  @override
  String get messageHintIdea =>
      'Qu\'aimeriez-vous voir, et à quoi cela vous servirait-il ?';

  @override
  String get messageHintQuestion => 'Qu\'essayez-vous de faire ?';

  @override
  String get messageHintOther => 'Dites-nous tout.';

  @override
  String get message => 'Message';

  @override
  String get emptyMessage => '(vide)';

  @override
  String get includeLogs => 'Joindre les logs récents';

  @override
  String get reviewData => 'Qu\'est-ce qui sera envoyé ?';

  @override
  String get send => 'Envoyer';

  @override
  String get retry => 'Réessayer';

  @override
  String get sendCancelled =>
      'Rien n\'a été envoyé. Votre message est toujours là.';

  @override
  String sendFailed(String reason) {
    return 'Envoi impossible : $reason';
  }

  @override
  String get screenshot => 'Capture d\'écran';

  @override
  String get annotate => 'Annoter';

  @override
  String get removeScreenshot => 'Retirer';

  @override
  String get undo => 'Annuler';

  @override
  String get done => 'Terminé';

  @override
  String get pen => 'Crayon';

  @override
  String get rectangle => 'Rectangle';

  @override
  String get color => 'Couleur';

  @override
  String get reviewTitle => 'Ce qui sera envoyé';

  @override
  String get nothingCollected => 'Rien.';

  @override
  String logsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Logs ($count entrées)',
      one: 'Logs (1 entrée)',
      zero: 'Logs',
    );
    return '$_temp0';
  }

  @override
  String get attachments => 'Pièces jointes';

  @override
  String get sentThanks => 'Merci, votre retour a été envoyé.';

  @override
  String get handedOff =>
      'Remis à votre application mail. Appuyez sur envoyer pour le transmettre.';

  @override
  String get openFullScreen => 'Ouvrir en plein écran';

  @override
  String get tutorial => 'Comment signaler un problème';

  @override
  String get skip => 'Passer';

  @override
  String get next => 'Suivant';

  @override
  String get tutorialShakeTitle => 'Secouez votre téléphone';

  @override
  String get tutorialShakeBody =>
      'Dès que quelque chose cloche, secouez l\'appareil. Un petit bouton apparaît ; touchez-le et choisissez « Envoyer un retour ».';

  @override
  String get tutorialShakeSheetBody =>
      'Secouez l\'appareil dès que quelque chose cloche ou qu\'une idée vous vient. Une petite feuille s\'ouvre, « Partager un retour » ; choisissez ce que vous voulez nous dire.';

  @override
  String get tutorialShakeFormBody =>
      'Dès que quelque chose cloche, secouez l\'appareil. Le formulaire s\'ouvre avec une capture de l\'écran.';

  @override
  String get tutorialOpenTitle => 'Ouvrez « Envoyer un retour »';

  @override
  String get tutorialOpenBody =>
      'Dès que quelque chose cloche, ouvrez « Envoyer un retour » depuis le menu. L\'écran est capturé tel quel.';

  @override
  String get tutorialAnnotateTitle => 'Entourez le problème';

  @override
  String get tutorialAnnotateBody =>
      'Dessinez sur la capture pour montrer où ça coince. Vous pouvez aussi retirer la capture.';

  @override
  String get tutorialDescribeTitle => 'Racontez ce qui s\'est passé';

  @override
  String get tutorialDescribeBody =>
      'Choisissez une catégorie et décrivez ce que vous faisiez et ce que vous attendiez. « Qu\'est-ce qui sera envoyé ? » montre le contenu exact du rapport.';

  @override
  String get tutorialSendTitle => 'Envoyez';

  @override
  String get tutorialSendBody =>
      'Appuyez sur Envoyer. En cas de problème, la raison s\'affiche et vous pouvez réessayer ; votre message est conservé.';

  @override
  String get openFloating => 'Fenêtre flottante';

  @override
  String get yourEmail => 'Votre e-mail (facultatif)';

  @override
  String get quickTitle => 'Partager un retour';

  @override
  String get quickSubtitle =>
      'Une capture de cet écran et les derniers logs seront joints.';

  @override
  String get quickReportProblem => 'Signaler un problème';

  @override
  String get quickShareIdea => 'Proposer une idée';

  @override
  String get quickAskQuestion => 'Poser une question';

  @override
  String get quickProblemHint => 'Quelque chose ne fonctionne pas comme prévu';

  @override
  String get quickIdeaHint => 'Quelque chose pourrait être encore mieux';

  @override
  String get quickQuestionHint => 'Quelque chose n\'est pas clair';

  @override
  String get drafts => 'Brouillons';

  @override
  String get unsentDraft => 'Brouillon non envoyé';

  @override
  String get continueDraft => 'Reprendre le brouillon';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get draftsNote => 'Gardés sur cet appareil pendant 30 jours.';

  @override
  String get continueAction => 'Reprendre';

  @override
  String get deleteAction => 'Supprimer';

  @override
  String get discardDraft => 'Supprimer le brouillon';

  @override
  String get automaticDraft => 'Automatique';

  @override
  String get afterAnError => 'après une erreur';

  @override
  String get withScreenshot => 'capture';

  @override
  String get frozenHint => 'Au moment où le formulaire s\'est ouvert';

  @override
  String get errorCardTitle => 'Un problème est survenu';

  @override
  String get errorCardBody =>
      'Un rapport est prêt avec la capture et ce que faisait l\'app.';

  @override
  String draftsReminderTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rapports non envoyés',
      one: '1 rapport non envoyé',
    );
    return '$_temp0';
  }

  @override
  String get draftsReminderBody =>
      'Ils restent sur cet appareil jusqu\'à ce que vous les envoyiez.';

  @override
  String get openDraft => 'Voir';

  @override
  String get later => 'Plus tard';

  @override
  String get addDetails => 'Ajouter des détails';

  @override
  String get quietTitle => 'Rester discret ?';

  @override
  String get quietBody =>
      'Un rapport sera toujours préparé après une erreur. Vous le retrouverez dans les brouillons du formulaire.';

  @override
  String get keepShowing => 'Continuer à afficher';

  @override
  String get keepQuiet => 'Rester discret';
}
