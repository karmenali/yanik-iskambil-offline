import 'package:flutter/material.dart';

class RulesDialog extends StatelessWidget {
  const RulesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 360;

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
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.menu_book, color: Color(0xFFFDE047), size: 22),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Nasıl Oynanır? (Kurallar)',
                            style: TextStyle(
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
                    tooltip: 'Kapat',
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
                      '🃏 1. Deste, Dağıtım ve Kart Çekme',
                      '• Oyun 2 tam deste (104 kart) + 2 Fiziksel Joker olmak üzere toplam 106 kağıtla oynanır.\n'
                      '• Her oyuncuya 10\'ar kart dağıtılır.\n'
                      '• Kart çekme YALNIZCA ortadaki kapalı desteden yapılır. Yanık İskambil\'de yerden kart çekilemez.',
                    ),
                    _buildRuleCard(
                      '👑 2. Jokerler (Gösterge & Fiziksel Joker)',
                      '• Dağıtım sonunda açılan Gösterge kartının sayı değeri o turun "Gösterge Jokeri" olur.\n'
                      '• Her iki destedeki bu sayıdaki tüm kartlar (8 adet) ve 2 Fiziksel Joker ile toplam 10 joker bulunur.\n'
                      '• Jokerler her per ve seride eksik kart yerine geçebilir.\n'
                      '• 3 veya daha fazla Joker tek başına bağımsız bir per oluşturabilir.\n'
                      '• DİKKAT: Tur sonunda per yapamayıp elinizde boşta kalan her Joker tam 25 ceza puanı yazar!',
                    ),
                    _buildRuleCard(
                      '📐 3. Geçerli Perler (Setler ve Seriler)',
                      'Kartlar en az 3\'erli gruplar halinde per yapılabilir:\n'
                      '• Grup Per (Set): Aynı sayı değerine sahip, FARKLI sembollerde en az 3 veya 4 kart (Örn: ♠K, ♦K, ♣K veya ♥8, ♠8, ♦8, ♣8). Aynı renkten çift kart aynı sete konulamaz.\n'
                      '• Seri Per (Run): Aynı sembolde ardışık en az 3 kart (Örn: ♥7, ♥8, ♥9, ♥10).\n'
                      '• As (A): Serinin başında (A-2-3) veya sonunda (J-Q-K-A) yer alabilir; ancak döngüsel olamaz (K-A-2 geçersizdir).',
                    ),
                    _buildRuleCard(
                      '🏆 4. El Açma ve Bitiş Kuralları',
                      '• Turunuzda kapalı desteden 1 kart çekerek 11 karta ulaşırsınız.\n'
                      '• Elinizdeki 10 kartı geçerli perler halinde bağlayıp 11. kartı masaya atarak "EL AÇ / BİTİR" yapabilirsiniz.\n'
                      '• Eli meşru açıp bitiren oyuncu o turda 0 CEZA PUANI alır.\n'
                      '• Diğer oyuncular ise per yapamadıkları boşta kalan kartlarının ceza puanlarını alır.',
                    ),
                    _buildRuleCard(
                      '💡 5. Örnek Kazanan El Senaryosu',
                      '10 meldelenmiş kart + 1 atılacak kart:\n'
                      '• 1. Istaka Sırası: [♠8, ♥8, ♦8] (3\'lü Grup Per)\n'
                      '• 2. Istaka Sırası: [♣4, ♣5, ♣6, ♣7] (4\'lü Seri Per)\n'
                      '• 3. Istaka Sırası: [♥J, ♥Q, ♥K] (3\'lü Seri Per)\n'
                      '• Masaya Atılacak Kart: [♦2] (Boşta kalan 11. kart)\n'
                      'Sonuç: 10 kart perlere bağlı, 11. kart masaya atılarak el başarıyla biter!',
                      accent: true,
                    ),
                    _buildRuleCard(
                      '✨ 6. Yardımlı Mod vs 🔥 Yardımsız Mod',
                      '• Yardımlı Mod: Perleriniz yeşil etiketlerle (✓ PER) ve elinizdeki anlık ceza puanı otomatik gösterilir. Bitiş için en uygun atılacak kart sistem tarafından desteklenir.\n'
                      '• Yardımsız Mod: Hiçbir per veya ceza ipucu verilmez! Istakanızdaki sıralama tamamen sizin dikkatinize aittir.\n'
                      '• ÖNEMLİ (Hatalı Açma Riski): Yardımsız modda eliniz geçerli olmadan hatalı el açarsanız DİREKT 101 CEZA ile yanarsınız; diğer tüm oyuncular 0 ceza alır!',
                    ),
                    _buildRuleCard(
                      '🔢 7. Ceza Puanları ve 101 Barajı',
                      'Per yapılmayan boşta kalan kartların ceza değerleri:\n'
                      '• As (A) = 10 puan\n'
                      '• Papaz (K), Kız (Q), Vale (J) = 10 puan\n'
                      '• 2 .. 10 = Kartın kendi rakam değeri\n'
                      '• Joker = 25 puan\n'
                      '• Toplam ceza puanı 101 veya üzerine çıkan oyuncu YANAR ve masadan elenir. Elenen oyuncular turlarda pas geçilir.',
                    ),
                    _buildRuleCard(
                      '🔄 8. Deste Tükenmesi (Beraberlik)',
                      '• 106 kağıtlık kapalı çekme destesi tamamen biter ve kimse elini açamamışsa tur berabere tamamlanır.\n'
                      '• Tüm oyuncular ellerindeki per dışı kartların ceza puanlarını hanelerine yazdırır.',
                    ),
                    _buildRuleCard(
                      '🥇 9. Masanın Şampiyonu',
                      '• Yanık İskambil hayatta kalma oyunudur. Rakipler 101 ceza barajını aşarak elendikçe oyun devam eder.\n'
                      '• Masada ayakta kalan son oyuncu oyunun ŞAMPİYONU olur!',
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
                  child: const Text(
                    'ANLADIM',
                    style: TextStyle(
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
