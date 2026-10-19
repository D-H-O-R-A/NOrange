import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// ============================================================================
/// HIDE PROTOCOL — ORIGINAL BRAND EMBLEM & VECTOR ILLUSTRATIONS
/// ============================================================================
/// Concept: A precision-cut hexagonal stealth shield housing an encrypted
/// optical tunnel core and concentric radio-wave arcs in Black, Graphite,
/// and Solar Orange (#FF6B00).

class HideProtocolLogo extends StatelessWidget {
  final double size;
  final bool showContainer;

  const HideProtocolLogo({
    super.key,
    this.size = 40,
    this.showContainer = true,
  });

  @override
  Widget build(BuildContext context) {
    final emblem = CustomPaint(
      size: Size.square(showContainer ? size * 0.66 : size),
      painter: _HideProtocolEmblemPainter(),
    );

    if (!showContainer) return emblem;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0B0E),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: HpColors.accentOrange.withOpacity(0.42),
          width: 1.2,
        ),
      ),
      child: emblem,
    );
  }
}

class _HideProtocolEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    // 1. Outer Stealth Shield Polygon (Angular Hexagonal Crest)
    final shieldPath = Path()
      ..moveTo(cx, h * 0.04)
      ..lineTo(w * 0.90, h * 0.24)
      ..lineTo(w * 0.90, h * 0.62)
      ..lineTo(cx, h * 0.96)
      ..lineTo(w * 0.10, h * 0.62)
      ..lineTo(w * 0.10, h * 0.24)
      ..close();

    final shieldFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1A1C23),
          Color(0xFF0C0D11),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(shieldPath, shieldFill);

    final shieldStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.065
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFF7A1A),
          Color(0xFFFF5500),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(shieldPath, shieldStroke);

    // 2. Inner Stealth Slit / Encrypted Tunnel Portal
    final innerRadius = w * 0.23;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFF8FAFC);

    // Left & Right precision radar/tunnel arcs
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy * 0.96), radius: innerRadius),
      math.pi * 0.72,
      math.pi * 0.56,
      false,
      arcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy * 0.96), radius: innerRadius),
      -math.pi * 0.28,
      math.pi * 0.56,
      false,
      arcPaint,
    );

    // 3. Central Solar Orange Core & Vertical Keyhole Pillar
    final corePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFF6B00);

    canvas.drawCircle(Offset(cx, cy * 0.88), w * 0.095, corePaint);

    final pillarPath = Path()
      ..moveTo(cx - w * 0.045, cy * 0.96)
      ..lineTo(cx + w * 0.045, cy * 0.96)
      ..lineTo(cx + w * 0.07, h * 0.73)
      ..lineTo(cx - w * 0.07, h * 0.73)
      ..close();
    canvas.drawPath(pillarPath, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Contextual vector radar illustration for the Wi-Fi Wave Proximity Radar
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

    // Crosshair lines
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

    // Plot detected signal nodes around the radar rings
    final nodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFF6B00);

    final count = devicesCount > 8 ? 8 : devicesCount;
    for (int i = 0; i < count; i++) {
      final angle = (i * 1.35) + 0.4;
      final radius = maxR * (0.35 + ((i % 3) * 0.25));
      final pt = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawCircle(pt, 4.0, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarScopePainter oldDelegate) =>
      oldDelegate.devicesCount != devicesCount;
}
