import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// An authentic Malaysian cultural heritage emblem representing the
/// traditional 8-petal Bunga Tanjung motif seen in Songket weaving,
/// Batik woodblock printing, and traditional woodcarving (Ukiran Kayu).
class HeritageLogo extends StatelessWidget {
  final double size;
  final bool showBadge;
  final Color? badgeColor;
  final Color? primaryColor;
  final Color? accentColor;
  final bool glow;

  const HeritageLogo({
    super.key,
    this.size = 64,
    this.showBadge = true,
    this.badgeColor,
    this.primaryColor,
    this.accentColor,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBadgeColor = badgeColor ?? Colors.white;
    final effectivePrimary = primaryColor ?? const Color(0xFF004D40); // Malaysian Emerald
    final effectiveAccent = accentColor ?? const Color(0xFFFFD54F);   // Heritage Gold

    Widget emblem = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BungaTanjungPainter(
          primaryColor: effectivePrimary,
          goldColor: effectiveAccent,
        ),
      ),
    );

    if (!showBadge) {
      return emblem;
    }

    final padding = size * 0.28;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: effectiveBadgeColor,
        shape: BoxShape.circle,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: effectiveAccent.withValues(alpha: 0.35),
                  blurRadius: size * 0.35,
                  spreadRadius: size * 0.08,
                ),
                BoxShadow(
                  color: effectivePrimary.withValues(alpha: 0.15),
                  blurRadius: size * 0.2,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: emblem,
    );
  }
}

/// Custom painter for the 8-petal Bunga Tanjung / Songket star motif.
class _BungaTanjungPainter extends CustomPainter {
  final Color primaryColor;
  final Color goldColor;

  _BungaTanjungPainter({
    required this.primaryColor,
    required this.goldColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Paint definitions
    final goldFill = Paint()
      ..color = goldColor
      ..style = PaintingStyle.fill;

    final primaryFill = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final goldStroke = Paint()
      ..color = goldColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, radius * 0.06)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fineStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, radius * 0.04)
      ..strokeCap = StrokeCap.round;

    // 1. Draw 8 outer heritage petals (4 cardinal + 4 diagonal)
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final isMajor = i % 2 == 0;
      final petalLen = isMajor ? radius * 0.96 : radius * 0.82;
      final petalWidth = isMajor ? radius * 0.36 : radius * 0.28;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final petalPath = Path();
      petalPath.moveTo(0, 0);
      petalPath.quadraticBezierTo(
        petalWidth,
        -petalLen * 0.45,
        0,
        -petalLen,
      );
      petalPath.quadraticBezierTo(
        -petalWidth,
        -petalLen * 0.45,
        0,
        0,
      );
      petalPath.close();

      // Alternate petal colors: Emerald base with gold accent
      canvas.drawPath(petalPath, isMajor ? primaryFill : goldFill);
      canvas.drawPath(petalPath, isMajor ? goldStroke : fineStroke);

      // Inner vein on major petals (benang emas filigree)
      if (isMajor) {
        final veinPath = Path()
          ..moveTo(0, -petalLen * 0.2)
          ..lineTo(0, -petalLen * 0.8);
        canvas.drawPath(veinPath, goldStroke);
      }

      canvas.restore();
    }

    // 2. Intersecting decorative inner ring (songket weave ring)
    final ringPaint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, radius * 0.07);
    canvas.drawCircle(center, radius * 0.42, ringPaint);

    final innerRingPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, radius * 0.04);
    canvas.drawCircle(center, radius * 0.32, innerRingPaint);

    // 3. Central Diamond Jewel (Intan Berlian) - Master Artisan symbol
    final diamondRadius = radius * 0.24;
    final diamondPath = Path()
      ..moveTo(center.dx, center.dy - diamondRadius)
      ..lineTo(center.dx + diamondRadius, center.dy)
      ..lineTo(center.dx, center.dy + diamondRadius)
      ..lineTo(center.dx - diamondRadius, center.dy)
      ..close();

    canvas.drawPath(diamondPath, goldFill);

    final diamondStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, radius * 0.05);
    canvas.drawPath(diamondPath, diamondStroke);

    // 4. Central Core Jewel Point
    canvas.drawCircle(center, radius * 0.09, primaryFill);
    canvas.drawCircle(center, radius * 0.04, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _BungaTanjungPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor || oldDelegate.goldColor != goldColor;
  }
}

/// A complete brand lockup with Heritage Logo and WarisanKita typography.
class HeritageBrandLockup extends StatelessWidget {
  final double logoSize;
  final Color titleColor;
  final Color subtitleColor;
  final bool isDark;

  const HeritageBrandLockup({
    super.key,
    this.logoSize = 56,
    this.titleColor = Colors.white,
    this.subtitleColor = const Color(0xFFFFD54F),
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HeritageLogo(
          size: logoSize,
          glow: true,
          badgeColor: isDark ? Colors.white : const Color(0xFF004D40),
          primaryColor: isDark ? const Color(0xFF004D40) : Colors.white,
          accentColor: const Color(0xFFFFD54F),
        ),
        const SizedBox(height: 18),
        Text(
          'WarisanKita',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: logoSize * 0.65,
            fontWeight: FontWeight.bold,
            color: titleColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 1.5,
              color: subtitleColor.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              'LIVING CULTURAL HERITAGE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.5,
                color: subtitleColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 16,
              height: 1.5,
              color: subtitleColor.withValues(alpha: 0.6),
            ),
          ],
        ),
      ],
    );
  }
}
