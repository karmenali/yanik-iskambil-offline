import 'package:flutter/widgets.dart';
import 'app_localizations.dart';
import 'app_localizations_tr.dart';

export 'app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this) ?? AppLocalizationsTr();
}

AppLocalizations l10nOf(BuildContext context) =>
    AppLocalizations.of(context) ?? AppLocalizationsTr();
