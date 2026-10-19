import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ============================================================================
/// NORANGE — "OBSIDIAN BLACK & SOLAR ORANGE" DESIGN SYSTEM
/// ============================================================================
/// Deep Black (#060608), Charcoal/Graphite surfaces (#0E0F13 / #15171E),
/// and Solar Orange (#FF6B00) primary brand accent with neutral grey hierarchy.

class HpColors {
  HpColors._();

  // Deep Black & Charcoal Graphite Surfaces
  static const Color bgCanvas = Color(0xFF060608);
  static const Color bgElevated = Color(0xFF0E0F13);
  static const Color bgSurface = Color(0xFF15171E);
  static const Color bgSurfaceHover = Color(0xFF1E212B);
  static const Color bgGlass = Color(0xE60E0F13);

  // Subtle Neutral Hairlines & Borders
  static const Color borderSubtle = Color(0xFF222530);
  static const Color borderStrong = Color(0xFF323646);

  // Primary Brand Accent: Solar Orange (#FF6B00) & Warm Amber
  static const Color accentOrange = Color(0xFFFF6B00);
  static const Color accentOrangeLight = Color(0xFFFF8833);
  static const Color accentOrangeDim = Color(0x24FF6B00);

  // Semantic aliases unified into the Black, Graphite & Orange hierarchy
  static const Color accentEmerald = Color(0xFFFF6B00);
  static const Color accentEmeraldDim = Color(0x24FF6B00);
  static const Color accentCyan = Color(0xFFFF8533);
  static const Color accentCyanDim = Color(0x1FFF8533);
  static const Color accentIndigo = Color(0xFFCBD5E1);
  static const Color accentAmber = Color(0xFFFF9E3D);
  static const Color accentAmberDim = Color(0x24FF9E3D);
  static const Color accentCrimson = Color(0xFFEF4444);
  static const Color accentCrimsonDim = Color(0x24EF4444);

  // Typography Hierarchy (Soft White & Neutral Greys)
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // High-Contrast Light Mode Counterparts (when toggled)
  static const Color lightCanvas = Color(0xFFF5F5F7);
  static const Color lightElevated = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFECECEF);
  static const Color lightBorder = Color(0xFFDCDCE2);
  static const Color lightTextPrimary = Color(0xFF090A0F);
  static const Color lightTextSecondary = Color(0xFF52525B);
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
      primary: HpColors.accentOrange,
      onPrimary: Color(0xFF08080A),
      secondary: HpColors.accentOrangeLight,
      onSecondary: Color(0xFF08080A),
      surface: HpColors.bgElevated,
      onSurface: HpColors.textPrimary,
      error: HpColors.accentCrimson,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: HpColors.bgCanvas,
      colorScheme: scheme,
      splashFactory: InkRipple.splashFactory,
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
        isDense: false,
        hintStyle: const TextStyle(color: HpColors.textMuted, fontSize: 14.5),
        labelStyle:
            const TextStyle(color: HpColors.textSecondary, fontSize: 14),
        floatingLabelStyle: const TextStyle(
          color: HpColors.accentOrange,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HpRadius.md),
          borderSide: const BorderSide(color: HpColors.borderSubtle, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HpRadius.md),
          borderSide: const BorderSide(color: HpColors.borderSubtle, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HpRadius.md),
          borderSide:
              const BorderSide(color: HpColors.accentOrange, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HpColors.accentOrange,
          foregroundColor: const Color(0xFF09090B),
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HpRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HpColors.textPrimary,
          side: const BorderSide(color: HpColors.borderStrong, width: 1.2),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HpRadius.md),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: HpColors.bgSurface,
        selectedColor: HpColors.accentOrangeDim,
        side: const BorderSide(color: HpColors.borderSubtle, width: 1),
        labelStyle: const TextStyle(
          color: HpColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: HpColors.accentOrange,
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
            return const Color(0xFF08080A);
          }
          return HpColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return HpColors.accentOrange;
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
            return HpColors.accentOrange;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(const Color(0xFF08080A)),
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
        backgroundColor: HpColors.accentOrange,
        foregroundColor: const Color(0xFF08080A),
        elevation: 2,
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
      primary: HpColors.accentOrange,
      onPrimary: Colors.white,
      secondary: Color(0xFF18181B),
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
      splashFactory: InkRipple.splashFactory,
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
        isDense: false,
        hintStyle: const TextStyle(color: HpColors.lightTextSecondary, fontSize: 14.5),
        labelStyle:
            const TextStyle(color: HpColors.lightTextSecondary, fontSize: 14),
        floatingLabelStyle: const TextStyle(
          color: HpColors.accentOrange,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HpRadius.md),
          borderSide: const BorderSide(color: HpColors.lightBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HpRadius.md),
          borderSide: const BorderSide(color: HpColors.lightBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HpRadius.md),
          borderSide:
              const BorderSide(color: HpColors.accentOrange, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HpColors.accentOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HpRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HpColors.lightTextPrimary,
          side: const BorderSide(color: HpColors.lightBorder, width: 1.2),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HpRadius.md),
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

    return Container(
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
    this.color = HpColors.accentOrange,
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trailing!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: HpColors.accentOrange,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: HpColors.accentOrange,
                  ),
                ],
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
    this.color = HpColors.accentOrange,
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
        border: Border.all(color: color.withOpacity(0.28), width: 1),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}
