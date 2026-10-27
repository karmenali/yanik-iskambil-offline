import 'package:flutter/material.dart';
import '../l10n/l10n_extension.dart';

class RulesDialog extends StatelessWidget {
  const RulesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 360;
    final l10n = l10nOf(context);

    return Dialog(
      backgroundColor: const Color(0xFF0A2218),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: mediaQuery.size.height * 0.85,
        ),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 14 : 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık Barı
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book, color: Color(0xFFFDE047), size: 22),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.rulesTitle,
                            style: const TextStyle(
                              color: Color(0xFFFDE047),
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.rulesClose,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 10),

              // Kaydırılabilir Kurallar Listesi
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildRuleCard(
                      l10n.rulesSection1Title,
                      l10n.rulesSection1Body,
                    ),
                    _buildRuleCard(
                      l10n.rulesSection2Title,
                      l10n.rulesSection2Body,
                    ),
                    _buildRuleCard(
                      l10n.rulesSection3Title,
                      l10n.rulesSection3Body,
                    ),
                    _buildRuleCard(
                      l10n.rulesSection4Title,
                      l10n.rulesSection4Body,
                    ),
                    _buildRuleCard(
                      l10n.rulesSection5Title,
                      l10n.rulesSection5Body,
                      accent: true,
                    ),
                    _buildRuleCard(
                      l10n.rulesSection6Title,
                      l10n.rulesSection6Body,
                    ),
                    _buildRuleCard(
                      l10n.rulesSection7Title,
                      l10n.rulesSection7Body,
                    ),
                    _buildRuleCard(
                      l10n.rulesSection8Title,
                      l10n.rulesSection8Body,
                    ),
                    _buildRuleCard(
                      l10n.rulesSection9Title,
                      l10n.rulesSection9Body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Onay Butonu
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0A2218),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.rulesUnderstandButton,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleCard(String title, String body, {bool accent = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent ? const Color(0x22D4AF37) : Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent
              ? const Color(0xFFFDE047)
              : const Color(0xFFD4AF37).withValues(alpha: 0.35),
          width: accent ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accent ? const Color(0xFFFDE047) : const Color(0xFFFDE047),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
