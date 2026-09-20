import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'app/bootstrap/root.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/fluent_design.dart';

class SyscrediApp extends StatelessWidget {
  const SyscrediApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([themeMode, brandPalette, brandVisuals]),
    builder: (context, _) => MaterialApp(
      title: 'Syscredi',
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light, brandPalette.value),
      darkTheme: appTheme(Brightness.dark, brandPalette.value),
      themeMode: themeMode.value,
      builder: (context, child) => fluent.FluentTheme(
        data: fluentTheme(
          Theme.of(context).brightness,
          brandPalette.value.primary,
        ),
        child: Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const BrandWatermarkOverlay(),
          ],
        ),
      ),
      home: Root(onTheme: (value) => themeMode.value = value),
    ),
  );
}
