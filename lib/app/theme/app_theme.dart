import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'local_brand_image.dart';
import 'design_tokens.dart';

/// Single source of truth for the institution's visual identity.
const green = Color(0xFF21A56B);
const navy = Color(0xFF152739);

class BrandPalette {
  const BrandPalette(this.primary, this.secondary);
  final Color primary;
  final Color secondary;
}

class BrandVisuals {
  const BrandVisuals({
    this.logo,
    this.alternateLogo,
    this.favicon,
    this.institutionName,
    this.institutionBio,
    this.compactSidebar = false,
    this.navigationIcons = true,
    this.watermark,
    this.stamp,
    this.signature,
    this.heroGradientStart = navy,
    this.heroGradientEnd = const Color(0xFF203B52),
    this.fontScale = 1.0,
    this.fontFamily = 'System',
    this.watermarkEnabled = true,
    this.watermarkOpacity = .045,
    this.watermarkSize = 560,
    this.watermarkPosition = 'Centro',
    this.radius = 8,
    this.density = 'Confortável',
    this.accent = const Color(0xff0078d4),
  });

  final bool watermarkEnabled;
  final double watermarkOpacity, watermarkSize, radius;
  final String watermarkPosition, density;
  final Color accent;
  final String? alternateLogo, favicon, institutionName, institutionBio;
  final bool compactSidebar, navigationIcons;
  final String? logo;
  final String? watermark;
  final String? stamp;
  final String? signature;
  final Color heroGradientStart;
  final Color heroGradientEnd;
  final double fontScale;
  final String fontFamily;

  BrandVisuals copyWith({
    String? logo,
    String? watermark,
    String? stamp,
    String? signature,
    Color? heroGradientStart,
    Color? heroGradientEnd,
    double? fontScale,
    String? fontFamily,
  }) => BrandVisuals(
    alternateLogo: alternateLogo,
    favicon: favicon,
    institutionName: institutionName,
    institutionBio: institutionBio,
    compactSidebar: compactSidebar,
    navigationIcons: navigationIcons,
    watermarkEnabled: watermarkEnabled,
    watermarkOpacity: watermarkOpacity,
    watermarkSize: watermarkSize,
    watermarkPosition: watermarkPosition,
    radius: radius,
    density: density,
    accent: accent,
    logo: logo ?? this.logo,
    watermark: watermark ?? this.watermark,
    stamp: stamp ?? this.stamp,
    signature: signature ?? this.signature,
    heroGradientStart: heroGradientStart ?? this.heroGradientStart,
    heroGradientEnd: heroGradientEnd ?? this.heroGradientEnd,
    fontScale: fontScale ?? this.fontScale,
    fontFamily: fontFamily ?? this.fontFamily,
  );
}

final brandPalette = ValueNotifier<BrandPalette>(
  const BrandPalette(green, navy),
);
final brandVisuals = ValueNotifier<BrandVisuals>(const BrandVisuals());

/// Theme selected by the current workspace. Shared with popup selectors so
/// the active option is always indicated when a menu is opened.
final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);
final currencyCode = ValueNotifier<String>('MT');
final localeCode = ValueNotifier<String>('pt_MZ');

/// Unified circular progress indicator used throughout the application.
/// The size changes with its container, while colour, track and stroke remain
/// consistent with the premium processing screen.
class SyscrediProgressIndicator extends StatelessWidget {
  const SyscrediProgressIndicator({
    this.size = 24,
    this.strokeWidth,
    this.color,
    this.backgroundColor,
    super.key,
  });
  final double size;
  final double? strokeWidth;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final primary = color ?? brandPalette.value.primary;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth ?? (size * .07).clamp(2.2, 5.0),
        valueColor: AlwaysStoppedAnimation<Color>(primary),
        backgroundColor: backgroundColor ?? primary.withValues(alpha: .16),
      ),
    );
  }
}

class CenteredLoadingState extends StatelessWidget {
  const CenteredLoadingState({
    required this.message,
    this.minimumHeight = 360,
    super.key,
  });

