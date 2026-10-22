import 'package:flutter/material.dart';

class RulesDialog extends StatelessWidget {
  const RulesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A2218),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu_book, color: Color(0xFFFDE047), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Nasıl Oynanır? (Kurallar)',
                      style: TextStyle(
                        color: Color(0xFFFDE047),
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const Divider(color: Colors.white24),
            const SizedBox(height: 6),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildRuleCard(
                    '🃏 106 Kağıt & 3 Sıralı Istaka Düzeni',
                    'Oyun 2 tam deste (104 kağıt) + 2 Fiziksel Joker olmak üzere toplam 106 kağıtla oynanır. '
                        'Her oyuncuya 10\'ar kağıt dağıtılır. Kağıtlarınızı 3 yatay sırada serbestçe dizebilirsiniz.',
                  ),
                  _buildRuleCard(
                    '👑 Gösterge Jokeri (Wild Card)',
                    'Dağıtım sonunda açılan Gösterge kağıdı ile aynı sayıdaki tüm kağıtlar ve 2 fiziksel Joker, o el boyunca JOKER yerine geçer. '
                        'Elinizde per yapmadan kalan Joker 25 ceza puanı yazar.',
                  ),
                  _buildRuleCard(
                    '✨ Yardımlı Mod vs 🔥 Yardımsız Mod',
                    '• Yardımlı Mod: Geçerli perleriniz (✓ PER) ve elinizdeki ceza puanı otomatik olarak canlı gösterilir.\n'
                        '• Yardımsız Mod: Hiçbir per veya ceza ipucu verilmez! DİKKAT: Yardımsız modda hatalı el açan oyuncu DİREKT 101 CEZA ile yanar!',
                  ),
                  _buildRuleCard(
                    '🔍 Şeffaf El Açma & Ceza İşleme',
                    'Bir oyuncu 10 kağıdını yere açıp 11. kağıdını attığında tur biter. '
                        'Eli açan oyuncu 0 ceza puanı alırken, diğer oyuncuların elinde per olmamış kağıtların sayı değerleri ceza olarak işlenir.',
                  ),
                  _buildRuleCard(
                    '🔥 101 Barajı',
                    'Toplam ceza puanı 101 veya üzerine çıkan oyuncu yanar ve elenir. '
                        'Ayakta kalan son oyuncu masanın şampiyonu olur!',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF0A2218),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('ANLADIM', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFDE047),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
