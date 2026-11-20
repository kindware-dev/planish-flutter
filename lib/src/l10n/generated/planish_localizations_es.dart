// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'planish_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class PlanishLocalizationsEs extends PlanishLocalizations {
  PlanishLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get debugButtonLabel => 'Abrir herramientas de depuración';

  @override
  String get debugTools => 'Herramientas de depuración';

  @override
  String get sendFeedback => 'Enviar comentarios';

  @override
  String get hideDebugButton => 'Ocultar botón de depuración';

  @override
  String get console => 'Consola';

  @override
  String get network => 'Red';

  @override
  String get deviceInfo => 'Dispositivo y app';

  @override
  String get preferences => 'Preferencias compartidas';

  @override
  String get close => 'Cerrar';

  @override
  String get copy => 'Copiar';

  @override
  String get copied => 'Copiado al portapapeles';

  @override
  String get clear => 'Borrar';

  @override
  String get filterHint => 'Filtrar';

  @override
  String get noLogs => 'Todavía no hay registros.';

  @override
  String get noNetworkCalls =>
      'No se registraron llamadas de red. Haz las peticiones a través de LoggingHttpClient para verlas aquí.';

  @override
  String get noPreferences => 'No hay preferencias guardadas.';

  @override
  String get error => 'Error';

  @override
  String get request => 'Petición';

  @override
  String get response => 'Respuesta';

  @override
  String get headers => 'Cabeceras';

  @override
  String get body => 'Cuerpo';

  @override
  String get sendFeedbackTitle => 'Enviar comentarios';

  @override
  String get reportProblemTitle => 'Informar de un problema';

  @override
  String get cancel => 'Cancelar';

  @override
  String get errorBanner =>
      'Algo salió mal. Contarnos qué estabas haciendo nos ayuda a corregirlo.';

  @override
  String get category => 'Categoría';

  @override
  String get categoryBug => 'Error';

  @override
  String get categoryIdea => 'Idea';

  @override
  String get categoryQuestion => 'Pregunta';

  @override
  String get categoryOther => 'Otro';

  @override
  String get messageHint => '¿Qué ocurrió? ¿Qué esperabas?';

  @override
  String get messageHintIdea => '¿Qué te gustaría ver y para qué te serviría?';

  @override
  String get messageHintQuestion => '¿Qué intentas hacer?';

  @override
  String get messageHintOther => 'Cuéntanos lo que quieras.';

  @override
  String get message => 'Mensaje';

  @override
  String get emptyMessage => '(vacío)';

  @override
  String get includeLogs => 'Incluir registros recientes';

  @override
  String get reviewData => '¿Qué se enviará?';

  @override
  String get send => 'Enviar';

  @override
  String get retry => 'Reintentar';

  @override
  String get sendCancelled => 'No se envió nada. Tu mensaje sigue aquí.';

  @override
  String sendFailed(String reason) {
    return 'No se pudo enviar: $reason';
  }

  @override
  String get screenshot => 'Captura de pantalla';

  @override
  String get annotate => 'Anotar';

  @override
  String get removeScreenshot => 'Quitar';

  @override
  String get undo => 'Deshacer';

  @override
  String get done => 'Listo';

  @override
  String get pen => 'Lápiz';

  @override
  String get rectangle => 'Rectángulo';

  @override
  String get color => 'Color';

  @override
  String get reviewTitle => 'Lo que se enviará';

  @override
  String get nothingCollected => 'Nada.';

  @override
  String logsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Registros ($count entradas)',
      one: 'Registros (1 entrada)',
      zero: 'Registros',
    );
    return '$_temp0';
  }

  @override
  String get attachments => 'Adjuntos';

  @override
  String get sentThanks => 'Gracias, tus comentarios se han enviado.';

  @override
  String get handedOff =>
      'Entregado a tu app de correo. Pulsa enviar allí para mandarlo.';

  @override
  String get openFullScreen => 'Abrir a pantalla completa';

  @override
  String get tutorial => 'Cómo informar de un problema';

  @override
  String get skip => 'Omitir';

  @override
  String get next => 'Siguiente';

  @override
  String get tutorialShakeTitle => 'Agita el teléfono';

  @override
  String get tutorialShakeBody =>
      'Cuando algo falle, agita el dispositivo. Aparece un pequeño botón; tócalo y elige «Enviar comentarios».';

  @override
  String get tutorialShakeSheetBody =>
      'Agita el dispositivo cuando algo falle o se te ocurra una idea. Se abre una pequeña ventana, «Compartir comentarios»; elige lo que quieres contarnos.';

  @override
  String get tutorialShakeFormBody =>
      'Cuando algo falle, agita el dispositivo. El formulario se abre con una captura de la pantalla.';

  @override
  String get tutorialOpenTitle => 'Abre «Enviar comentarios»';

  @override
  String get tutorialOpenBody =>
      'Cuando algo falle, abre «Enviar comentarios» desde el menú. La pantalla se captura tal cual.';

  @override
  String get tutorialAnnotateTitle => 'Rodea el problema';

  @override
  String get tutorialAnnotateBody =>
      'Dibuja sobre la captura para mostrar dónde falla. También puedes quitar la captura.';

  @override
  String get tutorialDescribeTitle => 'Cuéntanos qué pasó';

  @override
  String get tutorialDescribeBody =>
      'Elige una categoría y describe qué hiciste y qué esperabas. «¿Qué se enviará?» muestra el contenido exacto.';

  @override
  String get tutorialSendTitle => 'Envíalo';

  @override
  String get tutorialSendBody =>
      'Pulsa Enviar. Si algo falla, verás el motivo y podrás reintentar; tu mensaje se conserva.';

  @override
  String get openFloating => 'Ventana flotante';

  @override
  String get yourEmail => 'Tu correo (opcional)';

  @override
  String get quickTitle => 'Compartir comentarios';

  @override
  String get quickSubtitle =>
      'Se adjuntarán una captura de esta pantalla y los registros recientes.';

  @override
  String get quickReportProblem => 'Informar de un problema';

  @override
  String get quickShareIdea => 'Compartir una idea';

  @override
  String get quickAskQuestion => 'Hacer una pregunta';

  @override
  String get quickProblemHint => 'Algo no funciona como se esperaba';

  @override
  String get quickIdeaHint => 'Algo podría funcionar aún mejor';

  @override
  String get quickQuestionHint => 'Algo no está claro';

  @override
  String get drafts => 'Borradores';

  @override
  String get unsentDraft => 'Borrador sin enviar';

  @override
  String get continueDraft => 'Continuar el borrador';

  @override
  String get notNow => 'Ahora no';

  @override
  String get draftsNote =>
      'Informes que empezaste y no enviaste. Se guardan 30 días.';

  @override
  String get continueAction => 'Continuar';

  @override
  String get deleteAction => 'Eliminar';

  @override
  String get discardDraft => 'Descartar borrador';

  @override
  String get automaticDraft => 'Automático';

  @override
  String get afterAnError => 'tras un error';

  @override
  String get withScreenshot => 'captura';

  @override
  String get frozenHint => 'De cuando se abrió el formulario';

  @override
  String get errorCardTitle => 'Algo salió mal';

  @override
  String get errorCardBody =>
      'Hay un informe listo con la captura y lo que estaba haciendo la app.';

  @override
  String draftsReminderTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count informes sin enviar',
      one: '1 informe sin enviar',
    );
    return '$_temp0';
  }

  @override
  String get draftsReminderBody =>
      'Esperan en este dispositivo hasta que los envíes.';

  @override
  String get openDraft => 'Ver';

  @override
  String get later => 'Más tarde';

  @override
  String get addDetails => 'Añadir detalles';

  @override
  String get quietTitle => '¿Mantenerlo discreto?';

  @override
  String get quietBody =>
      'Se seguirá preparando un informe tras cada error. Lo encontrarás en Borradores, en el formulario.';

  @override
  String get keepShowing => 'Seguir mostrando';

  @override
  String get keepQuiet => 'Mantener discreto';

  @override
  String errorsCaught(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count errores detectados',
      one: '1 error detectado',
    );
    return '$_temp0';
  }

  @override
  String get errorsCaughtHint => 'Informa de uno si lo viste ocurrir';

  @override
  String errorOnScreen(String screen) {
    return 'Error en $screen';
  }

  @override
  String get errorInApp => 'Error en la app';

  @override
  String get reportAction => 'Informar';

  @override
  String get deleteAllDrafts => 'Eliminar todos los borradores';

  @override
  String get deleteAllDraftsConfirm =>
      '¿Eliminar todos los borradores? No se podrán recuperar.';

  @override
  String get noMessageYet => 'Aún sin mensaje';
}
