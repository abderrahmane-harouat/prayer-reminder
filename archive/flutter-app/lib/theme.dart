/// Kimi Design System for Athan App
/// Quiet, monochrome and spacious — ported from Kimi (com.moonshot.kimichat).
///
/// Rules followed (jetpack-compose-ui skill + Kimi STYLE.md):
/// - Monochrome base: near-black on white / light gray.
/// - One blue accent (#1783FF) for links and "on" states only.
/// - Black filled pills (#191919) for primary actions, tonal gray for secondary.
/// - Floating controls (white circles/pills, soft wide shadow), no full-width bars.
/// - Grouped white cards ~20dp on #F5F5F5, thin #EEEEEE dividers.
/// - Line icons only, never filled or colored.
/// - Hierarchy from weight + color, not size jumps.
///
/// Usage:
/// ```dart
/// import 'package:your_app/theme.dart';
/// final colors = AppColors.of(context);
/// Text('Hello', style: AppTextStyles.titleMedium(context));
/// ```
library;

import 'package:flutter/cupertino.dart';

/// Design System Constants
class AppConstants {
  static const String fontFamily = 'ElMessiri';
  static const String monoFontFamily = 'SF Mono';

  // Kimi layout tokens
  static const double screenMargin = 16.0;
  static const double floatingOffset = 12.0;

  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
}

/// Kimi color palette — context-aware for light/dark.
class AppColors {
  final Brightness brightness;

  AppColors._(this.brightness);

  static AppColors of(BuildContext context) {
    final brightness =
        CupertinoTheme.of(context).brightness ?? Brightness.light;
    return AppColors._(brightness);
  }

  bool get isDark => brightness == Brightness.dark;

  // Accent — blue means "link or state", never a primary button surface.
  Color get primary => const Color(0xFF1783FF);
  Color get primaryLight => const Color(0xFF3391FE);
  Color get primaryDark => const Color(0xFF0B63CE);

  // Secondary kept for compat (rarely used in Kimi style).
  Color get secondary => CupertinoColors.systemGreen;
  Color get accent => const Color(0xFF1783FF);

  // Backgrounds — Kimi: #FFFFFF home, #F5F5F5 settings/grouped pages.
  Color get background => isDark
      ? CupertinoColors.systemBackground.darkColor
      : const Color(0xFFFFFFFF);

  Color get secondaryBackground => isDark
      ? const Color(0xFF1C1C1E)
      : const Color(0xFFF5F5F5);

  Color get surface => isDark
      ? const Color(0xFF1C1C1E)
      : const Color(0xFFFFFFFF);

  Color get cardBackground => isDark
      ? const Color(0xFF1C1C1E)
      : const Color(0xFFFFFFFF);

  // Tonal fills — chips, pills, secondary buttons.
  Color get tonalFill =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF8F8F8);
  Color get tonalFillStrong =>
      isDark ? const Color(0xFF3A3A3C) : const Color(0xFFEEEEEE);

  // Inverse — Kimi primary action: black pill, white text.
  Color get inverse => const Color(0xFF191919);
  Color get onInverse => CupertinoColors.white;

  // Text — hierarchy from weight + color.
  Color get textPrimary =>
      isDark ? CupertinoColors.white : const Color(0xFF1A1A1A);

  Color get textSecondary =>
      isDark ? const Color(0xFF8E8E93) : const Color(0xFF666666);

  Color get textTertiary =>
      isDark ? const Color(0xFF636366) : const Color(0xFF8D8D8D);

  Color get textDisabled => const Color(0xFFBEBEBE);
  Color get placeholder => const Color(0xFFBEBEBE);

  // Status
  Color get success => CupertinoColors.systemGreen;
  Color get warning => CupertinoColors.systemYellow;
  Color get error => const Color(0xFFFF3849);
  Color get info => const Color(0xFF1783FF);

  // Dividers / borders — thin #EEEEEE, almost no borders elsewhere.
  Color get divider =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEEEEEE);

  Color get border =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFEEEEEE);

  // Legacy glass tokens — mapped to solid Kimi surfaces (no translucency).
  Color get glassBackground => surface;
  Color get glassBorder => divider;
  Color get glassHighlight => surface;

  // Utilities
  Color primaryWithOpacity(double opacity) =>
      primary.withValues(alpha: opacity);
  Color blackWithOpacity(double opacity) =>
      CupertinoColors.black.withValues(alpha: opacity);
  Color whiteWithOpacity(double opacity) =>
      CupertinoColors.white.withValues(alpha: opacity);
}

/// Kimi typography — hierarchy from weight + color, not size jumps.
class AppTextStyles {
  static Color _getTextColor(BuildContext context) {
    return AppColors.of(context).textPrimary;
  }

