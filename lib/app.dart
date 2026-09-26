import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app/bootstrap/root.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/fluent_design.dart';

class SyscrediApp extends StatelessWidget {
  const SyscrediApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      themeMode,
      brandPalette,
      brandVisuals,
      localeCode,
    ]),
    builder: (context, _) => MaterialApp(
      title: 'Syscredi',
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light, brandPalette.value),
      darkTheme: appTheme(Brightness.dark, brandPalette.value),
      themeMode: themeMode.value,
      locale: Locale.fromSubtags(
        languageCode: localeCode.value.split('_').first,
        countryCode: localeCode.value.contains('_')
            ? localeCode.value.split('_').last
            : null,
      ),
      supportedLocales: const [
        Locale('pt', 'MZ'),
        Locale('pt', 'PT'),
        Locale('en'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => fluent.FluentTheme(
        data: fluentTheme(
          Theme.of(context).brightness,
          brandPalette.value.primary,
        ),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Root(onTheme: (value) => themeMode.value = value),
    ),
  );
}
