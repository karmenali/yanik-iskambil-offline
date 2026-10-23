import 'package:flutter/material.dart';
import '../engine/card_model.dart';
import '../services/settings_service.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late bool _isAssisted;
  late bool _soundEnabled;
  late bool _vibrationEnabled;
  late String _selectedAvatar;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    final s = SettingsService.instance;
    _isAssisted = s.isAssisted;
    _soundEnabled = s.soundEnabled;
    _vibrationEnabled = s.vibrationEnabled;
    _selectedAvatar = s.playerAvatar;
    _nameCtrl = TextEditingController(text: s.playerName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A2218),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings, color: Color(0xFFFDE047), size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Oyun Ayarları',
                        style: TextStyle(
                          color: Color(0xFFFDE047),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: 'Kapat',
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),

              // 1. OYUN MODU SEÇİMİ (YARDIMLI / YARDIMSIZ)
              const Text(
                '🎮 OYUN MODU',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Yardımlı Mod Seçeneği
              _buildModeOption(
                title: '✨ Yardımlı Mod (Tavsiye Edilen)',
                subtitle:
                    'Geçerli perleriniz (✓) ve elinizdeki toplam ceza sayısı canlı gösterilir. Otomatik per kontrolü açıktır.',
                isSelected: _isAssisted,
                onTap: () async {
                  setState(() => _isAssisted = true);
                  await SettingsService.instance.setAssisted(true);
                },
              ),
              const SizedBox(height: 8),

              // Yardımsız Mod Seçeneği
              _buildModeOption(
                title: '🔥 Yardımsız Usta Modu',
                subtitle:
                    'Hiçbir per veya ceza ipucu verilmez! Saf tecrübe ve dikkat. Hatalı el açan oyuncu direkt 101 puan ile yanar.',
                isSelected: !_isAssisted,
                onTap: () async {
                  setState(() => _isAssisted = false);
                  await SettingsService.instance.setAssisted(false);
                },
              ),
              const SizedBox(height: 20),

              // 2. SES VE TİTREŞİM AYARLARI
              const Text(
                '🔊 SES & TİTREŞİM',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(0xFFD4AF37),
                title: const Text(
                  'Kart ve Oyun Sesleri',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                value: _soundEnabled,
                onChanged: (val) async {
                  setState(() => _soundEnabled = val);
                  await SettingsService.instance.setSoundEnabled(val);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: const Color(0xFFD4AF37),
                title: const Text(
                  'Titreşim Bildirimleri',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                value: _vibrationEnabled,
                onChanged: (val) async {
                  setState(() => _vibrationEnabled = val);
                  await SettingsService.instance.setVibrationEnabled(val);
                },
              ),
              const SizedBox(height: 16),

              // 3. OYUNCU PROFİLİ
              const Text(
                '👤 OYUNCU PROFİLİ',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Oyuncu Adı',
                  labelStyle: const TextStyle(color: Colors.white60),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                  ),
                ),
                onChanged: (name) {
                  SettingsService.instance.setPlayerProfile(
                    name: name,
                    avatar: _selectedAvatar,
                  );
                },
              ),
              const SizedBox(height: 12),

              // Avatar Seçimi
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: VipAvatar.all.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final av = VipAvatar.all[i];
                    final isSel = _selectedAvatar == av.key;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedAvatar = av.key);
                        SettingsService.instance.setPlayerProfile(
                          name: _nameCtrl.text,
                          avatar: av.key,
                        );
                      },
                      child: Container(
                        width: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSel
                              ? const Color(0xFFD4AF37).withValues(alpha: 0.3)
                              : Colors.black26,
                          border: Border.all(
                            color: isSel ? const Color(0xFFD4AF37) : Colors.white24,
                            width: isSel ? 2.5 : 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(av.emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Kaydet / Kapat Butonu
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0A2218),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'KAYDET VE DÖN',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF133827)
              : Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4AF37)
                : Colors.white12,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFFD4AF37) : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFFDE047) : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