  // Display — countdown hero only.
  static TextStyle displayLarge(BuildContext context) => TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w300,
        fontSize: 44.0,
        height: 1.15,
        letterSpacing: -0.5,
        color: _getTextColor(context),
        decoration: TextDecoration.none,
      );

  static TextStyle displayMedium(BuildContext context) => TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w300,
        fontSize: 32.0,
        height: 1.2,
        letterSpacing: -0.25,
        color: _getTextColor(context),
        decoration: TextDecoration.none,
      );

  // Answer headings (H2/H3 analogue).
  static TextStyle headlineLarge(BuildContext context) => TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 22.0,
        height: 1.5,
        color: _getTextColor(context),
        decoration: TextDecoration.none,
      );

  static TextStyle headlineMedium(BuildContext context) => TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 20.0,
        height: 1.5,
        color: _getTextColor(context),
        decoration: TextDecoration.none,
      );

  static TextStyle headlineSmall(BuildContext context) => TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 18.0,
        height: 1.5,
        color: _getTextColor(context),
        decoration: TextDecoration.none,
      );

  // Page title — Medium 18/24, centered (Kimi).
  static TextStyle titleLarge(BuildContext context) => TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 18.0,
        height: 1.35,
        color: _getTextColor(context),
        decoration: TextDecoration.none,
      );

  // List item / menu item — Regular/Medium 16/24 (Kimi).
  static TextStyle titleMedium(BuildContext context) => TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 16.0,
        height: 1.5,
        color: _getTextColor(context),
        decoration: TextDecoration.none,
      );

  static TextStyle titleSmall(BuildContext context) => TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 15.0,
        height: 1.35,
        color: _getTextColor(context),
        decoration: TextDecoration.none,
      );

  // Body — 16-17 / 26 well-typeset document text (Kimi chat answer).
  static TextStyle bodyLarge(BuildContext context) => TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 17.0,
        height: 1.55,
        color: _getTextColor(context),
        decoration: TextDecoration.none,
      );

  static TextStyle bodyMedium(BuildContext context) => TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        height: 1.5,
        color: _getTextColor(context),
        decoration: TextDecoration.none,
      );

  // Supporting text — Regular 14/20 (Kimi).
  static TextStyle bodySmall(BuildContext context) => TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 14.0,
        height: 1.45,
        color: _getTextColor(context),
        decoration: TextDecoration.none,
      );

  // Chips / small buttons — Medium 14-15/20 (Kimi).
  static TextStyle labelLarge(BuildContext context) => TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 15.0,
        height: 1.35,
        color: _getTextColor(context),
        decoration: TextDecoration.none,
      );

  static TextStyle labelMedium(BuildContext context) => TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 14.0,
        height: 1.45,
        color: _getTextColor(context),
        decoration: TextDecoration.none,
      );

  // Captions / badges — Regular 12/16-18 (Kimi).
  static TextStyle labelSmall(BuildContext context) => TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 12.0,
        height: 1.4,
        color: _getTextColor(context),
        decoration: TextDecoration.none,
      );

  // Special
  static TextStyle code(BuildContext context) => TextStyle(
        fontFamily: AppConstants.monoFontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 28.0,
        letterSpacing: 1.0,
        height: 1.2,
        color: _getTextColor(context),
        decoration: TextDecoration.none,
      );

  static TextStyle button(BuildContext context) => TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w600,
        fontSize: 16.0,
        height: 1.25,
        color: _getTextColor(context),
        decoration: TextDecoration.none,
      );

  static TextStyle caption(BuildContext context) => TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 12.0,
        height: 1.35,
        color: AppColors.of(context).textSecondary,
        decoration: TextDecoration.none,
      );
}

/// Spacing — 4, 8, 12, 16, 24, 32 (8 and 16 dominate).
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double smMd = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Semantic spacing
  static const double tiny = xs;
  static const double small = sm;
  static const double medium = md;
  static const double large = lg;
  static const double extraLarge = xl;
  static const double huge = xxl;
}

/// Radius — Kimi: cards ~20, sheets ~24 (top only), pills fully rounded.
class AppRadius {
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double pill = 999.0;

  // Semantic radius
  static const double small = xs;
  static const double medium = md;
  static const double large = lg;
  static const double card = 20.0;
  static const double sheet = 24.0;
  static const double dialog = 20.0;
  static const double popover = 16.0;
  static const double button = pill;
  static const double input = pill;
}

/// Icon sizes — 20-24dp dominates, tap target >= 48x48.
class AppIconSizes {
  static const double xs = 12.0;
  static const double sm = 16.0;
  static const double md = 20.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const double small = sm;
  static const double medium = md;
  static const double large = lg;
}

