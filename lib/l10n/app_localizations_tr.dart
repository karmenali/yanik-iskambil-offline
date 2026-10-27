// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Yanık İskambil';

  @override
  String get homeTitle => 'YANIK İSKAMBİL';

  @override
  String get defaultPlayerName => 'Oyuncu';

  @override
  String get homePlayButton => 'OYNA';

  @override
  String get homeAssistedMode => 'Yardımlı Mod';

  @override
  String get homeUnassistedMode => 'Yardımsız Mod';

  @override
  String get homeNewGameDialogTitle => 'Yeni Oyun Başlatılsın mı?';

  @override
  String get homeNewGameDialogContent =>
      'Devam eden bir oyununuz var. Yeni oyuna başlarsanız mevcut oyun ve puan durumu sıfırlanacaktır.';

  @override
  String get homeNewGameDialogCancel => 'İptal';

  @override
  String get homeNewGameDialogConfirm => 'Yeni Oyuna Başla';

  @override
  String get homeTooltipRules => 'Kurallar';

  @override
  String get homeTooltipSettings => 'Ayarlar';

  @override
  String get settingsTitle => 'Oyun Ayarları';

  @override
  String get settingsClose => 'Kapat';

  @override
  String get settingsLanguageSection => '🌐 DİL SEÇİMİ / LANGUAGE';

  @override
  String get settingsLanguageTr => 'Türkçe';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsGameModeSection => '🎮 OYUN MODU';

  @override
  String get settingsAssistedTitle => '✨ Yardımlı Mod (Tavsiye Edilen)';

  @override
  String get settingsAssistedDesc =>
      'Geçerli perleriniz (✓) ve elinizdeki toplam ceza sayısı canlı gösterilir. Otomatik per kontrolü açıktır.';

  @override
  String get settingsUnassistedTitle => '🔥 Yardımsız Usta Modu';

  @override
  String get settingsUnassistedDesc =>
      'Hiçbir per veya ceza ipucu verilmez! Saf tecrübe ve dikkat. Hatalı el açan oyuncu direkt 101 puan ile yanar.';

  @override
  String get settingsSoundSection => '🔊 SES & TİTREŞİM';

  @override
  String get settingsSoundEffects => 'Kart ve Oyun Sesleri';

  @override
  String get settingsVibration => 'Titreşim Bildirimleri';

  @override
  String get settingsProfileSection => '👤 OYUNCU PROFİLİ';

  @override
  String get settingsPlayerNameLabel => 'Oyuncu Adı';

  @override
  String get settingsSaveButton => 'KAYDET VE DÖN';

  @override
  String get rulesTitle => 'Nasıl Oynanır? (Kurallar)';

  @override
  String get rulesClose => 'Kapat';

  @override
  String get rulesUnderstandButton => 'ANLADIM';

  @override
  String get rulesSection1Title => '🃏 1. Deste, Dağıtım ve Kart Çekme';

  @override
  String get rulesSection1Body =>
      '• Oyun 2 tam deste (104 kart) + 2 Fiziksel Joker olmak üzere toplam 106 kağıtla oynanır.\n• Her oyuncuya 10\'ar kart dağıtılır.\n• Kart çekme YALNIZCA ortadaki kapalı desteden yapılır. Yanık İskambil\'de yerden kart çekilemez.';

  @override
  String get rulesSection2Title => '👑 2. Jokerler (Gösterge & Fiziksel Joker)';

  @override
  String get rulesSection2Body =>
      '• Dağıtım sonunda açılan Gösterge kartının sayı değeri o turun \"Gösterge Jokeri\" olur.\n• Her iki destedeki bu sayıdaki tüm kartlar (8 adet) ve 2 Fiziksel Joker ile toplam 10 joker bulunur.\n• Jokerler her per ve seride eksik kart yerine geçebilir.\n• 3 veya daha fazla Joker tek başına bağımsız bir per oluşturabilir.\n• DİKKAT: Tur sonunda per yapamayıp elinizde boşta kalan her Joker tam 25 ceza puanı yazar!';

  @override
  String get rulesSection3Title => '📐 3. Geçerli Perler (Setler ve Seriler)';

  @override
  String get rulesSection3Body =>
      'Kartlar en az 3\'erli gruplar halinde per yapılabilir:\n• Grup Per (Set): Aynı sayı değerine sahip, FARKLI sembollerde en az 3 veya 4 kart (Örn: ♠K, ♦K, ♣K veya ♥8, ♠8, ♦8, ♣8). Aynı renkten çift kart aynı sete konulamaz.\n• Seri Per (Run): Aynı sembolde ardışık en az 3 kart (Örn: ♥7, ♥8, ♥9, ♥10).\n• As (A): Serinin başında (A-2-3) veya sonunda (J-Q-K-A) yer alabilir; ancak döngüsel olamaz (K-A-2 geçersizdir).';

  @override
  String get rulesSection4Title => '🏆 4. El Açma ve Bitiş Kuralları';

  @override
  String get rulesSection4Body =>
      '• Turunuzda kapalı desteden 1 kart çekerek 11 karta ulaşırsınız.\n• Elinizdeki 10 kartı geçerli perler halinde bağlayıp 11. kartı masaya atarak \"EL AÇ / BİTİR\" yapabilirsiniz.\n• Eli meşru açıp bitiren oyuncu o turda 0 CEZA PUANI alır.\n• Diğer oyuncular ise per yapamadıkları boşta kalan kartlarının ceza puanlarını alır.';

  @override
  String get rulesSection5Title => '💡 5. Örnek Kazanan El Senaryosu';

  @override
  String get rulesSection5Body =>
      '10 meldelenmiş kart + 1 atılacak kart:\n• 1. Istaka Sırası: [♠8, ♥8, ♦8] (3\'lü Grup Per)\n• 2. Istaka Sırası: [♣4, ♣5, ♣6, ♣7] (4\'lü Seri Per)\n• 3. Istaka Sırası: [♥J, ♥Q, ♥K] (3\'lü Seri Per)\n• Masaya Atılacak Kart: [♦2] (Boşta kalan 11. kart)\nSonuç: 10 kart perlere bağlı, 11. kart masaya atılarak el başarıyla biter!';

  @override
  String get rulesSection6Title => '✨ 6. Yardımlı Mod vs 🔥 Yardımsız Mod';

  @override
  String get rulesSection6Body =>
      '• Yardımlı Mod: Perleriniz yeşil etiketlerle (✓ PER) ve elinizdeki anlık ceza puanı otomatik gösterilir. Bitiş için en uygun atılacak kart sistem tarafından desteklenir.\n• Yardımsız Mod: Hiçbir per veya ceza ipucu verilmez! Istakanızdaki sıralama tamamen sizin dikkatinize aittir.\n• ÖNEMLİ (Hatalı Açma Riski): Yardımsız modda eliniz geçerli olmadan hatalı el açarsanız DİREKT 101 CEZA ile yanarsınız; diğer tüm oyuncular 0 ceza alır!';

  @override
  String get rulesSection7Title => '🔢 7. Ceza Puanları ve 101 Barajı';

  @override
  String get rulesSection7Body =>
      'Per yapılmayan boşta kalan kartların ceza değerleri:\n• As (A) = 10 puan\n• Papaz (K), Kız (Q), Vale (J) = 10 puan\n• 2 .. 10 = Kartın kendi rakam değeri\n• Joker = 25 puan\n• Toplam ceza puanı 101 veya üzerine çıkan oyuncu YANAR ve masadan elenir. Elenen oyuncular turlarda pas geçilir.';

  @override
  String get rulesSection8Title => '🔄 8. Deste Tükenmesi (Beraberlik)';

  @override
  String get rulesSection8Body =>
      '• 106 kağıtlık kapalı çekme destesi tamamen biter ve kimse elini açamamışsa tur berabere tamamlanır.\n• Tüm oyuncular ellerindeki per dışı kartların ceza puanlarını hanelerine yazdırır.';

  @override
  String get rulesSection9Title => '🥇 9. Masanın Şampiyonu';

  @override
  String get rulesSection9Body =>
      '• Yanık İskambil hayatta kalma oyunudur. Rakipler 101 ceza barajını aşarak elendikçe oyun devam eder.\n• Masada ayakta kalan son oyuncu oyunun ŞAMPİYONU olur!';

  @override
  String get tableTooltipLeave => 'Masadan Ayrıl';

  @override
  String get tableTooltipScoresheet => '101 Skor Tablosu';

  @override
  String get tableTooltipSettings => 'Ayarlar';

  @override
  String tableRoundBadge(int roundNumber) {
    return 'El $roundNumber';
  }

  @override
  String get tableModeAssisted => 'Yardımlı';

  @override
  String get tableModeUnassisted => 'Yardımsız';

  @override
  String get tableIndicator => 'GÖSTERGE';

  @override
  String tableDeckCount(int count) {
    return 'DESTE $count';
  }

  @override
  String tableDrawNow(int count) {
    return '👇 ÇEK ($count)';
  }

  @override
  String get tableDiscardLabel => 'ATILAN';

  @override
  String get tableDiscardPile => 'ATILAN KART';

  @override
  String get tableBtnDraw => 'DESTEDEN\nÇEK';

  @override
  String get tableBtnAutoMeld => 'OTOMATİK\nPER DİZ';

  @override
  String get tableBtnSortRank => 'SAYIYA GÖRE\nSIRALA';

  @override
  String get tableBtnDiscard => 'KAĞIDI\nAT';

  @override
  String get tableBtnDeclareFinish => 'EL AÇ\nBİTİR';

  @override
  String get tableRackUnassisted => '🔥 Yardımsız Mod';

  @override
  String get tableRackReadyToFinish => '✨ El Açmaya Hazır';

  @override
  String tableRackPenaltyPoints(int points) {
    return 'Ceza: $points Puan';
  }

  @override
  String tableRackSelected(String card) {
    return 'Seçili: $card';
  }

  @override
  String get tableCardBadgeFinish => 'AT & AÇ';

  @override
  String get tablePlayerYouSuffix => ' (Sen)';

  @override
  String get tablePlayerWon => 'KAZANDI';

  @override
  String tablePlayerBust(int score) {
    return 'YANDI ($score)';
  }

  @override
  String tablePlayerPenalty(int score) {
    return 'Ceza: $score';
  }

  @override
  String get tableLeaveDialogTitle => 'Masadan Çıkılsın mı?';

  @override
  String get tableLeaveDialogContent =>
      'Mevcut oyun sonlandırılacak ve ana menüye dönülecektir.';

  @override
  String get tableLeaveDialogCancel => 'İPTAL';

  @override
  String get tableLeaveDialogConfirm => 'ÇIK';

  @override
  String get tableFalseFinishDialogTitle => 'Hatalı El Açma Uyarısı';

  @override
  String get tableFalseFinishDialogContent =>
      'Geçersiz el açarsanız 101 ceza alacaksınız. Devam etmek istiyor musunuz?';

  @override
  String get tableFalseFinishDialogCancel => 'Vazgeç';

  @override
  String get tableFalseFinishDialogConfirm => 'Devam Et';

  @override
  String get tableNotReadySnackBar => 'Eliniz henüz bitişe hazır değil.';

  @override
  String get tableDiscardSheetTitle => 'Atılacak Kartı Seçin';

  @override
  String get tableDiscardSheetDesc =>
      'Elinizi açıp bitirmek için masaya atmak istediğiniz kartı seçin:';

  @override
  String get tableDiscardSheetCancel => 'Vazgeç';

  @override
  String get tableRecentDiscardsTitle => '🗑️ Yere Atılan Son Kağıtlar';

  @override
  String get tableRecentDiscardsEmpty => 'Bu elde henüz yere kağıt atılmadı.';

  @override
  String get tableScoresheetTitle => '📝 OYUN ÇETELESİ (101 CEZA TABLOSU)';

  @override
  String tableScoresheetSubtitle(int roundNumber, String mode) {
    return 'El #$roundNumber • $mode';
  }

  @override
  String get tableScoresheetColRound => 'EL';

  @override
  String get tableScoresheetEmpty =>
      'Henüz el tamamlanmadı. İlk el bittiğinde cezalar buraya yazılacaktır.';

  @override
  String tableScoresheetRoundLabel(int roundNumber) {
    return '$roundNumber. El';
  }

  @override
  String get tableScoresheetDeclared => 'AÇTI';

  @override
  String get tableScoresheetTotal => 'TOPLAM';

  @override
  String get tableScoresheetBust => 'YANDI';

  @override
  String get summaryTitleGameOver => '🏆 OYUN BİTTİ';

  @override
  String summaryTitleRoundResult(int roundNumber) {
    return '📊 TUR $roundNumber SONUCU';
  }

  @override
  String get summaryPlayerDeclared => '✨ Eli Açtı (0 Ceza)';

  @override
  String get summaryPlayerFalseFinish => '❌ Hatalı El Açma (101 Ceza)';

  @override
  String summaryPlayerUnmeldedCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Boşta: $count kağıt',
      one: 'Boşta: 1 kağıt',
    );
    return '$_temp0';
  }

  @override
  String summaryPlayerBust(int score) {
    return '🔥 YANDI ($score)';
  }

  @override
  String summaryPlayerTotalScore(int score) {
    return 'Toplam: $score / 101';
  }

  @override
  String summaryMeldBadge(int meldNumber) {
    return 'PER $meldNumber';
  }

  @override
  String summaryDeadwoodBadge(int count) {
    return 'BOŞTA ($count)';
  }

  @override
  String get summaryBtnMainMenu => 'ANA MENÜ';

  @override
  String get summaryBtnPlayAgain => 'TEKRAR OYNA 🏆';

  @override
  String get summaryBtnContinue => 'DEVAM ET ➜';

  @override
  String get celebrationTableChampion => 'MASA ŞAMPİYONU';

  @override
  String get celebrationRoundWinner => 'ELİ AÇTI VE BİTİRDİ';

  @override
  String celebrationBotFinished(String winnerName) {
    return '$winnerName BİTİRDİ';
  }

  @override
  String get celebrationChampionDesc =>
      'Tebrikler! Masayı 1. Olarak Tamamladınız!';

  @override
  String get celebrationHumanRoundDesc => 'Harika El! 0 Ceza Puanı';

  @override
  String celebrationBotRoundDesc(String winnerName) {
    return '$winnerName Turu 0 Ceza İle Kazandı';
  }

  @override
  String get celebrationTapToSkip => 'Kutlamayı geçmek için dokunun';

  @override
  String get gameOverTitleChampion => '🏆 ŞAMPİYON! 🏆';

  @override
  String get gameOverTitleBust => '🔥 OYUN BİTTİ';

  @override
  String get championHumanMessage =>
      'Tebrikler! Masayı Şampiyon Olarak Tamamladınız! 🏆';

  @override
  String championBotMessage(String name) {
    return '$name Şampiyon Oldu!';
  }
}
