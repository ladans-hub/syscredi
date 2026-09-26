import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'design_tokens.dart';

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
        borderRadius: BorderRadius.circular(FluentTokens.radius12),
        border: Border.all(
          color: Color.lerp(
            materialTheme.colorScheme.outlineVariant,
            materialTheme.colorScheme.primary,
            .14,
          )!,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: materialTheme.colorScheme.primary.withValues(alpha: .035),
            blurRadius: 2,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Shared action primitives. These wrappers keep new screens on the same
/// density, typography and motion as the existing workspace.
class FluentActionButton extends StatelessWidget {
  const FluentActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = FluentActionKind.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final FluentActionKind kind;

  @override
  Widget build(BuildContext context) {
    final child = Text(label);
    return switch (kind) {
      FluentActionKind.primary =>
        icon == null
            ? FilledButton(onPressed: onPressed, child: child)
            : FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: child,
              ),
      FluentActionKind.secondary =>
        icon == null
            ? OutlinedButton(onPressed: onPressed, child: child)
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: child,
              ),
      FluentActionKind.subtle =>
        icon == null
            ? TextButton(onPressed: onPressed, child: child)
            : TextButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: child,
              ),
    };
  }
}

enum FluentActionKind { primary, secondary, subtle }

class FluentIconButton extends StatelessWidget {
  const FluentIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: FluentTokens.iconMedium),
  );
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
