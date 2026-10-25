import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Zynga / Monte Carlo Casino Standartlarında Prestijli Altın Parıltı ve Amblem Kutlama Katmanı.
///
/// Özellikler:
/// - Çizgi film tarzı aşırı konfeti yerine zarif altın parçacıklar ve parıltılar (`CustomPainter`).
/// - Sıfır gereksiz widget üretimi: Parçacıklar matematiksel olarak pre-seeded değerlerle çizilir.
/// - Merkeze zarif 24K altın detaylı zümrüt kazanma amblemi scale-in ve fade ile belirir.
/// - Kullanıcı ekrana dokunursa (tap-to-skip) anında sonuç ekranına geçer.
class VictoryCelebrationOverlay extends StatelessWidget {
  final Animation<double> animation;
  final String winnerName;
  final bool isHumanWinner;
  final bool isGrandChampion;
  final VoidCallback onTap;

  const VictoryCelebrationOverlay({
    super.key,
    required this.animation,
    required this.winnerName,
    required this.isHumanWinner,
    required this.isGrandChampion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = animation.value;

        // Amblem scale & fade eğrileri
        final emblemScale = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.12, 0.55, curve: Curves.easeOutBack),
        ).value;

        final emblemOpacity = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.10, 0.40, curve: Curves.easeOut),
        ).value;

        // Bitişe doğru hafif zarif sönümleme
        final fadeOut = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.85, 1.0, curve: Curves.easeIn),
        ).value;
        final overallAlpha = (1.0 - fadeOut).clamp(0.0, 1.0);

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Opacity(
            opacity: overallAlpha,
            child: Stack(
              children: [
                // 1. ZARİF ALTIN PARÇACIKLAR VE IŞILTI KATMANI (GPU Hızlandırmalı CustomPainter)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _GoldenSparksPainter(progress: progress),
                    ),
                  ),
                ),

                // 2. MERKEZDEKİ KRALİYET KAZANMA AMBLEMİ (Royal Victory Seal)
                Center(
                  child: Transform.scale(
                    scale: (0.75 + 0.25 * emblemScale).clamp(0.0, 1.15),
                    child: Opacity(
                      opacity: emblemOpacity.clamp(0.0, 1.0),
                      child: Container(
                        width: 290,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF0F3525), Color(0xFF061A11)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFD4AF37),
                            width: 2.0,
                          ),
                          boxShadow: [
                            // Dış altın ambient parıltı
                            BoxShadow(
                              color: const Color(0xFFD97706).withValues(alpha: 0.35),
                              blurRadius: 28,
                              spreadRadius: 3,
                            ),
                            // Derin casino gölgesi
                            const BoxShadow(
                              color: Colors.black87,
                              blurRadius: 30,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // İç asil altın süs çerçevesi
                            Container(
                              padding: const EdgeInsets.all(1.5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFDE047).withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Taç / Kupa & Yıldızlar
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('✦', style: TextStyle(color: Color(0xFFFDE047), fontSize: 13)),
                                        const SizedBox(width: 8),
                                        Text(
                                          isGrandChampion ? '👑' : '🏆',
                                          style: const TextStyle(fontSize: 26),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('✦', style: TextStyle(color: Color(0xFFFDE047), fontSize: 13)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Ana Başlık
                                    Text(
                                      isGrandChampion
                                          ? 'MASA ŞAMPİYONU'
                                          : (isHumanWinner ? 'ELİ AÇTI VE BİTİRDİ' : '$winnerName BİTİRDİ'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFFDE047),
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        shadows: [
                                          Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1.5)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 5),

                                    // Alt Açıklama
                                    Text(
                                      isGrandChampion
                                          ? 'Tebrikler! Masayı 1. Olarak Tamamladınız!'
                                          : (isHumanWinner
                                              ? 'Harika El! 0 Ceza Puanı'
                                              : '$winnerName Turu 0 Ceza İle Kazandı'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Dokunma / İlerleme İpucu (FittedBox ile taşma güvenliği sağlandı)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text('✦ ', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10)),
                                  Text(
                                    'Kutlamayı geçmek için dokunun',
                                    style: TextStyle(
                                      color: Color(0xFFFDE047),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  Text(' ✦', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

class _ParticleSpec {
  final double xRatio;
  final double yRatio;
  final double speedY;
  final double swaySpeed;
  final double swayAmp;
  final double size;
  final int type; // 0: 4-pointed star, 1: glowing circle orb, 2: micro glimmer
  final Color color;

  const _ParticleSpec({
    required this.xRatio,
    required this.yRatio,
    required this.speedY,
    required this.swaySpeed,
    required this.swayAmp,
    required this.size,
    required this.type,
    required this.color,
  });
}

/// Performans odaklı, GPU hızlandırmalı Altın Parçacık Boyayıcısı
class _GoldenSparksPainter extends CustomPainter {
  final double progress;

  _GoldenSparksPainter({required this.progress});

  // Pre-seeded 30 sabit parçacık tanımı (Her karede new/allocation yapılmaz!)
  static const List<_ParticleSpec> _specs = [
    _ParticleSpec(xRatio: 0.15, yRatio: 0.70, speedY: 0.35, swaySpeed: 5.0, swayAmp: 14, size: 5.0, type: 0, color: Color(0xFFFFD54F)),
    _ParticleSpec(xRatio: 0.85, yRatio: 0.65, speedY: 0.40, swaySpeed: 6.0, swayAmp: 16, size: 4.5, type: 0, color: Color(0xFFFDE047)),
    _ParticleSpec(xRatio: 0.30, yRatio: 0.80, speedY: 0.30, swaySpeed: 4.5, swayAmp: 12, size: 6.0, type: 1, color: Color(0xFFFFA000)),
    _ParticleSpec(xRatio: 0.70, yRatio: 0.75, speedY: 0.38, swaySpeed: 5.5, swayAmp: 15, size: 5.5, type: 1, color: Color(0xFFFFE082)),
    _ParticleSpec(xRatio: 0.50, yRatio: 0.60, speedY: 0.45, swaySpeed: 7.0, swayAmp: 18, size: 4.0, type: 0, color: Color(0xFFFFF8E1)),
    _ParticleSpec(xRatio: 0.22, yRatio: 0.55, speedY: 0.32, swaySpeed: 4.0, swayAmp: 10, size: 3.0, type: 2, color: Color(0xFFFFD54F)),
    _ParticleSpec(xRatio: 0.78, yRatio: 0.50, speedY: 0.34, swaySpeed: 4.8, swayAmp: 11, size: 3.5, type: 2, color: Color(0xFFF59E0B)),
    _ParticleSpec(xRatio: 0.40, yRatio: 0.72, speedY: 0.42, swaySpeed: 6.2, swayAmp: 14, size: 5.0, type: 0, color: Color(0xFFFDE047)),
    _ParticleSpec(xRatio: 0.60, yRatio: 0.68, speedY: 0.36, swaySpeed: 5.1, swayAmp: 13, size: 5.2, type: 1, color: Color(0xFFFFA000)),
    _ParticleSpec(xRatio: 0.10, yRatio: 0.85, speedY: 0.28, swaySpeed: 3.8, swayAmp: 9, size: 4.0, type: 2, color: Color(0xFFFFE082)),
    _ParticleSpec(xRatio: 0.90, yRatio: 0.82, speedY: 0.31, swaySpeed: 4.2, swayAmp: 10, size: 4.2, type: 0, color: Color(0xFFFFD54F)),
    _ParticleSpec(xRatio: 0.25, yRatio: 0.40, speedY: 0.40, swaySpeed: 5.8, swayAmp: 15, size: 5.0, type: 1, color: Color(0xFFFDE047)),
    _ParticleSpec(xRatio: 0.75, yRatio: 0.38, speedY: 0.38, swaySpeed: 5.2, swayAmp: 14, size: 4.8, type: 0, color: Color(0xFFFFF8E1)),
    _ParticleSpec(xRatio: 0.48, yRatio: 0.88, speedY: 0.44, swaySpeed: 6.5, swayAmp: 17, size: 6.5, type: 1, color: Color(0xFFF59E0B)),
    _ParticleSpec(xRatio: 0.52, yRatio: 0.45, speedY: 0.35, swaySpeed: 4.6, swayAmp: 12, size: 3.2, type: 2, color: Color(0xFFFFD54F)),
    _ParticleSpec(xRatio: 0.18, yRatio: 0.62, speedY: 0.33, swaySpeed: 5.0, swayAmp: 13, size: 4.0, type: 0, color: Color(0xFFFFE082)),
    _ParticleSpec(xRatio: 0.82, yRatio: 0.58, speedY: 0.37, swaySpeed: 5.4, swayAmp: 14, size: 4.4, type: 1, color: Color(0xFFFFA000)),
    _ParticleSpec(xRatio: 0.35, yRatio: 0.50, speedY: 0.39, swaySpeed: 6.0, swayAmp: 16, size: 4.6, type: 0, color: Color(0xFFFDE047)),
    _ParticleSpec(xRatio: 0.65, yRatio: 0.48, speedY: 0.35, swaySpeed: 4.9, swayAmp: 12, size: 5.0, type: 1, color: Color(0xFFF59E0B)),
    _ParticleSpec(xRatio: 0.28, yRatio: 0.90, speedY: 0.42, swaySpeed: 6.1, swayAmp: 15, size: 3.8, type: 2, color: Color(0xFFFFF8E1)),
    _ParticleSpec(xRatio: 0.72, yRatio: 0.88, speedY: 0.40, swaySpeed: 5.7, swayAmp: 14, size: 4.0, type: 0, color: Color(0xFFFFD54F)),
    _ParticleSpec(xRatio: 0.44, yRatio: 0.35, speedY: 0.30, swaySpeed: 4.4, swayAmp: 11, size: 5.0, type: 1, color: Color(0xFFFFE082)),
    _ParticleSpec(xRatio: 0.56, yRatio: 0.32, speedY: 0.32, swaySpeed: 4.7, swayAmp: 12, size: 4.8, type: 0, color: Color(0xFFFDE047)),
    _ParticleSpec(xRatio: 0.08, yRatio: 0.52, speedY: 0.29, swaySpeed: 3.9, swayAmp: 9, size: 3.0, type: 2, color: Color(0xFFFFA000)),
    _ParticleSpec(xRatio: 0.92, yRatio: 0.46, speedY: 0.31, swaySpeed: 4.3, swayAmp: 10, size: 3.5, type: 0, color: Color(0xFFFFD54F)),
  ];

  static final Paint _paint = Paint()..style = PaintingStyle.fill;
  static final Paint _glowPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    if (t <= 0.0 || t >= 1.0) return;

    // Genel parlaklık eğrisi: Başlangıçta yumuşak belirir, sonda yumuşakça söner
    final double globalAlpha = t < 0.20
        ? (t / 0.20)
        : (t > 0.75 ? ((1.0 - t) / 0.25) : 1.0);

    for (int i = 0; i < _specs.length; i++) {
      final spec = _specs[i];

      // Parçacık koordinatları (aşağıdan yukarı hafif süzülme ve sinüzoidal salınım)
      final dx = spec.xRatio * size.width +
          math.sin(t * spec.swaySpeed + i) * spec.swayAmp;
      final dy = spec.yRatio * size.height - t * spec.speedY * size.height;

      // Parçacık boyutu ve minik parıldama (twinkle)
      final twinkle = 0.85 + 0.25 * math.sin(t * 10.0 + i * 2.0);
      final r = (spec.size * twinkle).clamp(1.5, 9.0);

      final pAlpha = (globalAlpha * (0.65 + 0.35 * math.sin(t * 8.0 + i))).clamp(0.0, 1.0);
      _paint.color = spec.color.withValues(alpha: pAlpha);

      if (spec.type == 0) {
        // 4 Köşeli Elmas Yıldız (✦)
        _drawDiamondStar(canvas, dx, dy, r, _paint);
      } else if (spec.type == 1) {
        // Yumuşak Işıltılı Küre (Aura + Nokta)
        _glowPaint.color = spec.color.withValues(alpha: pAlpha * 0.35);
        canvas.drawCircle(Offset(dx, dy), r * 1.8, _glowPaint);
        canvas.drawCircle(Offset(dx, dy), r * 0.75, _paint);
      } else {
        // Mikro Pırıltı Noktası
        canvas.drawCircle(Offset(dx, dy), r * 0.65, _paint);
      }
    }
  }

  void _drawDiamondStar(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path()
      ..moveTo(cx, cy - r)
      ..quadraticBezierTo(cx, cy, cx + r * 0.45, cy)
      ..quadraticBezierTo(cx, cy, cx, cy + r)
      ..quadraticBezierTo(cx, cy, cx - r * 0.45, cy)
      ..quadraticBezierTo(cx, cy, cx, cy - r)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GoldenSparksPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
