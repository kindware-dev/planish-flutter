import 'package:flutter/widgets.dart';
import 'package:planish/src/l10n/generated/planish_localizations.dart';

export 'package:planish/src/l10n/generated/planish_localizations.dart'
    show PlanishLocalizations;

/// Like the generated delegate, but never fails: unsupported locales get
/// English. Used by the host so apps need no setup; also fine to list in
/// `localizationsDelegates`.
class PlanishLocalizationsDelegate
    extends LocalizationsDelegate<PlanishLocalizations> {
  const PlanishLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<PlanishLocalizations> load(Locale locale) {
    final inner = PlanishLocalizations.delegate;
    return inner.load(inner.isSupported(locale) ? locale : const Locale('en'));
  }

  @override
  bool shouldReload(PlanishLocalizationsDelegate old) => false;
}

/// Adds the package strings below [context] unless the app already did.
Widget withPackageLocalizations(BuildContext context, Widget child) {
  final present =
      Localizations.of<PlanishLocalizations>(context, PlanishLocalizations) !=
      null;
  if (present) {
    return child;
  }
  return Localizations.override(
    context: context,
    delegates: const [PlanishLocalizationsDelegate()],
    child: child,
  );
}

extension PlanishL10nContext on BuildContext {
  PlanishLocalizations get planishStrings => PlanishLocalizations.of(this);
}
