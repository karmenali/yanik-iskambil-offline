import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yanık İskambil'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In tr, this message translates to:
  /// **'YANIK İSKAMBİL'**
  String get homeTitle;

  /// No description provided for @defaultPlayerName.
  ///
  /// In tr, this message translates to:
  /// **'Oyuncu'**
  String get defaultPlayerName;

  /// No description provided for @homePlayButton.
  ///
  /// In tr, this message translates to:
  /// **'OYNA'**
  String get homePlayButton;

  /// No description provided for @homeAssistedMode.
  ///
  /// In tr, this message translates to:
  /// **'Yardımlı Mod'**
  String get homeAssistedMode;

  /// No description provided for @homeUnassistedMode.
  ///
  /// In tr, this message translates to:
  /// **'Yardımsız Mod'**
  String get homeUnassistedMode;

  /// No description provided for @homeNewGameDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Oyun Başlatılsın mı?'**
  String get homeNewGameDialogTitle;

  /// No description provided for @homeNewGameDialogContent.
  ///
  /// In tr, this message translates to:
  /// **'Devam eden bir oyununuz var. Yeni oyuna başlarsanız mevcut oyun ve puan durumu sıfırlanacaktır.'**
  String get homeNewGameDialogContent;

  /// No description provided for @homeNewGameDialogCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get homeNewGameDialogCancel;

  /// No description provided for @homeNewGameDialogConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Oyuna Başla'**
  String get homeNewGameDialogConfirm;

  /// No description provided for @homeTooltipRules.
  ///
  /// In tr, this message translates to:
  /// **'Kurallar'**
  String get homeTooltipRules;

  /// No description provided for @homeTooltipSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get homeTooltipSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Oyun Ayarları'**
  String get settingsTitle;

  /// No description provided for @settingsClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get settingsClose;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In tr, this message translates to:
  /// **'🌐 DİL SEÇİMİ / LANGUAGE'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageTr.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get settingsLanguageTr;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @settingsGameModeSection.
  ///
  /// In tr, this message translates to:
  /// **'🎮 OYUN MODU'**
  String get settingsGameModeSection;

  /// No description provided for @settingsAssistedTitle.
  ///
  /// In tr, this message translates to:
  /// **'✨ Yardımlı Mod (Tavsiye Edilen)'**
  String get settingsAssistedTitle;

  /// No description provided for @settingsAssistedDesc.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli perleriniz (✓) ve elinizdeki toplam ceza sayısı canlı gösterilir. Otomatik per kontrolü açıktır.'**
  String get settingsAssistedDesc;

  /// No description provided for @settingsUnassistedTitle.
  ///
  /// In tr, this message translates to:
  /// **'🔥 Yardımsız Usta Modu'**
  String get settingsUnassistedTitle;

  /// No description provided for @settingsUnassistedDesc.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbir per veya ceza ipucu verilmez! Saf tecrübe ve dikkat. Hatalı el açan oyuncu direkt 101 puan ile yanar.'**
  String get settingsUnassistedDesc;

  /// No description provided for @settingsSoundSection.
  ///
  /// In tr, this message translates to:
  /// **'🔊 SES & TİTREŞİM'**
  String get settingsSoundSection;

  /// No description provided for @settingsSoundEffects.
  ///
  /// In tr, this message translates to:
  /// **'Kart ve Oyun Sesleri'**
  String get settingsSoundEffects;

  /// No description provided for @settingsVibration.
  ///
  /// In tr, this message translates to:
  /// **'Titreşim Bildirimleri'**
  String get settingsVibration;

  /// No description provided for @settingsProfileSection.
  ///
  /// In tr, this message translates to:
  /// **'👤 OYUNCU PROFİLİ'**
  String get settingsProfileSection;

  /// No description provided for @settingsPlayerNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Oyuncu Adı'**
  String get settingsPlayerNameLabel;

  /// No description provided for @settingsSaveButton.
  ///
  /// In tr, this message translates to:
  /// **'KAYDET VE DÖN'**
  String get settingsSaveButton;

  /// No description provided for @rulesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl Oynanır? (Kurallar)'**
  String get rulesTitle;

  /// No description provided for @rulesClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get rulesClose;

  /// No description provided for @rulesUnderstandButton.
  ///
  /// In tr, this message translates to:
  /// **'ANLADIM'**
  String get rulesUnderstandButton;

  /// No description provided for @rulesSection1Title.
  ///
  /// In tr, this message translates to:
  /// **'🃏 1. Deste, Dağıtım ve Kart Çekme'**
  String get rulesSection1Title;

  /// No description provided for @rulesSection1Body.
  ///
  /// In tr, this message translates to:
  /// **'• Oyun 2 tam deste (104 kart) + 2 Fiziksel Joker olmak üzere toplam 106 kağıtla oynanır.\n• Her oyuncuya 10\'ar kart dağıtılır.\n• Kart çekme YALNIZCA ortadaki kapalı desteden yapılır. Yanık İskambil\'de yerden kart çekilemez.'**
  String get rulesSection1Body;

  /// No description provided for @rulesSection2Title.
  ///
  /// In tr, this message translates to:
  /// **'👑 2. Jokerler (Gösterge & Fiziksel Joker)'**
  String get rulesSection2Title;

  /// No description provided for @rulesSection2Body.
  ///
  /// In tr, this message translates to:
  /// **'• Dağıtım sonunda açılan Gösterge kartının sayı değeri o turun \"Gösterge Jokeri\" olur.\n• Her iki destedeki bu sayıdaki tüm kartlar (8 adet) ve 2 Fiziksel Joker ile toplam 10 joker bulunur.\n• Jokerler her per ve seride eksik kart yerine geçebilir.\n• 3 veya daha fazla Joker tek başına bağımsız bir per oluşturabilir.\n• DİKKAT: Tur sonunda per yapamayıp elinizde boşta kalan her Joker tam 25 ceza puanı yazar!'**
  String get rulesSection2Body;

  /// No description provided for @rulesSection3Title.
  ///
  /// In tr, this message translates to:
  /// **'📐 3. Geçerli Perler (Setler ve Seriler)'**
  String get rulesSection3Title;

  /// No description provided for @rulesSection3Body.
  ///
  /// In tr, this message translates to:
  /// **'Kartlar en az 3\'erli gruplar halinde per yapılabilir:\n• Grup Per (Set): Aynı sayı değerine sahip, FARKLI sembollerde en az 3 veya 4 kart (Örn: ♠K, ♦K, ♣K veya ♥8, ♠8, ♦8, ♣8). Aynı renkten çift kart aynı sete konulamaz.\n• Seri Per (Run): Aynı sembolde ardışık en az 3 kart (Örn: ♥7, ♥8, ♥9, ♥10).\n• As (A): Serinin başında (A-2-3) veya sonunda (J-Q-K-A) yer alabilir; ancak döngüsel olamaz (K-A-2 geçersizdir).'**
  String get rulesSection3Body;

  /// No description provided for @rulesSection4Title.
  ///
  /// In tr, this message translates to:
  /// **'🏆 4. El Açma ve Bitiş Kuralları'**
  String get rulesSection4Title;

  /// No description provided for @rulesSection4Body.
  ///
  /// In tr, this message translates to:
  /// **'• Turunuzda kapalı desteden 1 kart çekerek 11 karta ulaşırsınız.\n• Elinizdeki 10 kartı geçerli perler halinde bağlayıp 11. kartı masaya atarak \"EL AÇ / BİTİR\" yapabilirsiniz.\n• Eli meşru açıp bitiren oyuncu o turda 0 CEZA PUANI alır.\n• Diğer oyuncular ise per yapamadıkları boşta kalan kartlarının ceza puanlarını alır.'**
  String get rulesSection4Body;

  /// No description provided for @rulesSection5Title.
  ///
  /// In tr, this message translates to:
  /// **'💡 5. Örnek Kazanan El Senaryosu'**
  String get rulesSection5Title;

  /// No description provided for @rulesSection5Body.
  ///
  /// In tr, this message translates to:
  /// **'10 meldelenmiş kart + 1 atılacak kart:\n• 1. Istaka Sırası: [♠8, ♥8, ♦8] (3\'lü Grup Per)\n• 2. Istaka Sırası: [♣4, ♣5, ♣6, ♣7] (4\'lü Seri Per)\n• 3. Istaka Sırası: [♥J, ♥Q, ♥K] (3\'lü Seri Per)\n• Masaya Atılacak Kart: [♦2] (Boşta kalan 11. kart)\nSonuç: 10 kart perlere bağlı, 11. kart masaya atılarak el başarıyla biter!'**
  String get rulesSection5Body;

  /// No description provided for @rulesSection6Title.
  ///
  /// In tr, this message translates to:
  /// **'✨ 6. Yardımlı Mod vs 🔥 Yardımsız Mod'**
  String get rulesSection6Title;

  /// No description provided for @rulesSection6Body.
  ///
  /// In tr, this message translates to:
  /// **'• Yardımlı Mod: Perleriniz yeşil etiketlerle (✓ PER) ve elinizdeki anlık ceza puanı otomatik gösterilir. Bitiş için en uygun atılacak kart sistem tarafından desteklenir.\n• Yardımsız Mod: Hiçbir per veya ceza ipucu verilmez! Istakanızdaki sıralama tamamen sizin dikkatinize aittir.\n• ÖNEMLİ (Hatalı Açma Riski): Yardımsız modda eliniz geçerli olmadan hatalı el açarsanız DİREKT 101 CEZA ile yanarsınız; diğer tüm oyuncular 0 ceza alır!'**
  String get rulesSection6Body;

  /// No description provided for @rulesSection7Title.
  ///
  /// In tr, this message translates to:
  /// **'🔢 7. Ceza Puanları ve 101 Barajı'**
  String get rulesSection7Title;

  /// No description provided for @rulesSection7Body.
  ///
  /// In tr, this message translates to:
  /// **'Per yapılmayan boşta kalan kartların ceza değerleri:\n• As (A) = 10 puan\n• Papaz (K), Kız (Q), Vale (J) = 10 puan\n• 2 .. 10 = Kartın kendi rakam değeri\n• Joker = 25 puan\n• Toplam ceza puanı 101 veya üzerine çıkan oyuncu YANAR ve masadan elenir. Elenen oyuncular turlarda pas geçilir.'**
  String get rulesSection7Body;

  /// No description provided for @rulesSection8Title.
  ///
  /// In tr, this message translates to:
  /// **'🔄 8. Deste Tükenmesi (Beraberlik)'**
  String get rulesSection8Title;

  /// No description provided for @rulesSection8Body.
  ///
  /// In tr, this message translates to:
  /// **'• 106 kağıtlık kapalı çekme destesi tamamen biter ve kimse elini açamamışsa tur berabere tamamlanır.\n• Tüm oyuncular ellerindeki per dışı kartların ceza puanlarını hanelerine yazdırır.'**
  String get rulesSection8Body;

  /// No description provided for @rulesSection9Title.
  ///
  /// In tr, this message translates to:
  /// **'🥇 9. Masanın Şampiyonu'**
  String get rulesSection9Title;

  /// No description provided for @rulesSection9Body.
  ///
  /// In tr, this message translates to:
  /// **'• Yanık İskambil hayatta kalma oyunudur. Rakipler 101 ceza barajını aşarak elendikçe oyun devam eder.\n• Masada ayakta kalan son oyuncu oyunun ŞAMPİYONU olur!'**
  String get rulesSection9Body;

  /// No description provided for @tableTooltipLeave.
  ///
  /// In tr, this message translates to:
  /// **'Masadan Ayrıl'**
  String get tableTooltipLeave;

  /// No description provided for @tableTooltipScoresheet.
  ///
  /// In tr, this message translates to:
  /// **'101 Skor Tablosu'**
  String get tableTooltipScoresheet;

  /// No description provided for @tableTooltipSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get tableTooltipSettings;

  /// No description provided for @tableRoundBadge.
  ///
  /// In tr, this message translates to:
  /// **'El {roundNumber}'**
  String tableRoundBadge(int roundNumber);

  /// No description provided for @tableModeAssisted.
  ///
  /// In tr, this message translates to:
  /// **'Yardımlı'**
  String get tableModeAssisted;

  /// No description provided for @tableModeUnassisted.
  ///
  /// In tr, this message translates to:
  /// **'Yardımsız'**
  String get tableModeUnassisted;

  /// No description provided for @tableIndicator.
  ///
  /// In tr, this message translates to:
  /// **'GÖSTERGE'**
  String get tableIndicator;

  /// No description provided for @tableDeckCount.
  ///
  /// In tr, this message translates to:
  /// **'DESTE {count}'**
  String tableDeckCount(int count);

  /// No description provided for @tableDrawNow.
  ///
  /// In tr, this message translates to:
  /// **'👇 ÇEK ({count})'**
  String tableDrawNow(int count);

  /// No description provided for @tableDiscardLabel.
  ///
  /// In tr, this message translates to:
  /// **'ATILAN'**
  String get tableDiscardLabel;

  /// No description provided for @tableDiscardPile.
  ///
  /// In tr, this message translates to:
  /// **'ATILAN KART'**
  String get tableDiscardPile;

  /// No description provided for @tableBtnDraw.
  ///
  /// In tr, this message translates to:
  /// **'DESTEDEN\nÇEK'**
  String get tableBtnDraw;

  /// No description provided for @tableBtnAutoMeld.
  ///
  /// In tr, this message translates to:
  /// **'OTOMATİK\nPER DİZ'**
  String get tableBtnAutoMeld;

  /// No description provided for @tableBtnSortRank.
  ///
  /// In tr, this message translates to:
  /// **'SAYIYA GÖRE\nSIRALA'**
  String get tableBtnSortRank;

  /// No description provided for @tableBtnDiscard.
  ///
  /// In tr, this message translates to:
  /// **'KAĞIDI\nAT'**
  String get tableBtnDiscard;

  /// No description provided for @tableBtnDeclareFinish.
  ///
  /// In tr, this message translates to:
  /// **'EL AÇ\nBİTİR'**
  String get tableBtnDeclareFinish;

  /// No description provided for @tableRackUnassisted.
  ///
  /// In tr, this message translates to:
  /// **'🔥 Yardımsız Mod'**
  String get tableRackUnassisted;

  /// No description provided for @tableRackReadyToFinish.
  ///
  /// In tr, this message translates to:
  /// **'✨ El Açmaya Hazır'**
  String get tableRackReadyToFinish;

  /// No description provided for @tableRackPenaltyPoints.
  ///
  /// In tr, this message translates to:
  /// **'Ceza: {points} Puan'**
  String tableRackPenaltyPoints(int points);

  /// No description provided for @tableRackSelected.
  ///
  /// In tr, this message translates to:
  /// **'Seçili: {card}'**
  String tableRackSelected(String card);

  /// No description provided for @tableCardBadgeFinish.
  ///
  /// In tr, this message translates to:
  /// **'AT & AÇ'**
  String get tableCardBadgeFinish;

  /// No description provided for @tablePlayerYouSuffix.
  ///
  /// In tr, this message translates to:
  /// **' (Sen)'**
  String get tablePlayerYouSuffix;

  /// No description provided for @tablePlayerWon.
  ///
  /// In tr, this message translates to:
  /// **'KAZANDI'**
  String get tablePlayerWon;

  /// No description provided for @tablePlayerBust.
  ///
  /// In tr, this message translates to:
  /// **'YANDI ({score})'**
  String tablePlayerBust(int score);

  /// No description provided for @tablePlayerPenalty.
  ///
  /// In tr, this message translates to:
  /// **'Ceza: {score}'**
  String tablePlayerPenalty(int score);

  /// No description provided for @tableLeaveDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Masadan Çıkılsın mı?'**
  String get tableLeaveDialogTitle;

  /// No description provided for @tableLeaveDialogContent.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut oyun sonlandırılacak ve ana menüye dönülecektir.'**
  String get tableLeaveDialogContent;

  /// No description provided for @tableLeaveDialogCancel.
  ///
  /// In tr, this message translates to:
  /// **'İPTAL'**
  String get tableLeaveDialogCancel;

  /// No description provided for @tableLeaveDialogConfirm.
  ///
  /// In tr, this message translates to:
  /// **'ÇIK'**
  String get tableLeaveDialogConfirm;

  /// No description provided for @tableFalseFinishDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hatalı El Açma Uyarısı'**
  String get tableFalseFinishDialogTitle;

  /// No description provided for @tableFalseFinishDialogContent.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz el açarsanız 101 ceza alacaksınız. Devam etmek istiyor musunuz?'**
  String get tableFalseFinishDialogContent;

  /// No description provided for @tableFalseFinishDialogCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get tableFalseFinishDialogCancel;

  /// No description provided for @tableFalseFinishDialogConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get tableFalseFinishDialogConfirm;

  /// No description provided for @tableNotReadySnackBar.
  ///
  /// In tr, this message translates to:
  /// **'Eliniz henüz bitişe hazır değil.'**
  String get tableNotReadySnackBar;

  /// No description provided for @tableDiscardSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Atılacak Kartı Seçin'**
  String get tableDiscardSheetTitle;

  /// No description provided for @tableDiscardSheetDesc.
  ///
  /// In tr, this message translates to:
  /// **'Elinizi açıp bitirmek için masaya atmak istediğiniz kartı seçin:'**
  String get tableDiscardSheetDesc;

  /// No description provided for @tableDiscardSheetCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get tableDiscardSheetCancel;

  /// No description provided for @tableRecentDiscardsTitle.
  ///
  /// In tr, this message translates to:
  /// **'🗑️ Yere Atılan Son Kağıtlar'**
  String get tableRecentDiscardsTitle;

  /// No description provided for @tableRecentDiscardsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu elde henüz yere kağıt atılmadı.'**
  String get tableRecentDiscardsEmpty;

  /// No description provided for @tableScoresheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'📝 OYUN ÇETELESİ (101 CEZA TABLOSU)'**
  String get tableScoresheetTitle;

  /// No description provided for @tableScoresheetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'El #{roundNumber} • {mode}'**
  String tableScoresheetSubtitle(int roundNumber, String mode);

  /// No description provided for @tableScoresheetColRound.
  ///
  /// In tr, this message translates to:
  /// **'EL'**
  String get tableScoresheetColRound;

  /// No description provided for @tableScoresheetEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz el tamamlanmadı. İlk el bittiğinde cezalar buraya yazılacaktır.'**
  String get tableScoresheetEmpty;

  /// No description provided for @tableScoresheetRoundLabel.
  ///
  /// In tr, this message translates to:
  /// **'{roundNumber}. El'**
  String tableScoresheetRoundLabel(int roundNumber);

  /// No description provided for @tableScoresheetDeclared.
  ///
  /// In tr, this message translates to:
  /// **'AÇTI'**
  String get tableScoresheetDeclared;

  /// No description provided for @tableScoresheetTotal.
  ///
  /// In tr, this message translates to:
  /// **'TOPLAM'**
  String get tableScoresheetTotal;

  /// No description provided for @tableScoresheetBust.
  ///
  /// In tr, this message translates to:
  /// **'YANDI'**
  String get tableScoresheetBust;

  /// No description provided for @summaryTitleGameOver.
  ///
  /// In tr, this message translates to:
  /// **'🏆 OYUN BİTTİ'**
  String get summaryTitleGameOver;

  /// No description provided for @summaryTitleRoundResult.
  ///
  /// In tr, this message translates to:
  /// **'📊 TUR {roundNumber} SONUCU'**
  String summaryTitleRoundResult(int roundNumber);

  /// No description provided for @summaryPlayerDeclared.
  ///
  /// In tr, this message translates to:
  /// **'✨ Eli Açtı (0 Ceza)'**
  String get summaryPlayerDeclared;

  /// No description provided for @summaryPlayerFalseFinish.
  ///
  /// In tr, this message translates to:
  /// **'❌ Hatalı El Açma (101 Ceza)'**
  String get summaryPlayerFalseFinish;

  /// No description provided for @summaryPlayerUnmeldedCards.
  ///
  /// In tr, this message translates to:
  /// **'{count, plural, =1{Boşta: 1 kağıt} other{Boşta: {count} kağıt}}'**
  String summaryPlayerUnmeldedCards(int count);

  /// No description provided for @summaryPlayerBust.
  ///
  /// In tr, this message translates to:
  /// **'🔥 YANDI ({score})'**
  String summaryPlayerBust(int score);

  /// No description provided for @summaryPlayerTotalScore.
  ///
  /// In tr, this message translates to:
  /// **'Toplam: {score} / 101'**
  String summaryPlayerTotalScore(int score);

  /// No description provided for @summaryMeldBadge.
  ///
  /// In tr, this message translates to:
  /// **'PER {meldNumber}'**
  String summaryMeldBadge(int meldNumber);

  /// No description provided for @summaryDeadwoodBadge.
  ///
  /// In tr, this message translates to:
  /// **'BOŞTA ({count})'**
  String summaryDeadwoodBadge(int count);

  /// No description provided for @summaryBtnMainMenu.
  ///
  /// In tr, this message translates to:
  /// **'ANA MENÜ'**
  String get summaryBtnMainMenu;

  /// No description provided for @summaryBtnPlayAgain.
  ///
  /// In tr, this message translates to:
  /// **'TEKRAR OYNA 🏆'**
  String get summaryBtnPlayAgain;

  /// No description provided for @summaryBtnContinue.
  ///
  /// In tr, this message translates to:
  /// **'DEVAM ET ➜'**
  String get summaryBtnContinue;

  /// No description provided for @celebrationTableChampion.
  ///
  /// In tr, this message translates to:
  /// **'MASA ŞAMPİYONU'**
  String get celebrationTableChampion;

  /// No description provided for @celebrationRoundWinner.
  ///
  /// In tr, this message translates to:
  /// **'ELİ AÇTI VE BİTİRDİ'**
  String get celebrationRoundWinner;

  /// No description provided for @celebrationBotFinished.
  ///
  /// In tr, this message translates to:
  /// **'{winnerName} BİTİRDİ'**
  String celebrationBotFinished(String winnerName);

  /// No description provided for @celebrationChampionDesc.
  ///
  /// In tr, this message translates to:
  /// **'Tebrikler! Masayı 1. Olarak Tamamladınız!'**
  String get celebrationChampionDesc;

  /// No description provided for @celebrationHumanRoundDesc.
  ///
  /// In tr, this message translates to:
  /// **'Harika El! 0 Ceza Puanı'**
  String get celebrationHumanRoundDesc;

  /// No description provided for @celebrationBotRoundDesc.
  ///
  /// In tr, this message translates to:
  /// **'{winnerName} Turu 0 Ceza İle Kazandı'**
  String celebrationBotRoundDesc(String winnerName);

  /// No description provided for @celebrationTapToSkip.
  ///
  /// In tr, this message translates to:
  /// **'Kutlamayı geçmek için dokunun'**
  String get celebrationTapToSkip;

  /// No description provided for @gameOverTitleChampion.
  ///
  /// In tr, this message translates to:
  /// **'🏆 ŞAMPİYON! 🏆'**
  String get gameOverTitleChampion;

  /// No description provided for @gameOverTitleBust.
  ///
  /// In tr, this message translates to:
  /// **'🔥 OYUN BİTTİ'**
  String get gameOverTitleBust;

  /// No description provided for @championHumanMessage.
  ///
  /// In tr, this message translates to:
  /// **'Tebrikler! Masayı Şampiyon Olarak Tamamladınız! 🏆'**
  String get championHumanMessage;

  /// No description provided for @championBotMessage.
  ///
  /// In tr, this message translates to:
  /// **'{name} Şampiyon Oldu!'**
  String championBotMessage(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