/// Kimi shadows — floating controls use a soft, wide shadow.
class AppShadows {
  static List<BoxShadow> floating(BuildContext context) {
    final colors = AppColors.of(context);
    return [
      BoxShadow(
        color: colors.textPrimary.withValues(alpha: colors.isDark ? 0.3 : 0.08),
        blurRadius: 20,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> card(BuildContext context) {
    final colors = AppColors.of(context);
    return [
      BoxShadow(
        color: colors.textPrimary.withValues(alpha: colors.isDark ? 0.25 : 0.05),
        blurRadius: 16,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];
  }
}

/// Kimi surfaces.
class AppDecorations {
  /// Grouped white card on #F5F5F5 — ~20dp corners, no border, soft shadow.
  static BoxDecoration kimiCard(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    final colors = AppColors.of(context);
    return BoxDecoration(
      color: backgroundColor ?? colors.surface,
      borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.card),
      boxShadow: AppShadows.card(context),
    );
  }

  /// Tonal card — #F8F8F8 / #EEEEEE fill, ~20dp corners, no border.
  static BoxDecoration kimiTonalCard(
    BuildContext context, {
    BorderRadius? borderRadius,
  }) {
    final colors = AppColors.of(context);
    return BoxDecoration(
      color: colors.tonalFill,
      borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.card),
    );
  }

  /// Floating control — white circle/pill with soft wide shadow.
  static BoxDecoration floatingControl(
    BuildContext context, {
    BorderRadius? borderRadius,
  }) {
    final colors = AppColors.of(context);
    return BoxDecoration(
      color: colors.surface,
      borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.pill),
      boxShadow: AppShadows.floating(context),
    );
  }

  /// Black primary pill — #191919 with white text.
  static BoxDecoration primaryPill(BuildContext context) {
    final colors = AppColors.of(context);
    return BoxDecoration(
      color: colors.inverse,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    );
  }

  /// Tonal pill — secondary actions.
  static BoxDecoration tonalPill(BuildContext context) {
    final colors = AppColors.of(context);
    return BoxDecoration(
      color: colors.tonalFillStrong,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    );
  }

  // Legacy names — reimplemented Kimi-style (solid, no translucency).
  static BoxDecoration liquidGlass(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? backgroundColor,
    Border? border,
  }) {
    return kimiCard(
      context,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
    );
  }

  static BoxDecoration cleanCard(
    BuildContext context, {
    BorderRadius? borderRadius,
  }) {
    return kimiCard(context, borderRadius: borderRadius);
  }

  static BoxDecoration expandedSection(
    BuildContext context, {
    BorderRadius? borderRadius,
  }) {
    final colors = AppColors.of(context);
    return BoxDecoration(
      color: colors.secondaryBackground.withValues(alpha: 0.6),
    );
  }
}

/// Complete Theme Data
class AppTheme {
  static final CupertinoThemeData lightTheme = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFF1783FF),
    barBackgroundColor: Color(0xFFFFFFFF),
    scaffoldBackgroundColor: Color(0xFFF5F5F5),
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        height: 1.5,
        color: Color(0xFF1A1A1A),
        decoration: TextDecoration.none,
      ),
      actionTextStyle: TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        height: 1.4,
        color: Color(0xFF1783FF),
        decoration: TextDecoration.none,
      ),
      tabLabelTextStyle: TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 12.0,
        height: 1.4,
        color: Color(0xFF8D8D8D),
        decoration: TextDecoration.none,
      ),
      navTitleTextStyle: TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 18.0,
        height: 1.35,
        color: Color(0xFF1A1A1A),
        decoration: TextDecoration.none,
      ),
      navLargeTitleTextStyle: TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w300,
        fontSize: 32.0,
        height: 1.25,
        letterSpacing: -0.25,
        color: Color(0xFF1A1A1A),
        decoration: TextDecoration.none,
      ),
      pickerTextStyle: TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        height: 1.5,
        color: Color(0xFF1A1A1A),
        decoration: TextDecoration.none,
      ),
      dateTimePickerTextStyle: TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        height: 1.5,
        color: Color(0xFF1A1A1A),
        decoration: TextDecoration.none,
      ),
    ),
  );

  static final CupertinoThemeData darkTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFF1783FF),
    barBackgroundColor: Color(0xFF000000),
    scaffoldBackgroundColor: Color(0xFF000000),
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        height: 1.5,
        color: CupertinoColors.white,
        decoration: TextDecoration.none,
      ),
      actionTextStyle: TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        height: 1.4,
        color: Color(0xFF1783FF),
        decoration: TextDecoration.none,
      ),
      tabLabelTextStyle: TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 12.0,
        height: 1.4,
        color: Color(0xFF8D8D8D),
        decoration: TextDecoration.none,
      ),
      navTitleTextStyle: TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 18.0,
        height: 1.35,
        color: CupertinoColors.white,
        decoration: TextDecoration.none,
      ),
      navLargeTitleTextStyle: TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w300,
        fontSize: 32.0,
        height: 1.25,
        letterSpacing: -0.25,
        color: CupertinoColors.white,
        decoration: TextDecoration.none,
      ),
      pickerTextStyle: TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        height: 1.5,
        color: CupertinoColors.white,
        decoration: TextDecoration.none,
      ),
      dateTimePickerTextStyle: TextStyle(
        fontFamily: AppConstants.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: 16.0,
        height: 1.5,
        color: CupertinoColors.white,
        decoration: TextDecoration.none,
      ),
    ),
  );
}