  final String message;
  final double minimumHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      width: double.infinity,
      height: constraints.hasBoundedHeight
          ? constraints.maxHeight
          : minimumHeight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SyscrediProgressIndicator(size: 42),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}

Color parseBrandColor(String raw, Color fallback) {
  final decimal = int.tryParse(raw.trim());
  if (decimal != null) return Color(decimal);
  final legacy = int.tryParse(raw.replaceFirst('#', ''), radix: 16);
  return legacy == null ? fallback : Color(0xFF000000 | legacy);
}

/// Shared semantic colours for screens that need status accents.
abstract final class AppColors {
  static Color danger(BuildContext context) =>
      Theme.of(context).colorScheme.error;
  static Color warning(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;
  static Color info(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
  static Color muted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
  static Color localBanner(BuildContext context) =>
      Theme.of(context).colorScheme.tertiaryContainer;
}

abstract final class AppAssets {
  static const authBackground = 'assets/images/auth-background.png';
  static const registerBackground = 'assets/images/register-background.png';
  static const entrepreneur = 'assets/images/entrepreneur.png';
  static const syscrediLogo = 'assets/images/logo.png';
}

Widget? brandImage(String path, double size) {
  if (path.startsWith('data:image/')) {
    try {
      return Image.memory(
        base64Decode(path.split(',').last),
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, error, stack) => const SizedBox.shrink(),
      );
    } catch (_) {
      return null;
    }
  }
  return localBrandImage(path, size);
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({this.size = 38, this.fallbackColor, this.color, super.key});
  final double size;
  final Color? fallbackColor, color;

  @override
  Widget build(BuildContext context) {
    final visuals = brandVisuals.value;
    final path = size <= 32 && visuals.favicon != null
        ? visuals.favicon
        : Theme.of(context).brightness == Brightness.dark &&
              visuals.alternateLogo != null
        ? visuals.alternateLogo
        : visuals.logo;
    if (path != null && path.isNotEmpty) {
      final image = brandImage(path, size);
      if (image != null) return image;
    }
    return Image.asset(
      AppAssets.syscrediLogo,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color,
      errorBuilder: (_, error, stack) =>
          SyscrediMark(size: size, color: fallbackColor ?? green),
    );
  }
}

class PremiumProcessingScreen extends StatelessWidget {
  const PremiumProcessingScreen({
    required this.title,
    required this.subtitle,
    super.key,
  });
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([brandPalette, brandVisuals]),
    builder: (context, _) {
      final palette = brandPalette.value;
      final base = Color.lerp(Colors.black, palette.secondary, .22)!;
      final glow = Color.lerp(Colors.black, palette.primary, .24)!;
      return Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-.72, .95),
              radius: 1.25,
              colors: [glow, base, const Color(0xFF020807)],
              stops: const [0, .48, 1],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: .18),
                        Colors.black.withValues(alpha: .42),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SyscrediProgressIndicator(
                        size: 72,
                        strokeWidth: 5,
                        color: palette.primary,
                        backgroundColor: Colors.white.withValues(alpha: .18),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .70),
                          fontSize: 17,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Native fallback mark used when an institution has not uploaded a logo yet.
class SyscrediMark extends StatelessWidget {
  const SyscrediMark({this.size = 38, this.color = green, super.key});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: FittedBox(
      fit: BoxFit.contain,
      child: Text(
        'SC',
        style: TextStyle(
          color: color,
          fontSize: 100,
          fontWeight: FontWeight.w900,
          letterSpacing: -9,
          height: 1,
        ),
      ),
    ),
  );
}

/// Subtle institutional mark shared by every application surface.
/// It is deliberately rendered above the page in an IgnorePointer so it never
/// interferes with forms, tables, dialogs or navigation.
class BrandWatermarkOverlay extends StatelessWidget {
  const BrandWatermarkOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final visuals = brandVisuals.value;
    if (!visuals.watermarkEnabled) return const SizedBox.shrink();
    final path = visuals.watermark ?? visuals.logo;
    final image = path == null ? null : brandImage(path, visuals.watermarkSize);
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.center,
          child: Opacity(
            opacity: visuals.watermarkOpacity.clamp(0, .15),
            child: image ?? BrandLogo(size: visuals.watermarkSize),
          ),
        ),
      ),
    );
  }
}

