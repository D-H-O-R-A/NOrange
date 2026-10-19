import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ============================================================================
// NORANGE — FUTURISTIC GEOMETRIC ORANGE BRAND EMBLEM & VECTOR GRAPHICS
// ============================================================================

/// Minimalist, futuristic, geometric Orange emblem for the NOrange brand.
/// Renders crisp vector geometry at any size (Splash, Header, Floating Widget).
class NOrangeLogo extends StatelessWidget {
  final double size;
  final bool showGlow;
  final bool showContainer;

  const NOrangeLogo({
    super.key,
    this.size = 42,
    this.showGlow = false,
    this.showContainer = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NOrangeEmblemPainter(
          showGlow: showGlow,
          showContainer: showContainer,
        ),
      ),
    );
  }
}

/// Typography lockup for NOrange ("N" in Soft White + "Orange" in Solar Orange).
class NOrangeWordmark extends StatelessWidget {
  final double fontSize;
  final String? subtitle;

  const NOrangeWordmark({
    super.key,
    this.fontSize = 18,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
              height: 1.05,
              fontFamily: 'Roboto',
            ),
            children: [
              TextSpan(
                text: 'N',
                style: TextStyle(
                  color: isDark ? HpColors.textPrimary : HpColors.lightTextPrimary,
                ),
              ),
              const TextSpan(
                text: 'Orange',
                style: TextStyle(
                  color: HpColors.accentOrange,
                ),
              ),
            ],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: (fontSize * 0.52).clamp(9.0, 12.0),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: HpColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _NOrangeEmblemPainter extends CustomPainter {
  final bool showGlow;
  final bool showContainer;

  _NOrangeEmblemPainter({
    required this.showGlow,
    required this.showContainer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (showContainer) {
      final rect = Offset.zero & size;
      final rrect = RRect.fromRectAndRadius(
        rect.deflate(w * 0.03),
        Radius.circular(w * 0.24),
      );

      final bgPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF15171F),
            Color(0xFF08090C),
          ],
        ).createShader(rect);
      canvas.drawRRect(rrect, bgPaint);

      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.025).clamp(1.0, 2.2)
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF8833).withOpacity(0.55),
            const Color(0xFF232632),
          ],
        ).createShader(rect);
      canvas.drawRRect(rrect, borderPaint);
    }

    // Center of the geometric citrus silhouette (slightly below midpoint to balance top leaf)
    final cx = w * 0.50;
    final cy = h * (showContainer ? 0.545 : 0.535);
    final r = w * (showContainer ? 0.315 : 0.375);

    if (showGlow) {
      final glowPaint = Paint()
        ..color = HpColors.accentOrange.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset(cx, cy), r * 0.95, glowPaint);
    }

    // 1. Outer Precision Citrus Rind Ring
    final rindPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.125).clamp(1.4, 6.0)
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF9E44),
          Color(0xFFFF6B00),
          Color(0xFFD94E00),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, rindPaint);

    // 2. Six Geometric Citrus Segments with Structural Channels
    final segOuter = r * 0.80;
    final segInner = r * 0.23;
    const gapDeg = 7.5;

    final segmentColors = <Color>[
      const Color(0xFFFF9E44), // Top-Right: Futuristic offset innovation wedge
      const Color(0xFFFF6B00), // Bottom-Right
      const Color(0xFFE65C00), // Bottom
      const Color(0xFFD45200), // Bottom-Left
      const Color(0xFFEC6200), // Top-Left
      const Color(0xFFFF8524), // Top
    ];

    for (int i = 0; i < 6; i++) {
      final startDeg = -60.0 + i * 60.0 + gapDeg;
      final endDeg = -60.0 + (i + 1) * 60.0 - gapDeg;
      final sweepRad = (endDeg - startDeg) * math.pi / 180.0;
      final startRad = startDeg * math.pi / 180.0;
      final midRad = ((startDeg + endDeg) * 0.5) * math.pi / 180.0;

      // Subtle technological offset on top-right wedge (index 0)
      final offsetDist = i == 0 ? r * 0.05 : 0.0;
      final scx = cx + offsetDist * math.cos(midRad);
      final scy = cy + offsetDist * math.sin(midRad);
      final currentOuter = i == 0 ? segOuter * 1.04 : segOuter;

      final segPath = Path()
        ..arcTo(
          Rect.fromCircle(center: Offset(scx, scy), radius: currentOuter),
          startRad,
          sweepRad,
          true,
        )
        ..arcTo(
          Rect.fromCircle(center: Offset(scx, scy), radius: segInner),
          startRad + sweepRad,
          -sweepRad,
          false,
        )
        ..close();

      final segPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = segmentColors[i];
      canvas.drawPath(segPath, segPaint);
    }

    // 3. Central Geometric Core Node
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (r * 0.055).clamp(1.0, 3.0)
      ..color = const Color(0xFFFF9E44);
    canvas.drawCircle(Offset(cx, cy), r * 0.14, corePaint);

    final coreDotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFB366);
    canvas.drawCircle(Offset(cx, cy), r * 0.05, coreDotPaint);

    // 4. Minimalist Geometric Stem & Leaf Vector at Top
    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (r * 0.085).clamp(1.2, 4.5)
      ..color = const Color(0xFFF8FAFC);
    canvas.drawLine(
      Offset(cx, cy - r * 1.04),
      Offset(cx, cy - r * 1.24),
      stemPaint,
    );

    final leafPath = Path()
      ..moveTo(cx + r * 0.08, cy - r * 1.08)
      ..quadraticBezierTo(
        cx + r * 0.30,
        cy - r * 1.38,
        cx + r * 0.68,
        cy - r * 1.24,
      )
      ..quadraticBezierTo(
        cx + r * 0.46,
        cy - r * 0.96,
        cx + r * 0.08,
        cy - r * 1.08,
      )
      ..close();

    final leafPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFFFFB86B),
          Color(0xFFFF6B00),
        ],
      ).createShader(
        Rect.fromLTRB(cx, cy - r * 1.38, cx + r * 0.70, cy - r * 0.96),
      );
    canvas.drawPath(leafPath, leafPaint);
  }

  @override
  bool shouldRepaint(covariant _NOrangeEmblemPainter oldDelegate) =>
      oldDelegate.showGlow != showGlow ||
      oldDelegate.showContainer != showContainer;
}

