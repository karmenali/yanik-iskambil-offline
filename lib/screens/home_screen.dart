import 'package:flutter/material.dart';
import '../engine/card_model.dart';
import '../engine/offline_table_controller.dart';
import '../l10n/l10n_extension.dart';
import '../services/settings_service.dart';
import '../services/sound_fx.dart';
import '../widgets/game_logo_widget.dart';
import 'offline_table_screen.dart';
import 'rules_dialog.dart';
import 'settings_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isStartingGame = false;

  @override
  void initState() {
    super.initState();
    OfflineTableController.instance.pauseGame();
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

  Future<void> _handlePlayButton() async {
    if (_isStartingGame) return;
    _isStartingGame = true;

    final ctrl = OfflineTableController.instance;
    final l10n = l10nOf(context);

    // Devam eden ve henüz bitmemiş aktif bir oyun varsa onay sor
    if (ctrl.hasActiveMatch) {
      final shouldStartNew = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF091C14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFDE047), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.homeNewGameDialogTitle,
                  style: const TextStyle(
                    color: Color(0xFFFDE047),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            l10n.homeNewGameDialogContent,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                l10n.homeNewGameDialogCancel,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF0A2218),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                l10n.homeNewGameDialogConfirm,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ],
        ),
      );

      if (shouldStartNew != true) {
        _isStartingGame = false;
        return;
      }
    }

    _startMatchAndNavigate();
  }

  void _startMatchAndNavigate() {
    SoundFx.playCardSlide();
    OfflineTableController.instance.initMatch();

    if (!mounted) {
      _isStartingGame = false;
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OfflineTableScreen()),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isStartingGame = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    final avatar = VipAvatar.fromKey(settings.playerAvatar);
    final l10n = l10nOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF05160F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [Color(0xFF0C2C1D), Color(0xFF071B11), Color(0xFF040E0A)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final h = constraints.maxHeight;
              final logoSize = (h * 0.17).clamp(84.0, 140.0);
              final isSmall = h < 620;

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: h),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // 1. ÜST BAR: Profil ve Ayarlar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              // Profil Avatarı & İsim
                              Expanded(
                                child: InkWell(
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => const SettingsDialog(),
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF0B2217),
                                          border: Border.all(
                                            color: const Color(0xFFD4AF37),
                                            width: 1.8,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black45,
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            avatar.emoji,
                                            style: const TextStyle(fontSize: 22),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          settings.playerName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Kurallar Butonu (En az 48x48 dp dokunma alanı)
                              IconButton(
                                tooltip: l10n.homeTooltipRules,
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

                              // Ayarlar Butonu (En az 48x48 dp dokunma alanı)
                              IconButton(
                                tooltip: l10n.homeTooltipSettings,
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

                        const Spacer(flex: 2),

                        // 2. MERKEZ LOGO VE BAŞLIK
                        Center(
                          child: GameLogoWidget(size: logoSize),
                        ),
                        SizedBox(height: isSmall ? 10 : 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              l10n.homeTitle,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFFDE047),
                                fontWeight: FontWeight.w900,
                                fontSize: isSmall ? 24 : 28,
                                letterSpacing: 2.0,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isSmall ? 8 : 14),

                        // Aktif Tercih Edilen Mod Rozeti (Yardımlı / Yardımsız)
                        InkWell(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => const SettingsDialog(),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF081F15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                                width: 1.2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    settings.isAssisted ? '✨' : '🔥',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    settings.isAssisted ? l10n.homeAssistedMode : l10n.homeUnassistedMode,
                                    style: const TextStyle(
                                      color: Color(0xFFFDE047),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.tune_rounded,
                                    color: Color(0xFFFDE047),
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const Spacer(flex: 3),

                        // 3. GÜÇLÜ VE KOLAY FARK EDİLEN OYNA BUTONU
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: _buildPlayButton(
                            label: l10n.homePlayButton,
                            onTap: _handlePlayButton,
                          ),
                        ),

                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton({required String label, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857), Color(0xFF065F46)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF34D399), width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFFFDE047),
                    size: 34,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