ThemeData appTheme(
  Brightness b, [
  BrandPalette palette = const BrandPalette(green, navy),
]) {
  final scheme = ColorScheme.fromSeed(
    seedColor: palette.primary,
    brightness: b,
  );
  return ThemeData(
    useMaterial3: true,
    visualDensity: switch (brandVisuals.value.density) {
      'Compacta' => VisualDensity.compact,
      'Espaçosa' => const VisualDensity(horizontal: 1, vertical: 1),
      _ => VisualDensity.standard,
    },
    fontFamily: brandVisuals.value.fontFamily == 'System'
        ? ((defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS)
              ? '.SF Pro Text'
              : null)
        : brandVisuals.value.fontFamily,
    brightness: b,
    colorScheme: scheme.copyWith(
      primary: palette.primary,
      onPrimary: palette.primary.computeLuminance() > .179
          ? Colors.black
          : Colors.white,
      tertiary: brandVisuals.value.accent,
      onTertiary: brandVisuals.value.accent.computeLuminance() > .179
          ? Colors.black
          : Colors.white,
      secondary: b == Brightness.dark
          ? scheme.onSurfaceVariant
          : palette.secondary,
    ),
    scaffoldBackgroundColor: scheme.surface,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: .1,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -.1,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -.2,
      ),
      titleLarge: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w800,
        letterSpacing: -.5,
      ),
    ).apply(fontSizeFactor: brandVisuals.value.fontScale),
    cardTheme: CardThemeData(
      elevation: 1,
      shadowColor: scheme.shadow.withValues(
        alpha: b == Brightness.dark ? .24 : .10,
      ),
      surfaceTintColor: Colors.transparent,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        // A barely tinted keyline gives surfaces the crisp layering used by
        // Fluent without competing with the content inside the card.
        side: BorderSide(
          color: Color.lerp(scheme.outlineVariant, scheme.primary, .16)!,
        ),
        borderRadius: BorderRadius.circular(FluentTokens.radius12),
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      titleSpacing: FluentTokens.space24,
      centerTitle: false,
      toolbarHeight: 64,
      shape: Border(
        bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: .8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      // A little extra vertical breathing room keeps every form readable,
      // including forms assembled dynamically by the workspace.
      contentPadding: const EdgeInsets.symmetric(
        horizontal: FluentTokens.space16,
        vertical: FluentTokens.space12,
      ),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
      floatingLabelStyle: TextStyle(
        color: palette.primary,
        fontWeight: FontWeight.w700,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(brandVisuals.value.radius),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(brandVisuals.value.radius),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(brandVisuals.value.radius),
        borderSide: BorderSide(color: palette.primary, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(brandVisuals.value.radius),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(brandVisuals.value.radius),
        borderSide: BorderSide(color: scheme.error),
      ),
      errorStyle: const TextStyle(fontSize: 11, height: 1.2),
      helperStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      alignment: Alignment.center,
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 560),
      actionsPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FluentTokens.radius12),
      ),
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        fixedSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(brandVisuals.value.radius),
        ),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        backgroundColor: palette.primary,
        foregroundColor: b == Brightness.light ? Colors.white : Colors.black,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(brandVisuals.value.radius),
        ),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        foregroundColor: palette.primary,
        side: BorderSide(color: palette.primary),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(brandVisuals.value.radius),
        ),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      shadowColor: scheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FluentTokens.radius12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: scheme.onSurface, fontSize: 13),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(brandVisuals.value.radius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        foregroundColor: palette.primary,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(brandVisuals.value.radius),
        ),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        backgroundColor: palette.primary,
        foregroundColor: b == Brightness.light ? Colors.white : Colors.black,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(brandVisuals.value.radius),
        ),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
  );
}
