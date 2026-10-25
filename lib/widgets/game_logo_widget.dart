import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Yanık İskambil için alevli iskambil kartları temalı yüksek kaliteli amblem ve logo bileşeni.
class GameLogoWidget extends StatelessWidget {
  final double size;

  const GameLogoWidget({
    super.key,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.20);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
            blurRadius: (size * 0.16).clamp(8.0, 24.0),
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.black87,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(
          'assets/images/app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => CustomPaint(
            size: Size(size, size),
            painter: _GameLogoPainter(),
          ),
        ),
      ),
    );
  }
}

class _GameLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // 1. Zengin koyu yeşil masa keçesi / asil madalyon zemini
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF143827), Color(0xFF091C14), Color(0xFF040E0A)],
        stops: [0.0, 0.70, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - 2, bgPaint);

    // 2. Dış İnce Altın Çember ve Boncuklu / Tırtıklı Prestij Kenarlığı
    final goldBorderPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.024).clamp(1.5, 3.0);
    canvas.drawCircle(center, radius - (w * 0.03), goldBorderPaint);

    final innerGoldRingPaint = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, radius - (w * 0.07), innerGoldRingPaint);

    // Çember etrafında minik altın noktalar (40 nokta)
    final dotPaint = Paint()..color = const Color(0xFFD4AF37);
    final dotRadius = (w * 0.012).clamp(1.0, 1.8);
    final dotDist = radius - (w * 0.05);
    for (int i = 0; i < 36; i++) {
      final angle = i * (2 * math.pi / 36);
      final dx = center.dx + dotDist * math.cos(angle);
      final dy = center.dy + dotDist * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), dotRadius, dotPaint);
    }

    // 3. Alt Kısımda Simetrik Altın Defne Yaprakları Çelengi (Laurel Wreath)
    final laurelPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final leafDist = radius * 0.75;
    for (int side = -1; side <= 1; side += 2) {
      for (int i = 1; i <= 5; i++) {
        final a = (math.pi / 2) + side * (i * 0.22);
        final lx = center.dx + leafDist * math.cos(a);
        final ly = center.dy + leafDist * math.sin(a);
        canvas.save();
        canvas.translate(lx, ly);
        canvas.rotate(a + (side == 1 ? math.pi / 4 : -math.pi / 4));
        final leafRect = Rect.fromCenter(
          center: Offset.zero,
          width: (w * 0.07).clamp(4.0, 7.5),
          height: (w * 0.03).clamp(2.0, 4.0),
        );
        canvas.drawOval(leafRect, laurelPaint);
        canvas.restore();
      }
    }

    // 4. Merkezde Asil Maça (Spades ♠) Vektörü
    final s = (w / 100.0) * 1.5;
    final spadeCenter = center.translate(0, -w * 0.03);

    canvas.save();
    canvas.translate(spadeCenter.dx, spadeCenter.dy);

    final spadePath = Path()
      ..moveTo(0, -14 * s)
      ..cubicTo(-5 * s, -7 * s, -13 * s, -1 * s, -13 * s, 6 * s)
      ..cubicTo(-13 * s, 11 * s, -8 * s, 14 * s, -1.5 * s, 10 * s)
      ..cubicTo(-2.5 * s, 14 * s, -5 * s, 15 * s, -8 * s, 15.5 * s)
      ..lineTo(8 * s, 15.5 * s)
      ..cubicTo(5 * s, 15 * s, 2.5 * s, 14 * s, 1.5 * s, 10 * s)
      ..cubicTo(8 * s, 14 * s, 13 * s, 11 * s, 13 * s, 6 * s)
      ..cubicTo(13 * s, -1 * s, 5 * s, -7 * s, 0, -14 * s);

    // Koyu asil maça dolgusu
    final spadePaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawPath(spadePath, spadePaint);

    // İnce altın kontur
    final spadeBorder = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(spadePath, spadeBorder);

    // İç süsleme çizgileri
    final innerSpade = Path()
      ..moveTo(0, -9 * s)
      ..cubicTo(-3.5 * s, -4 * s, -8 * s, 0, -8 * s, 4.5 * s)
      ..cubicTo(-8 * s, 8 * s, -5 * s, 9.5 * s, 0, 7 * s)
      ..cubicTo(5 * s, 9.5 * s, 8 * s, 8 * s, 8 * s, 4.5 * s)
      ..cubicTo(8 * s, 0, 3.5 * s, -4 * s, 0, -9 * s);
    final innerBorder = Paint()
      ..color = const Color(0xFFFDE047).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(innerSpade, innerBorder);

    canvas.restore();

    // 5. Yanlarda Minyatür Kupa ve Karo Sembolleri
    final miniIconY = center.dy - w * 0.02;
    _drawMiniHeart(canvas, Offset(center.dx - radius * 0.58, miniIconY), (w * 0.07).clamp(5.0, 8.0));
    _drawMiniDiamond(canvas, Offset(center.dx + radius * 0.58, miniIconY), (w * 0.07).clamp(5.0, 8.0));
  }

  void _drawMiniHeart(Canvas canvas, Offset c, double size) {
    final s = size / 16.0;
    final path = Path()
      ..moveTo(c.dx, c.dy + 5 * s)
      ..cubicTo(c.dx - 4 * s, c.dy + 1 * s, c.dx - 7 * s, c.dy - 3 * s, c.dx - 7 * s, c.dy - 6 * s)
      ..cubicTo(c.dx - 7 * s, c.dy - 9 * s, c.dx - 3 * s, c.dy - 10 * s, c.dx, c.dy - 6 * s)
      ..cubicTo(c.dx + 3 * s, c.dy - 10 * s, c.dx + 7 * s, c.dy - 9 * s, c.dx + 7 * s, c.dy - 6 * s)
      ..cubicTo(c.dx + 7 * s, c.dy - 3 * s, c.dx + 4 * s, c.dy + 1 * s, c.dx, c.dy + 5 * s);
    canvas.drawPath(path, Paint()..color = const Color(0xFFC41E3A));
  }

  void _drawMiniDiamond(Canvas canvas, Offset c, double size) {
    final s = size / 16.0;
    final path = Path()
      ..moveTo(c.dx, c.dy - 7 * s)
      ..lineTo(c.dx + 5.5 * s, c.dy)
      ..lineTo(c.dx, c.dy + 7 * s)
      ..lineTo(c.dx - 5.5 * s, c.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFC41E3A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
