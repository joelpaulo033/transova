import 'package:flutter/material.dart';

class TransovaTheme {
  // Brand Color Palette Mapping

  static const Color primary = Color(0xFF000666); // Fixed invalid hex format
  static const Color primaryContainer = Color(0xFF1A237E);
  static const Color onPrimaryContainer = Color(0xFF8690EE);
  static const Color primaryFixedDim = Color(
    0xFFBDC2FF,
  ); // Updated to match tailwind-config config block precisely

  static const Color secondary = Color(0xFF006E2A);
  static const Color secondaryContainer = Color(0xFF5CFD80);
  static const Color onSecondaryContainer = Color(0xFF00732C);

  static const Color tertiary = Color(
    0xFF705D00,
  ); // Standard base variant for pending tasks
  static const Color tertiaryContainer = Color(0xFFC9A800);
  static const Color onTertiaryContainer = Color(0xFF4C3E00);

  static const Color error = Color(0xFFBA1A1A); // Urgent alert status
  static const Color errorContainer = Color(
    0xFFFFDAD6,
  ); // Updated to match config block precisely
  static const Color onErrorContainer = Color(
    0xFF93000A,
  ); // Updated to match config block precisely

  static const Color background = Color(0xFFF3FAFF);
  static const Color surface = Color(0xFFF3FAFF);
  static const Color surfaceContainer = Color(
    0xFFDBF1FE,
  ); // Updated to match config block precisely
  static const Color surfaceContainerLow = Color(0xFFE6F6FF);
  static const Color surfaceContainerHigh = Color(0xFFD5ECF8);
  static const Color surfaceContainerHighest = Color(0xFFCFE6F2);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  // Additional Tailwind Configuration Brand Colors Added Below:
  static const Color onSecondaryFixed = Color(0xFF002108);
  static const Color onSecondaryFixedVariant = Color(0xFF00531E);
  static const Color inverseSurface = Color(0xFF1E333C);
  static const Color onTertiaryFixed = Color(0xFF221B00);
  static const Color inverseOnSurface = Color(0xFFDFF4FF);
  static const Color tertiaryFixedDim = Color(0xFFE9C400);
  static const Color surfaceBright = Color(0xFFF3FAFF);
  static const Color surfaceVariant = Color(0xFFCFE6F2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color surfaceTint = Color(0xFF4C56AF);
  static const Color onPrimaryFixedVariant = Color(0xFF343D96);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onPrimaryFixed = Color(0xFF000767);
  static const Color onTertiaryFixedVariant = Color(0xFF544600);
  static const Color inversePrimary = Color(0xFFBDC2FF);
  static const Color secondaryFixedDim = Color(0xFF3CE36A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFE0E0FF);
  static const Color surfaceDim = Color(0xFFC7DDE9);
  static const Color secondaryFixed = Color(0xFF69FF87);
  static const Color tertiaryFixed = Color(0xFFFFE170);
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color onSurface = Color(0xFF071E27);
  static const Color onSurfaceVariant = Color(0xFF454652);
  static const Color outline = Color(
    0xFF767683,
  ); // Action boundaries token updated to match config block precisely
  static const Color outlineVariant = Color(0xFFC6C5D4);
  static const Color onBackground = Color(0xFF071E27);

  // Status Logistics Visual Layer Configurations
  static Color statusInTransitBg = const Color(0xFF00C853).withOpacity(0.10);
  static const Color statusInTransitText = Color(0xFF00C853);
  static const Color statusDelayedBg = Color(0xFFFFE170);
  static const Color statusDelayedText = Color(0xFF221B00);
  static const Color statusCancelledBg = Color(0xFFFFDAD6);
  static const Color statusCancelledText = Color(0xFFBA1A1A);

  // Shape Language Tokens (Converted from specification measurements)
  static const double radiusSm = 4.0; // 0.25rem
  static const double radiusDefault =
      8.0; // 0.5rem (Standard Buttons & Input Form Fields)
  static const double radiusMd = 12.0; // 0.75rem
  static const double radiusLg = 16.0; // 1rem (Cards & Container Dashboards)
  static const double radiusXl = 24.0; // 1.5rem
  static const double radiusFull = 9999.0; // Status Chips Pill Shape

  // Spatial Grid Spacing Variables
  static const double spaceXs = 4.0;
  static const double spaceBase = 8.0;
  static const double spaceSm = 12.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double spaceGutter = 24.0;
  static const double marginMobile = 16.0;
  static const double marginDesktop = 32.0;

  // Data Table Layout Metrics
  static const double tableRowStandardHeight = 48.0;
  static const double tableRowDenseHeight = 36.0;

  // Elevation Level Shadows
  static final BoxBorder level1Border = Border.all(
    color: outlineVariant,
    width: 1.0,
  );
  static final List<BoxShadow> level2Shadow = [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.05),
      blurRadius: 12.0,
      offset: const Offset(0, 4),
    ),
  ];
  static final List<BoxShadow> level3Shadow = [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.15),
      blurRadius: 24.0,
      offset: const Offset(0, 8),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        inversePrimary: inversePrimary,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceVariant,
        onSurfaceVariant: onSurfaceVariant,
        inverseSurface: inverseSurface,
        onInverseSurface: inverseOnSurface,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        // display-lg
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          color: onSurface,
          height: 1.12, // 64px / 57px
          letterSpacing: -1.14,
        ),
        // headline-lg
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: primary,
          height: 1.25, // 40px / 32px
        ),
        // headline-lg-mobile
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primary,
          height: 1.28, // 36px / 28px
        ),
        // title-md
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: onSurface,
          height: 1.5, // 24px / 16px
        ),
        // body-lg
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: onSurface,
          height: 1.5, // 24px / 16px
        ),
        // body-md
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onSurfaceVariant,
          height: 1.42, // 20px / 14px
        ),
        // label-sm
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.45, // 16px / 11px
        ),
      ),

      // Integrated Input Form Decorations Strategy Rules
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: outline, width: 1.0),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radiusDefault),
            topRight: Radius.circular(radiusDefault),
          ),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: outline, width: 1.0),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: primary, width: 2.0),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: error, width: 1.0),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceSm,
        ),
      ),

      // Integrated Custom Button Themes Configuration Helpers
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLg,
            vertical: spaceSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusDefault),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLg,
            vertical: spaceSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusDefault),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  /// Extension functional style accessor for data-heavy layout scanning layers
  static TextStyle getTabularDataStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: FontWeight.w500,
      fontSize: 14,
      height: 1.42,
    );
  }
}
