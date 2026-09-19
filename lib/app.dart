import 'package:flutter/material.dart';
import 'app/bootstrap/root.dart';
import 'app/theme/app_theme.dart';

class SysCrediApp extends StatelessWidget {
  const SysCrediApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: themeMode,
    builder: (context, mode, _) => MaterialApp(
      title: 'SysCredi',
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light, brandPalette.value),
      darkTheme: appTheme(Brightness.dark, brandPalette.value),
      themeMode: mode,
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox.shrink(),
          const BrandWatermarkOverlay(),
        ],
      ),
      home: Root(onTheme: (value) => themeMode.value = value),
    ),
  );
}
