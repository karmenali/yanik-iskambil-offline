import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Zynga Poker & Batak HD seviyesinde GPU hızlandırmalı Profesyonel Vektörel İskambil Çizim Motoru
class VectorCardPainter extends CustomPainter {
  final int rank; // 1: A, 2..10, 11: J, 12: Q, 13: K, 0: Joker
  final String suit; // 'S': Maça, 'H': Kupa, 'D': Karo, 'C': Sinek, 'J': Joker
  final bool isPhysicalJoker;
  final bool showAsWild;
  final bool isSelected;
  final bool isWinningDiscardCandidate;

  VectorCardPainter({
    required this.rank,
    required this.suit,
    this.isPhysicalJoker = false,
    this.showAsWild = false,
    this.isSelected = false,
    this.isWinningDiscardCandidate = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. KART GÖVDESİ & CASINO FİLDİŞİ DOKUSU
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular((w * 0.12).clamp(4.5, 9.0)),
    );

    // Zengin derinlik gölgesi
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isSelected ? 0.35 : 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 6 : 2.5);
    canvas.drawRRect(rrect.shift(Offset(0, isSelected ? 4 : 1.5)), shadowPaint);

    // Kart Kağıdı Dolgusu (Casino ivory fildişi zemin)
    final cardBgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFFBFBFA), Color(0xFFF4F4F2)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(rrect, cardBgPaint);

    // Sahte Joker (Gösterge jokeri) yardımlı moddaysa hafif asil altın parıltı dokusu
    final bool isIndicatorWild = showAsWild && !isPhysicalJoker;
    if (isIndicatorWild) {
      final wildGlowPaint = Paint()
        ..color = const Color(0xFFF59E0B).withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, wildGlowPaint);
    }

    // Kart Kenar Çizgisi (Border)
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isSelected || isIndicatorWild) ? 1.8 : 1.0
      ..color = isSelected
          ? const Color(0xFFF59E0B)
          : (isIndicatorWild
              ? const Color(0xFFF59E0B)
              : const Color(0xFFD1D5DB).withValues(alpha: 0.85));
    canvas.drawRRect(rrect, borderPaint);

    // İç ince asil çerçeve çizgisi
    final innerRRect = rrect.deflate((w * 0.04).clamp(1.5, 2.8));
    final innerBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = isIndicatorWild
          ? const Color(0xFFD4AF37).withValues(alpha: 0.5)
          : const Color(0xFF94A3B8).withValues(alpha: 0.25);
    canvas.drawRRect(innerRRect, innerBorderPaint);

    // 2. RENKLER
    final bool isRed = suit == 'H' || suit == 'D';
    final Color suitColor = isPhysicalJoker
        ? const Color(0xFF7C3AED)
        : (isRed ? const Color(0xFFC41E3A) : const Color(0xFF18181B));

    if (isPhysicalJoker) {
      _paintJoker(canvas, w, h);
      return;
    }

    // 3. KÖŞE İNDEKSLERİ (SOL ÜST & SAĞ ALT - TERS SİMETRİK)
    _paintCorner(canvas, w, h, suitColor, isTop: true);
    if (h >= 50) {
      _paintCorner(canvas, w, h, suitColor, isTop: false);
    }

    // 4. MERKEZ DESENİ (AS, RESİMLİ KARTLAR VEYA PİPLER)
    _paintCenterArt(canvas, w, h, suitColor);
  }

  void _paintCorner(Canvas canvas, double w, double h, Color color, {required bool isTop}) {
    canvas.save();
    if (!isTop) {
      canvas.translate(w, h);
      canvas.rotate(math.pi);
    }

    final double padX = (w * 0.075).clamp(2.8, 5.5);
    final double padY = (h * 0.045).clamp(2.2, 4.5);

    // Sayı / Harf
    final label = _getRankLabel();
    final double fontSize = (w * 0.23).clamp(9.5, 15.0);
    final textSpan = TextSpan(
      text: label,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: rank == 10 ? -1.2 : -0.3,
        height: 1.0,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(padX, padY));

    // Köşedeki küçük sembol
    final double suitY = padY + tp.height + 1.0;
    final double cornerSuitSize = (w * 0.15).clamp(6.0, 9.5);
    _drawSuitVector(
      canvas,
      suit,
      Offset(padX + tp.width / 2, suitY + cornerSuitSize / 2),
      cornerSuitSize,
      color,
    );

    canvas.restore();
  }

  void _paintCenterArt(Canvas canvas, double w, double h, Color color) {
    final center = Offset(w / 2, h / 2);

    // AS (A) - Lüks Casino Amblemi
    if (rank == 1) {
      if (suit == 'S') {
        _drawOrnateAceOfSpades(canvas, center, w, h, color);
      } else {
        final double aceSize = (w * 0.44).clamp(18.0, 36.0);
        _drawSuitVector(canvas, suit, center, aceSize, color);
      }
      return;
    }

    // RESİMLİ KARTLAR (J, Q, K) - Çift Başlı Otantik Kraliyet Portresi
    if (rank >= 11 && rank <= 13) {
      _drawRoyalCourtFigure(canvas, w, h, center, color);
      return;
    }

    // 2..10 SAYI KARTLARI (Kusursuz Oransal Pip Matrisi)
    _drawPipMatrix(canvas, w, h, color);
  }

  /// Maça Ası için klasik Bicycle tarzı süslemeli gravür amblemi
  void _drawOrnateAceOfSpades(Canvas canvas, Offset center, double w, double h, Color color) {
    final double aceSize = (w * 0.46).clamp(20.0, 38.0);
    // Ana büyük maça
    _drawSuitVector(canvas, 'S', center, aceSize, color);

    // İç kontur ve filigran çizgileri (lüks detay)
    final double innerSize = aceSize * 0.55;
    _drawSuitVector(canvas, 'S', center.translate(0, -aceSize * 0.04), innerSize, Colors.white.withValues(alpha: 0.85));
    _drawSuitVector(canvas, 'S', center.translate(0, -aceSize * 0.04), innerSize * 0.70, color);

    // Altında ve yanlarında minik altın rosetler
    final double s = aceSize / 24.0;
    final accentPaint = Paint()..color = const Color(0xFFD4AF37);
    canvas.drawCircle(Offset(center.dx - 9 * s, center.dy + 8 * s), 1.2 * s, accentPaint);
    canvas.drawCircle(Offset(center.dx + 9 * s, center.dy + 8 * s), 1.2 * s, accentPaint);
  }

  /// Resimli Kartlar (J, Q, K) - İki Başlı (180° Simetrik) Otantik Casino Kraliyet Çizimi
  void _drawRoyalCourtFigure(Canvas canvas, double w, double h, Offset center, Color color) {
    // Portre çerçeve sınırları (köşe indekslerini asla örtmez!)
    final double mw = (w * 0.54).clamp(21.0, 48.0);
    final double mh = (h * 0.62).clamp(32.0, 72.0);

    final rect = Rect.fromCenter(center: center, width: mw, height: mh);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3.5));

    // 1. Minyatür Portre Çerçevesi ve Zemin Dokusu
    final bgPaint = Paint()..color = const Color(0xFFFAF7EE);
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

    // İç süs çizgisi
    final innerRRect = RRect.fromRectAndRadius(
      rect.deflate(1.6),
      const Radius.circular(2.0),
    );
    final innerBorderPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawRRect(innerRRect, innerBorderPaint);

    // Ortadan geçen yatay zarif bölücü kraliyet kuşağı (Sash)
    final double halfH = mh / 2;
    final dividerPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawLine(
      Offset(rect.left + 2, center.dy),
      Offset(rect.right - 2, center.dy),
      dividerPaint,
    );

    // Kuşak ortasındaki altın kraliyet arması
    final diamondPath = Path()
      ..moveTo(center.dx, center.dy - 2.8)
      ..lineTo(center.dx + 4.2, center.dy)
      ..lineTo(center.dx, center.dy + 2.8)
      ..lineTo(center.dx - 4.2, center.dy)
      ..close();
    canvas.drawPath(diamondPath, Paint()..color = const Color(0xFFD4AF37));
    canvas.drawCircle(center, 1.2, Paint()..color = (color == const Color(0xFFC41E3A) ? const Color(0xFFC41E3A) : const Color(0xFF1E3A8A)));

    // 2. ÇİFT BAŞLI PORTRE ÇİZİMİ (ÜST DÜZ & ALT 180° TERS SİMETRİK)
    _drawHalfCourtFigure(canvas, mw, halfH, center, color, isTop: true);
    _drawHalfCourtFigure(canvas, mw, halfH, center, color, isTop: false);
  }

  void _drawHalfCourtFigure(
    Canvas canvas,
    double mw,
    double halfH,
    Offset center,
    Color color, {
    required bool isTop,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (!isTop) {
      canvas.rotate(math.pi);
    }

    final double s = (mw / 36.0).clamp(0.60, 1.30);

    // 1. OMUZLAR & KRALİYET BORNOZU / ELBİSESİ (Robe & Mantle)
    final robePath = Path();
    robePath.moveTo(-mw * 0.44, 0);
    robePath.lineTo(-mw * 0.40, -halfH * 0.42);
    robePath.cubicTo(
      -mw * 0.28, -halfH * 0.62,
      -mw * 0.12, -halfH * 0.58,
      -mw * 0.08, -halfH * 0.50,
    );
    robePath.lineTo(0, -halfH * 0.32);
    robePath.lineTo(mw * 0.08, -halfH * 0.50);
    robePath.cubicTo(
      mw * 0.12, -halfH * 0.58,
      mw * 0.28, -halfH * 0.62,
      mw * 0.40, -halfH * 0.42,
    );
    robePath.lineTo(mw * 0.44, 0);
    robePath.close();

    // Elbise dolgu rengi: Kraliyet Laciverti ve Bordo uyumu
    final Color primaryRobeColor = (rank == 12)
        ? const Color(0xFF831843) // Queen: Zengin Fuşya/Bordo
        : (rank == 13 ? const Color(0xFF1E3A8A) : const Color(0xFF0F766E)); // King: Lacivert, Jack: Zümrüt Mavisi
    canvas.drawPath(robePath, Paint()..color = primaryRobeColor.withValues(alpha: 0.18));
    canvas.drawPath(
      robePath,
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // 2. ERMİNE YAKA VE BROKAR ÇİZGİLERİ
    final collarPath = Path()
      ..moveTo(-mw * 0.22, -halfH * 0.48)
      ..lineTo(0, -halfH * 0.28)
      ..lineTo(mw * 0.22, -halfH * 0.48);
    canvas.drawPath(
      collarPath,
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // 3. YÜZ & BAŞ (Head & Face)
    final headY = -halfH * 0.64;
    final headR = 6.2 * s;
    final facePaint = Paint()..color = const Color(0xFFFFF7ED); // Fildişi ten rengi
    canvas.drawCircle(Offset(0, headY), headR, facePaint);
    canvas.drawCircle(
      Offset(0, headY),
      headR,
      Paint()
        ..color = color.withValues(alpha: 0.60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );

    // Bukleler / Saçlar
    final hairColor = (rank == 12)
        ? const Color(0xFFB45309) // Kraliçe altın/kızıl bukleler
        : (rank == 13 ? const Color(0xFF475569) : const Color(0xFF78350F)); // Kral gümüşi/koyu, Vale kahve
    final hairPaint = Paint()..color = hairColor;
    canvas.drawCircle(Offset(-headR * 0.85, headY + 1 * s), 2.7 * s, hairPaint);
    canvas.drawCircle(Offset(headR * 0.85, headY + 1 * s), 2.7 * s, hairPaint);

    // Gözler ve Kaşlar
    final eyePaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(Offset(-1.9 * s, headY - 0.7 * s), 0.75 * s, eyePaint);
    canvas.drawCircle(Offset(1.9 * s, headY - 0.7 * s), 0.75 * s, eyePaint);

    // 4. FİGÜRE ÖZGÜ ÖZELLİKLER (J, Q, K)
    if (rank == 13) {
      // PAPAZ / KRAL (KING - K)
      // Kraliyet Sakalı ve Bıyığı
      final beardPath = Path();
      beardPath.moveTo(-3.2 * s, headY + 2.0 * s);
      beardPath.cubicTo(-2.0 * s, headY + 5.6 * s, 2.0 * s, headY + 5.6 * s, 3.2 * s, headY + 2.0 * s);
      beardPath.lineTo(0, headY + 6.8 * s);
      beardPath.close();
      canvas.drawPath(beardPath, Paint()..color = hairColor);

      // 5 Tepeli Altın Taç (Crown)
      final crownY = headY - headR;
      final crownPath = Path()
        ..moveTo(-headR * 0.95, crownY + 1.5 * s)
        ..lineTo(-headR * 0.80, crownY - 5.8 * s)
        ..lineTo(-headR * 0.38, crownY - 1.8 * s)
        ..lineTo(0, crownY - 7.6 * s)
        ..lineTo(headR * 0.38, crownY - 1.8 * s)
        ..lineTo(headR * 0.80, crownY - 5.8 * s)
        ..lineTo(headR * 0.95, crownY + 1.5 * s)
        ..close();
      canvas.drawPath(crownPath, Paint()..color = const Color(0xFFF59E0B));
      canvas.drawPath(
        crownPath,
        Paint()
          ..color = const Color(0xFFB45309)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      // Taç ortasındaki yakut mücevher
      canvas.drawCircle(Offset(0, crownY - 3.8 * s), 1.2 * s, Paint()..color = const Color(0xFFDC2626));
      canvas.drawCircle(Offset(-headR * 0.55, crownY - 2.5 * s), 0.8 * s, Paint()..color = const Color(0xFF2563EB));
      canvas.drawCircle(Offset(headR * 0.55, crownY - 2.5 * s), 0.8 * s, Paint()..color = const Color(0xFF2563EB));

      // Sağ elde Kraliyet Kılıcı (Sword)
      final swordX = mw * 0.30;
      final swordPath = Path()
        ..moveTo(swordX, -halfH * 0.85)
        ..lineTo(swordX + 1.2 * s, -halfH * 0.15)
        ..lineTo(swordX - 1.2 * s, -halfH * 0.15)
        ..close();
      canvas.drawPath(swordPath, Paint()..color = const Color(0xFFCBD5E1));
      canvas.drawRect(
        Rect.fromCenter(center: Offset(swordX, -halfH * 0.15), width: 6.5 * s, height: 1.6 * s),
        Paint()..color = const Color(0xFFD4AF37),
      );
      canvas.drawCircle(Offset(swordX, -halfH * 0.08), 1.2 * s, Paint()..color = const Color(0xFFD4AF37));

    } else if (rank == 12) {
      // KIZ / KRALİÇE (QUEEN - Q)
      // Zarif Dudak
      canvas.drawArc(
        Rect.fromCenter(center: Offset(0, headY + 2.2 * s), width: 3.2 * s, height: 2.0 * s),
        0.2,
        math.pi - 0.4,
        false,
        Paint()
          ..color = const Color(0xFFDC2626)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );

      // İncili Kraliçe Tacı (Tiara)
      final crownY = headY - headR;
      final tiaraPath = Path()
        ..moveTo(-headR * 0.90, crownY + 1.5 * s)
        ..cubicTo(-headR * 0.5, crownY - 5.0 * s, headR * 0.5, crownY - 5.0 * s, headR * 0.90, crownY + 1.5 * s)
        ..lineTo(headR * 0.60, crownY - 0.5 * s)
        ..lineTo(0, crownY - 6.2 * s)
        ..lineTo(-headR * 0.60, crownY - 0.5 * s)
        ..close();
      canvas.drawPath(tiaraPath, Paint()..color = const Color(0xFFF59E0B));
      canvas.drawPath(
        tiaraPath,
        Paint()
          ..color = const Color(0xFFB45309)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7,
      );
      // İnciler
      for (double px in [-4.0 * s, 0, 4.0 * s]) {
        canvas.drawCircle(Offset(px, crownY - 2.8 * s), 0.95 * s, Paint()..color = Colors.white);
      }

      // Sağ elde Kraliyet Çiçeği / Asası (Scepter / Flower)
      final flowerX = mw * 0.28;
      final flowerY = -halfH * 0.48;
      canvas.drawLine(
        Offset(flowerX, flowerY + 6.5 * s),
        Offset(flowerX, 0),
        Paint()
          ..color = const Color(0xFFD4AF37)
          ..strokeWidth = 1.0,
      );
      canvas.drawCircle(Offset(flowerX, flowerY), 2.8 * s, Paint()..color = const Color(0xFFE11D48));
      canvas.drawCircle(Offset(flowerX, flowerY), 1.1 * s, Paint()..color = const Color(0xFFFEF08A));

    } else {
      // VALE / ŞÖVALYE (JACK - J)
      // Dinamik Genç Yüz ve Çene
      canvas.drawArc(
        Rect.fromCenter(center: Offset(0, headY + 2.0 * s), width: 3.8 * s, height: 1.6 * s),
        0.1,
        math.pi - 0.2,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );

      // Şövalye Tüylü Başlığı / Beresi (Feathered Cap)
      final capY = headY - headR * 0.6;
      final capPath = Path()
        ..moveTo(-headR * 1.10, capY + 1.0 * s)
        ..cubicTo(-headR * 0.8, capY - 6.5 * s, headR * 0.5, capY - 7.5 * s, headR * 1.05, capY - 1.5 * s)
        ..lineTo(headR * 0.75, capY + 1.5 * s)
        ..close();
      canvas.drawPath(capPath, Paint()..color = const Color(0xFF1E3A8A));
      canvas.drawPath(
        capPath,
        Paint()
          ..color = const Color(0xFF1D4ED8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      // Geriye süzülen altın tüy
      final featherPath = Path()
        ..moveTo(-headR * 0.70, capY - 3.0 * s)
        ..cubicTo(-headR * 1.35, capY - 8.5 * s, -headR * 0.90, capY - 11.5 * s, -headR * 0.25, capY - 7.5 * s);
      canvas.drawPath(
        featherPath,
        Paint()
          ..color = const Color(0xFFF59E0B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );

      // Sağ elde Mızrak / Kargı (Spear / Halberd)
      final spearX = mw * 0.30;
      canvas.drawLine(
        Offset(spearX, -halfH * 0.82),
        Offset(spearX, 0),
        Paint()
          ..color = const Color(0xFF94A3B8)
          ..strokeWidth = 1.1,
      );
      final spearHead = Path()
        ..moveTo(spearX, -halfH * 0.88)
        ..lineTo(spearX + 3.2 * s, -halfH * 0.72)
        ..lineTo(spearX, -halfH * 0.76)
        ..lineTo(spearX - 3.2 * s, -halfH * 0.72)
        ..close();
      canvas.drawPath(spearHead, Paint()..color = const Color(0xFF64748B));
    }

    // Omuz hizasında minik Takım Sembolü (Suit Insignia)
    final miniSuitX = -mw * 0.28;
    final miniSuitY = -halfH * 0.72;
    _drawSuitVector(canvas, suit, Offset(miniSuitX, miniSuitY), 5.5 * s, color);

    canvas.restore();
  }

  /// Kusursuz Pip Matrisi (2..10 Sayı Kartları)
  void _drawPipMatrix(Canvas canvas, double w, double h, Color color) {
    final double pipSize = (w * 0.19).clamp(7.5, 13.0);

    // Güvenli iç çizim alanı (köşe indekslerine asla değmez!)
    final double leftCol = w * 0.33;
    final double midCol = w * 0.50;
    final double rightCol = w * 0.67;

    final double topRow = h * 0.25;
    final double upperMidRow = h * 0.38;
    final double centerRow = h * 0.50;
    final double lowerMidRow = h * 0.62;
    final double bottomRow = h * 0.75;

    void draw(double x, double y, {bool inverted = false}) {
      _drawSuitVector(canvas, suit, Offset(x, y), pipSize, color, inverted: inverted);
    }

    switch (rank) {
      case 2:
        draw(midCol, topRow);
        draw(midCol, bottomRow, inverted: true);
        break;
      case 3:
        draw(midCol, topRow);
        draw(midCol, centerRow);
        draw(midCol, bottomRow, inverted: true);
        break;
      case 4:
        draw(leftCol, topRow);
        draw(rightCol, topRow);
        draw(leftCol, bottomRow, inverted: true);
        draw(rightCol, bottomRow, inverted: true);
        break;
      case 5:
        draw(leftCol, topRow);
        draw(rightCol, topRow);
        draw(midCol, centerRow);
        draw(leftCol, bottomRow, inverted: true);
        draw(rightCol, bottomRow, inverted: true);
        break;
      case 6:
        draw(leftCol, topRow);
        draw(rightCol, topRow);
        draw(leftCol, centerRow);
        draw(rightCol, centerRow);
        draw(leftCol, bottomRow, inverted: true);
        draw(rightCol, bottomRow, inverted: true);
        break;
      case 7:
        draw(leftCol, topRow);
        draw(rightCol, topRow);
        draw(midCol, upperMidRow);
        draw(leftCol, centerRow);
        draw(rightCol, centerRow);
        draw(leftCol, bottomRow, inverted: true);
        draw(rightCol, bottomRow, inverted: true);
        break;
      case 8:
        draw(leftCol, topRow);
        draw(rightCol, topRow);
        draw(midCol, upperMidRow);
        draw(leftCol, centerRow);
        draw(rightCol, centerRow);
        draw(midCol, lowerMidRow, inverted: true);
        draw(leftCol, bottomRow, inverted: true);
        draw(rightCol, bottomRow, inverted: true);
        break;
      case 9:
        draw(leftCol, topRow);
        draw(rightCol, topRow);
        draw(leftCol, upperMidRow);
        draw(rightCol, upperMidRow);
        draw(midCol, centerRow);
        draw(leftCol, lowerMidRow, inverted: true);
        draw(rightCol, lowerMidRow, inverted: true);
        draw(leftCol, bottomRow, inverted: true);
        draw(rightCol, bottomRow, inverted: true);
        break;
      case 10:
        draw(leftCol, topRow);
        draw(rightCol, topRow);
        draw(midCol, h * 0.32);
        draw(leftCol, upperMidRow);
        draw(rightCol, upperMidRow);
        draw(leftCol, lowerMidRow, inverted: true);
        draw(rightCol, lowerMidRow, inverted: true);
        draw(midCol, h * 0.68, inverted: true);
        draw(leftCol, bottomRow, inverted: true);
        draw(rightCol, bottomRow, inverted: true);
        break;
      default:
        draw(midCol, centerRow);
    }
  }

  /// Orijinal Joker (Fiziksel Joker) - 3 Uçlu Çıngıraklı Soytarı Şapkası & Maskeli Yüz
  void _paintJoker(Canvas canvas, double w, double h) {
    final center = Offset(w / 2, h / 2);
    final s = (w / 44.0).clamp(0.60, 1.30);

    // 1. Köşe İndeksleri: Çift Taraflı "J O K E R" ve Yıldız
    _paintJokerCorner(canvas, w, h, isTop: true);
    if (h >= 50) {
      _paintJokerCorner(canvas, w, h, isTop: false);
    }

    // 2. Merkez Paneli (Altın İnce Çerçeve ve Zemin)
    final mw = (w * 0.58).clamp(24.0, 50.0);
    final mh = (h * 0.66).clamp(34.0, 76.0);
    final rect = Rect.fromCenter(center: center, width: mw, height: mh);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(5.0));

    final bgPaint = Paint()..color = const Color(0xFFFAF5FF); // Asil hafif lavanta zemin
    canvas.drawRRect(rrect, bgPaint);
    final borderPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

    // 3. JESTİ / SOYTARI ÇİZİMİ
    final faceY = center.dy + 1 * s;
    final faceR = 6.0 * s;

    // A. 3 Uçlu Çıngıraklı Soytarı Şapkası (Jester Tricorne Cap)
    final capBaseY = faceY - faceR * 0.5;

    // Sol Boynuz (Left Horn)
    final leftHorn = Path()
      ..moveTo(center.dx - faceR * 0.8, capBaseY)
      ..cubicTo(
        center.dx - faceR * 1.8, capBaseY - 6 * s,
        center.dx - faceR * 2.2, capBaseY - 14 * s,
        center.dx - faceR * 1.4, capBaseY - 17 * s,
      )
      ..cubicTo(
        center.dx - faceR * 0.9, capBaseY - 15 * s,
        center.dx - faceR * 0.4, capBaseY - 8 * s,
        center.dx, capBaseY - 6 * s,
      )
      ..close();
    canvas.drawPath(leftHorn, Paint()..color = const Color(0xFF7C3AED)); // Mor

    // Orta Boynuz (Center Horn)
    final centerHorn = Path()
      ..moveTo(center.dx - faceR * 0.5, capBaseY - 4 * s)
      ..cubicTo(
        center.dx - faceR * 0.3, capBaseY - 16 * s,
        center.dx + faceR * 0.3, capBaseY - 16 * s,
        center.dx + faceR * 0.5, capBaseY - 4 * s,
      )
      ..close();
    canvas.drawPath(centerHorn, Paint()..color = const Color(0xFFF59E0B)); // Altın

    // Sağ Boynuz (Right Horn)
    final rightHorn = Path()
      ..moveTo(center.dx + faceR * 0.8, capBaseY)
      ..cubicTo(
        center.dx + faceR * 1.8, capBaseY - 6 * s,
        center.dx + faceR * 2.2, capBaseY - 14 * s,
        center.dx + faceR * 1.4, capBaseY - 17 * s,
      )
      ..cubicTo(
        center.dx + faceR * 0.9, capBaseY - 15 * s,
        center.dx + faceR * 0.4, capBaseY - 8 * s,
        center.dx, capBaseY - 6 * s,
      )
      ..close();
    canvas.drawPath(rightHorn, Paint()..color = const Color(0xFFDC2626)); // Kırmızı

    // Şapka Uçlarındaki Altın Çıngıraklar / Ziller (Bells)
    final bellPaint = Paint()..color = const Color(0xFFFDE047);
    final bellBorder = Paint()
      ..color = const Color(0xFFB45309)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    final bell1 = Offset(center.dx - faceR * 1.4, capBaseY - 17 * s);
    final bell2 = Offset(center.dx, capBaseY - 16 * s);
    final bell3 = Offset(center.dx + faceR * 1.4, capBaseY - 17 * s);

    for (final b in [bell1, bell2, bell3]) {
      canvas.drawCircle(b, 1.8 * s, bellPaint);
      canvas.drawCircle(b, 1.8 * s, bellBorder);
    }

    // Şapka Kafa Bandı (Headband)
    final bandRect = Rect.fromCenter(center: Offset(center.dx, capBaseY), width: faceR * 2.2, height: 2.2 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(bandRect, const Radius.circular(1.0)), Paint()..color = const Color(0xFFD4AF37));

    // B. Yüz ve Soytarı Maskesi
    canvas.drawCircle(Offset(center.dx, faceY), faceR, Paint()..color = const Color(0xFFFFF7ED));
    canvas.drawCircle(
      Offset(center.dx, faceY),
      faceR,
      Paint()
        ..color = const Color(0xFF7C3AED).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );

    // Maskeli Gözler
    final maskPaint = Paint()..color = const Color(0xFF7C3AED);
    canvas.drawCircle(Offset(center.dx - 2.0 * s, faceY - 0.6 * s), 1.2 * s, maskPaint);
    canvas.drawCircle(Offset(center.dx + 2.0 * s, faceY - 0.6 * s), 1.2 * s, maskPaint);
    canvas.drawCircle(Offset(center.dx - 2.0 * s, faceY - 0.6 * s), 0.5 * s, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(center.dx + 2.0 * s, faceY - 0.6 * s), 0.5 * s, Paint()..color = Colors.white);

    // Güler Yüz (Smile)
    final smilePath = Path()
      ..moveTo(center.dx - 2.4 * s, faceY + 2.0 * s)
      ..quadraticBezierTo(center.dx, faceY + 4.2 * s, center.dx + 2.4 * s, faceY + 2.0 * s);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = const Color(0xFFDC2626)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // C. Fırfırlı Kraliyet Yakalığı (Accordion Ruff Collar)
    final collarY = faceY + faceR * 0.9;
    final ruffPath = Path();
    ruffPath.moveTo(center.dx - faceR * 1.4, collarY);
    for (int i = 0; i < 5; i++) {
      final double x1 = center.dx - faceR * 1.4 + (i * 2 + 1) * (faceR * 1.4 / 5);
      final double x2 = center.dx - faceR * 1.4 + (i * 2 + 2) * (faceR * 1.4 / 5);
      ruffPath.lineTo(x1, collarY + 3.8 * s);
      ruffPath.lineTo(x2, collarY);
    }
    ruffPath.close();
    canvas.drawPath(ruffPath, Paint()..color = const Color(0xFFF59E0B));
    canvas.drawPath(
      ruffPath,
      Paint()
        ..color = const Color(0xFFB45309)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  void _paintJokerCorner(Canvas canvas, double w, double h, {required bool isTop}) {
    canvas.save();
    if (!isTop) {
      canvas.translate(w, h);
      canvas.rotate(math.pi);
    }

    final double padX = (w * 0.075).clamp(2.5, 4.5);
    final double padY = (h * 0.045).clamp(2.0, 4.0);
    final double fontSize = (w * 0.16).clamp(7.0, 10.0);

    // Yıldız
    final starSpan = TextSpan(
      text: '★',
      style: TextStyle(
        color: const Color(0xFFF59E0B),
        fontSize: fontSize + 1,
        fontWeight: FontWeight.bold,
      ),
    );
    final stp = TextPainter(text: starSpan, textDirection: TextDirection.ltr);
    stp.layout();
    stp.paint(canvas, Offset(padX, padY));

    // Dikey J O K E R yazısı
    const letters = ['J', 'O', 'K', 'E', 'R'];
    double curY = padY + stp.height + 0.5;
    for (final char in letters) {
      final textSpan = TextSpan(
        text: char,
        style: TextStyle(
          color: const Color(0xFF7C3AED),
          fontSize: fontSize * 0.85,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(padX + (stp.width - tp.width) / 2, curY));
      curY += tp.height * 0.85;
    }

    canvas.restore();
  }


  /// Gerçek Vektörel İskambil Sembolü Çizimi (Maça, Kupa, Karo, Sinek)
  void _drawSuitVector(
    Canvas canvas,
    String suitKey,
    Offset center,
    double size,
    Color color, {
    bool inverted = false,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (inverted) canvas.rotate(math.pi);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final s = size / 24.0; // 24x24 normalize standart vektör grid'i
    final path = Path();

    switch (suitKey) {
      case 'S': // MAÇA (Spades ♠)
        path.moveTo(0, -11 * s);
        path.cubicTo(-4 * s, -6 * s, -10 * s, -1 * s, -10 * s, 4 * s);
        path.cubicTo(-10 * s, 8 * s, -6 * s, 10 * s, -1 * s, 7 * s);
        path.cubicTo(-2 * s, 10 * s, -4 * s, 11 * s, -6 * s, 11 * s);
        path.lineTo(6 * s, 11 * s);
        path.cubicTo(4 * s, 11 * s, 2 * s, 10 * s, 1 * s, 7 * s);
        path.cubicTo(6 * s, 10 * s, 10 * s, 8 * s, 10 * s, 4 * s);
        path.cubicTo(10 * s, -1 * s, 4 * s, -6 * s, 0, -11 * s);
        break;

      case 'H': // KUPA (Hearts ♥)
        path.moveTo(0, 10 * s);
        path.cubicTo(-5 * s, 5 * s, -11 * s, 0 * s, -11 * s, -5 * s);
        path.cubicTo(-11 * s, -9.5 * s, -6.5 * s, -11 * s, -2 * s, -7.5 * s);
        path.lineTo(0, -5 * s);
        path.lineTo(2 * s, -7.5 * s);
        path.cubicTo(6.5 * s, -11 * s, 11 * s, -9.5 * s, 11 * s, -5 * s);
        path.cubicTo(11 * s, 0 * s, 5 * s, 5 * s, 0, 10 * s);
        break;

      case 'D': // KARO (Diamonds ♦)
        path.moveTo(0, -11.5 * s);
        path.lineTo(8.5 * s, 0);
        path.lineTo(0, 11.5 * s);
        path.lineTo(-8.5 * s, 0);
        path.close();
        break;

      case 'C': // SİNEK (Clubs ♣)
        // Üst daire
        path.addOval(Rect.fromCircle(center: Offset(0, -5 * s), radius: 4.8 * s));
        // Sol daire
        path.addOval(Rect.fromCircle(center: Offset(-5.2 * s, 1.5 * s), radius: 4.8 * s));
        // Sağ daire
        path.addOval(Rect.fromCircle(center: Offset(5.2 * s, 1.5 * s), radius: 4.8 * s));
        // Merkez dolgu
        path.addRect(Rect.fromLTWH(-2 * s, -3 * s, 4 * s, 6 * s));
        // Ayak / Gövde
        final stem = Path()
          ..moveTo(-1 * s, 2 * s)
          ..lineTo(-5 * s, 11 * s)
          ..lineTo(5 * s, 11 * s)
          ..lineTo(1 * s, 2 * s)
          ..close();
        path.addPath(stem, Offset.zero);
        break;
    }

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  String _getRankLabel() {
    switch (rank) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return rank.toString();
    }
  }

  @override
  bool shouldRepaint(covariant VectorCardPainter old) {
    return old.rank != rank ||
        old.suit != suit ||
        old.isPhysicalJoker != isPhysicalJoker ||
        old.showAsWild != showAsWild ||
        old.isSelected != isSelected ||
        old.isWinningDiscardCandidate != isWinningDiscardCandidate;
  }
}
