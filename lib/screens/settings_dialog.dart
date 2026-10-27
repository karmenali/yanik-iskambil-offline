import 'package:flutter/material.dart';
import '../engine/card_model.dart';
import '../l10n/l10n_extension.dart';
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
    final l10n = l10nOf(context);
    final currentLocale = SettingsService.instance.locale;

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
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.settings, color: Color(0xFFFDE047), size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.settingsTitle,
                            style: const TextStyle(
                              color: Color(0xFFFDE047),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.settingsClose,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),

              // 1. DİL SEÇİMİ / LANGUAGE
              Text(
                l10n.settingsLanguageSection,
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildLanguageOption(
                      flag: '🇹🇷',
                      label: l10n.settingsLanguageTr,
                      isSelected: currentLocale.languageCode == 'tr',
                      onTap: () async {
                        await SettingsService.instance.setLanguageCode('tr');
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildLanguageOption(
                      flag: '🇬🇧',
                      label: l10n.settingsLanguageEn,
                      isSelected: currentLocale.languageCode == 'en',
                      onTap: () async {
                        await SettingsService.instance.setLanguageCode('en');
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. OYUN MODU SEÇİMİ (YARDIMLI / YARDIMSIZ)
              Text(
                l10n.settingsGameModeSection,
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Yardımlı Mod Seçeneği
              _buildModeOption(
                title: l10n.settingsAssistedTitle,
                subtitle: l10n.settingsAssistedDesc,
                isSelected: _isAssisted,
                onTap: () async {
                  setState(() => _isAssisted = true);
                  await SettingsService.instance.setAssisted(true);
                },
              ),
              const SizedBox(height: 8),

              // Yardımsız Mod Seçeneği
              _buildModeOption(
                title: l10n.settingsUnassistedTitle,
                subtitle: l10n.settingsUnassistedDesc,
                isSelected: !_isAssisted,
                onTap: () async {
                  setState(() => _isAssisted = false);
                  await SettingsService.instance.setAssisted(false);
                },
              ),
              const SizedBox(height: 20),

              // 3. SES VE TİTREŞİM AYARLARI
              Text(
                l10n.settingsSoundSection,
                style: const TextStyle(
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
                title: Text(
                  l10n.settingsSoundEffects,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
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
                title: Text(
                  l10n.settingsVibration,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                value: _vibrationEnabled,
                onChanged: (val) async {
                  setState(() => _vibrationEnabled = val);
                  await SettingsService.instance.setVibrationEnabled(val);
                },
              ),
              const SizedBox(height: 16),

              // 4. OYUNCU PROFİLİ
              Text(
                l10n.settingsProfileSection,
                style: const TextStyle(
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
                  labelText: l10n.settingsPlayerNameLabel,
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
                  child: Text(
                    l10n.settingsSaveButton,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String flag,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF133827) : Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.white12,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFDE047) : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
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
