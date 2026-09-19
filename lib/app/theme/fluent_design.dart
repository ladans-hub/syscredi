import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Fluent Design tokens shared by the whole workspace.
///
/// Material widgets remain available for platform integrations, while all
/// workspace surfaces consume these Microsoft Fluent timing, colour and shape
/// tokens through the inherited [fluent.FluentTheme].
fluent.FluentThemeData fluentTheme(Brightness brightness, Color accent) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: brightness,
  );
  final hsl = HSLColor.fromColor(accent);
  Color tone(double lightness) =>
      hsl.withLightness(lightness.clamp(0.08, 0.92)).toColor();
  final accentSwatch = fluent.AccentColor.swatch({
    'darkest': tone(.18),
    'darker': tone(.28),
    'dark': tone(.38),
    'normal': accent,
    'light': tone(.62),
    'lighter': tone(.72),
    'lightest': tone(.82),
  });
  return fluent.FluentThemeData(
    brightness: brightness,
    accentColor: accentSwatch,
    activeColor: scheme.onPrimary,
    inactiveColor: scheme.onSurfaceVariant,
    scaffoldBackgroundColor: scheme.surface,
    cardColor: scheme.surface,
    acrylicBackgroundColor: scheme.surface.withValues(alpha: .9),
    micaBackgroundColor: scheme.surface.withValues(alpha: .95),
    shadowColor: Colors.black.withValues(alpha: dark ? .32 : .14),
    fasterAnimationDuration: const Duration(milliseconds: 83),
    fastAnimationDuration: const Duration(milliseconds: 167),
    mediumAnimationDuration: const Duration(milliseconds: 250),
    slowAnimationDuration: const Duration(milliseconds: 358),
    animationCurve: Curves.easeOutCubic,
    fontFamily: brandVisuals.value.fontFamily == 'System'
        ? null
        : brandVisuals.value.fontFamily,
  );
}

/// A Fluent surface for dashboards, forms and report rows.
class FluentSurface extends StatelessWidget {
  const FluentSurface({required this.child, this.padding, super.key});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final fluentThemeData = fluent.FluentTheme.maybeOf(context);
    final materialTheme = Theme.of(context);
    final cardColor =
        materialTheme.cardTheme.color ?? materialTheme.colorScheme.surface;
    final shadowColor =
        fluentThemeData?.shadowColor ?? materialTheme.shadowColor;
    final duration =
        fluentThemeData?.mediumAnimationDuration ??
        const Duration(milliseconds: 250);
    final curve = fluentThemeData?.animationCurve ?? Curves.easeOutCubic;
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: materialTheme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Fluent indeterminate progress feedback used for every asynchronous action.
class FluentProcessingIndicator extends StatelessWidget {
  const FluentProcessingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    // Standalone feature tests and embedded integrations may not install the
    // app shell. Keep the indicator safe there while the real workspace uses
    // the Fluent ProgressRing.
    if (fluent.FluentTheme.maybeOf(context) == null) {
      return const SyscrediProgressIndicator(strokeWidth: 3.5);
    }
    return const fluent.ProgressRing(
      strokeWidth: 3.5,
      semanticLabel: 'A processar',
    );
  }
}
