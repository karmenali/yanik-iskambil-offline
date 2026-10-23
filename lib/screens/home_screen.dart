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

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    SettingsService.instance.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    SettingsService.instance.removeListener(_onSettingsChanged);
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
      backgroundColor: const Color(0xFF05160F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 1. ÜST PROFİL VE AYARLAR BARI (Orijinal Lobby Düzeni)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    // Profil Avatarı & İsim
                    InkWell(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const SettingsDialog(),
                      ),
                      borderRadius: BorderRadius.circular(30),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black38,
                              border: Border.all(
                                color: const Color(0xFFD4AF37),
                                width: 1.8,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                avatar.emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            settings.playerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Kurallar Butonu (En az 48x48 dp dokunma alanı)
                    IconButton(
                      tooltip: 'Kurallar',
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const RulesDialog(),
                      ),
                      icon: const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFFFDE047),
                        size: 23,
                      ),
                    ),

                    // Ayarlar Dişlisi (En az 48x48 dp dokunma alanı)
                    IconButton(
                      tooltip: 'Ayarlar',
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const SettingsDialog(),
                      ),
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white70,
                        size: 23,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 2. ORTA LOGO & YANIK İSKAMBİL VIP MARKASI (Orijinal 90x90 Çapında Maça Logosu)
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFF2D1B10), Color(0xFF0F0B08)],
                        ),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '♠',
                          style: TextStyle(
                            fontSize: 48,
                            color: Color(0xFFFDE047),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'YANIK İSKAMBİL VIP',
                      style: TextStyle(
                        color: Color(0xFFFDE047),
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'KLASİK İSKAMBİL DENEYİMİ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Aktif Oyun Modu Rozeti (Tıklayınca Ayarları Açar)
                    InkWell(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const SettingsDialog(),
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: settings.isAssisted
                                ? const [Color(0xFF1E3A8A), Color(0xFF0F172A)]
                                : const [Color(0xFF991B1B), Color(0xFF450A0A)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFD4AF37),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              settings.isAssisted ? '✨' : '🔥',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              settings.isAssisted
                                  ? 'Mod: Yardımlı Oyun'
                                  : 'Mod: Yardımsız Usta',
                              style: const TextStyle(
                                color: Color(0xFFFDE047),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.tune_rounded,
                              color: Color(0xFFFDE047),
                              size: 13,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 44),

              // 3. ANA OYNA BUTONU (Orijinal Yeşil Menü Butonu)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildBigMenuButton(
                  title: 'OYNA',
                  icon: Icons.play_arrow_rounded,
                  gradient: const [Color(0xFF059669), Color(0xFF047857)],
                  borderColor: const Color(0xFF34D399),
                  onTap: _startGame,
                ),
              ),

              const SizedBox(height: 36),

              // 4. ALT BİLGİ ROZETİ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 16),
                      SizedBox(width: 8),
                      Text(
                        '1 Oyuncu + 3 Bot • %100 Çevrimdışı',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBigMenuButton({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFFDE047), size: 28),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
