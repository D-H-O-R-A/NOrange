import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================================================================
/// HIDE PROTOCOL — "OBSIDIAN STEALTH" DESIGN SYSTEM
/// ============================================================================
/// A studio-grade dark UI/UX system combining architectural precision,
/// high-contrast telemetry typography, and restrained tactical surfaces.

class HpColors {
  HpColors._();

  // Core Obsidian & Graphite Surfaces (Dark Mode Default)
  static const Color bgCanvas = Color(0xFF07090D);
  static const Color bgElevated = Color(0xFF0D1118);
  static const Color bgSurface = Color(0xFF131924);
  static const Color bgSurfaceHover = Color(0xFF1A2232);
  static const Color bgGlass = Color(0xCC0F141D);

  // Architectural Hairlines & Borders
  static const Color borderSubtle = Color(0xFF1E2738);
  static const Color borderStrong = Color(0xFF2C3850);

  // Proprietary Brand Accents
  static const Color accentEmerald = Color(0xFF00F59B);
  static const Color accentEmeraldDim = Color(0x2600F59B);
  static const Color accentCyan = Color(0xFF38BDF8);
  static const Color accentCyanDim = Color(0x2438BDF8);
  static const Color accentIndigo = Color(0xFF818CF8);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentAmberDim = Color(0x24F59E0B);
  static const Color accentCrimson = Color(0xFFF43F5E);
  static const Color accentCrimsonDim = Color(0x24F43F5E);

  // Typography Hierarchy
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Light Mode Counterparts (Clean Technical Alabaster when toggled)
  static const Color lightCanvas = Color(0xFFF4F6F9);
  static const Color lightElevated = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFEEF2F6);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
}

class HpRadius {
  HpRadius._();
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 22.0;
  static const double xl = 28.0;
  static const double pill = 999.0;
}

class HpSpacing {
  HpSpacing._();
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class HpTextStyles {
  HpTextStyles._();

  static const TextStyle displayTimer = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle screenTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const TextStyle sectionHeader = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.3,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const TextStyle metricValue = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );
}

class HpTheme {
  HpTheme._();

  static ThemeData get darkTheme {
    const scheme = ColorScheme.dark(
      primary: HpColors.accentEmerald,
      onPrimary: Color(0xFF04130C),
      secondary: HpColors.accentCyan,
      onSecondary: Color(0xFF04131A),
      surface: HpColors.bgElevated,
      onSurface: HpColors.textPrimary,
      error: HpColors.accentCrimson,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: HpColors.bgCanvas,
      colorScheme: scheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: HpColors.bgCanvas,
        foregroundColor: HpColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: HpColors.bgCanvas,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: HpColors.textPrimary,
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: HpColors.bgElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HpRadius.md),
          side: const BorderSide(color: HpColors.borderSubtle, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: HpColors.borderSubtle,
        thickness: 1,
        space: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HpColors.bgSurface,
        isDense: true,
        hintStyle: const TextStyle(color: HpColors.textMuted, fontSize: 13.5),
        labelStyle:
            const TextStyle(color: HpColors.textSecondary, fontSize: 13),
        floatingLabelStyle: const TextStyle(
          color: HpColors.accentEmerald,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HpRadius.sm),
          borderSide: const BorderSide(color: HpColors.borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HpRadius.sm),
          borderSide: const BorderSide(color: HpColors.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HpRadius.sm),
          borderSide:
              const BorderSide(color: HpColors.accentEmerald, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HpColors.accentEmerald,
          foregroundColor: const Color(0xFF04140D),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HpRadius.sm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HpColors.textPrimary,
          side: const BorderSide(color: HpColors.borderStrong, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HpRadius.sm),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: HpColors.bgSurface,
        selectedColor: HpColors.accentEmeraldDim,
        side: const BorderSide(color: HpColors.borderSubtle, width: 1),
        labelStyle: const TextStyle(
          color: HpColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: HpColors.accentEmerald,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HpRadius.pill),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF04140D);
          }
          return HpColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return HpColors.accentEmerald;
          }
          return HpColors.bgSurfaceHover;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return HpColors.borderStrong;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return HpColors.accentEmerald;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(const Color(0xFF04140D)),
        side: const BorderSide(color: HpColors.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: HpColors.bgElevated,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: HpColors.bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: HpColors.accentEmerald,
        foregroundColor: const Color(0xFF04140D),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HpRadius.md),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: HpColors.bgElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HpRadius.md),
          side: const BorderSide(color: HpColors.borderStrong, width: 1),
        ),
        textStyle: const TextStyle(
          color: HpColors.textPrimary,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    const scheme = ColorScheme.light(
      primary: Color(0xFF059669),
      onPrimary: Colors.white,
      secondary: Color(0xFF0284C7),
      onSecondary: Colors.white,
      surface: HpColors.lightElevated,
      onSurface: HpColors.lightTextPrimary,
      error: HpColors.accentCrimson,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: HpColors.lightCanvas,
      colorScheme: scheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: HpColors.lightCanvas,
        foregroundColor: HpColors.lightTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: HpColors.lightTextPrimary,
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: HpColors.lightElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HpRadius.md),
          side: const BorderSide(color: HpColors.lightBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: HpColors.lightBorder,
        thickness: 1,
        space: 24,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HpColors.lightSurface,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HpRadius.sm),
          borderSide: const BorderSide(color: HpColors.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HpRadius.sm),
          borderSide: const BorderSide(color: HpColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HpRadius.sm),
          borderSide: const BorderSide(color: Color(0xFF059669), width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HpRadius.sm),
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// REUSABLE DESIGN SYSTEM COMPONENTS
/// ============================================================================

class HpSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const HpSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.borderRadius = HpRadius.md,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBg =
        color ?? (isDark ? HpColors.bgElevated : HpColors.lightElevated);
    final effectiveBorder =
        borderColor ?? (isDark ? HpColors.borderSubtle : HpColors.lightBorder);

    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? effectiveBg : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: effectiveBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.selectionClick();
                  onTap!();
                }
              : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(HpSpacing.md),
            child: child,
          ),
        ),
      ),
    );

    return content;
  }
}

class HpBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final bool pulsingDot;

  const HpBadge({
    super.key,
    required this.text,
    this.color = HpColors.accentEmerald,
    this.icon,
    this.pulsingDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(HpRadius.pill),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulsingDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class HpSectionLabel extends StatelessWidget {
  final String label;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const HpSectionLabel({
    super.key,
    required this.label,
    this.trailing,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2, right: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: HpTextStyles.sectionHeader.copyWith(
              color: isDark ? HpColors.textMuted : HpColors.lightTextSecondary,
            ),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailingTap,
              child: Text(
                trailing!,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: HpColors.accentEmerald,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HpIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const HpIconBox({
    super.key,
    required this.icon,
    this.color = HpColors.accentEmerald,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}
