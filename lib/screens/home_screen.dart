import 'package:flutter/material.dart';
import '../engine/card_model.dart';
import '../engine/offline_table_controller.dart';
import '../services/settings_service.dart';
import '../services/sound_fx.dart';
import 'offline_table_screen.dart';
import 'rules_dialog.dart';
import 'settings_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );

    SettingsService.instance.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsService.instance.removeListener(_onSettingsChanged);
    _animCtrl.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  void _startGame() {
    SoundFx.playCardSlide();
    OfflineTableController.instance.initMatch();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OfflineTableScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    final avatar = VipAvatar.fromKey(settings.playerAvatar);

    return Scaffold(
      body: Stack(
        children: [
          // Arka Plan
          Positioned.fill(
            child: Image.asset(
              'assets/images/table_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Üst Bar: Profil & Ayarlar / Kurallar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Oyuncu Profili
                      GestureDetector(
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => const SettingsDialog(),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(avatar.emoji,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text(
                                settings.playerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Ayarlar ve Kurallar Butonları
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.menu_book,
                                color: Color(0xFFFDE047), size: 26),
                            tooltip: 'Kurallar',
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => const RulesDialog(),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.settings,
                                color: Color(0xFFFDE047), size: 26),
                            tooltip: 'Ayarlar',
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => const SettingsDialog(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // Logo & Başlık
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                          blurRadius: 25,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/game_logo.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'YANIK İSKAMBİL',
                    style: TextStyle(
                      color: Color(0xFFFDE047),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'VIP Çevrimdışı Sürüm',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Aktif Mod Göstergesi (Tıklayınca Ayarları Açar)
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => const SettingsDialog(),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: settings.isAssisted
                            ? const Color(0xFF10B981).withValues(alpha: 0.25)
                            : const Color(0xFFDC2626).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: settings.isAssisted
                              ? const Color(0xFF10B981)
                              : const Color(0xFFDC2626),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            settings.isAssisted
                                ? Icons.check_circle_outline
                                : Icons.local_fire_department,
                            color: settings.isAssisted
                                ? const Color(0xFF34D399)
                                : const Color(0xFFF87171),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            settings.isAssisted
                                ? 'Mod: Yardımlı'
                                : 'Mod: Yardımsız Usta',
                            style: TextStyle(
                              color: settings.isAssisted
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFF87171),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, color: Colors.white54, size: 12),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // BÜYÜK "OYNA" BUTONU
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFDE047),
                            Color(0xFFD4AF37),
                            Color(0xFFB45309),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                            blurRadius: 18,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _startGame,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFF0A2218),
                              size: 34,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'OYNA',
                              style: TextStyle(
                                color: Color(0xFF0A2218),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Alt Sürüm Bilgisi
                  const Text(
                    '1 Oyuncu + 3 Bot • Google Play Store Sürümü',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