/// Contextual vector radar illustration for the Wi-Fi Wave Proximity Radar section.
class WifiWaveRadarGraphic extends StatelessWidget {
  final List<Map<String, dynamic>> devices;

  const WifiWaveRadarGraphic({super.key, required this.devices});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF08090C),
        borderRadius: BorderRadius.circular(HpRadius.md),
        border: Border.all(color: HpColors.borderSubtle),
      ),
      child: CustomPaint(
        painter: _RadarScopePainter(devicesCount: devices.length),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: HpColors.accentOrange.withOpacity(0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: HpColors.accentOrange, width: 1.4),
                ),
                child: const Icon(
                  Icons.wifi_tethering_rounded,
                  color: HpColors.accentOrange,
                  size: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${devices.length} ONDA(S) DETECTADA(S)',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: HpColors.accentOrange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadarScopePainter extends CustomPainter {
  final int devicesCount;

  _RadarScopePainter({required this.devicesCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) * 0.44;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF222530);

    final accentRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFFF6B00).withOpacity(0.28);

    canvas.drawCircle(center, maxR * 0.38, accentRingPaint);
    canvas.drawCircle(center, maxR * 0.68, ringPaint);
    canvas.drawCircle(center, maxR, ringPaint);

    canvas.drawLine(
      Offset(center.dx - maxR * 1.2, center.dy),
      Offset(center.dx + maxR * 1.2, center.dy),
      ringPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxR),
      Offset(center.dx, center.dy + maxR),
      ringPaint,
    );

    final nodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFF8833);

    final count = math.min(devicesCount, 8);
    for (int i = 0; i < count; i++) {
      final angle = (i * 1.15) - 0.6;
      final dist = maxR * (0.35 + ((i % 3) * 0.22));
      final pt = Offset(
        center.dx + dist * math.cos(angle),
        center.dy + dist * math.sin(angle),
      );
      canvas.drawCircle(pt, 3.5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarScopePainter oldDelegate) =>
      oldDelegate.devicesCount != devicesCount;
}
