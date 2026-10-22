# Yanık İskambil VIP - Çevrimdışı (Play Store Sürümü)

Bu proje, popüler Türk iskambil oyunu **Yanık (Yunan Yanığı)**'nın Google Play Store için özel olarak optimize edilmiş, **%100 Çevrimdışı (Offline)** çalışan sürümüdür.

---

## 🌟 Öne Çıkan Özellikler

1. **Tamamen Çevrimdışı (Offline) Mimari**:
   - İnternet bağlantısı, sunucu veya veritabanı gerektirmez.
   - Metroda, uçakta veya çekmeyen yerlerde kesintisiz oyun keyfi sunar.
2. **Sade ve Hızlı Ana Menü**:
   - Karmaşık ve gereksiz online menülerden (odalar, krediler, arkadaşlar, sohbet) arındırılmıştır.
   - Sadece **OYNA** butonu ve Ayarlar mevcuttur.
3. **Ayarlarda Mod Seçimi**:
   - **✨ Yardımlı Mod (Tavsiye Edilen)**: Otomatik per vurgulama (✓) ve eldeki ceza puanı canlı gösterilir.
   - **🔥 Yardımsız Usta Modu**: Sıfır ipucu ve ceza göstergesi. Yanlış el açan oyuncu doğrudan 101 ceza ile yanar!
4. **1 İnsan + 3 Akıllı Bot (4 Kişilik Masa)**:
   - Botlar gerçekçi düşünme süreleriyle (1-1.2 sn) yerden kart çeker, bitiş taraması yapar ve optimum gereksiz kağıtları atar.
5. **Süresiz El Sonu (Showdown)**:
   - Tur bittiğinde hiçbir geri sayım veya zorunlu süre yoktur.
   - 4 oyuncunun perleri, unmelded kartları ve ceza puanları anında listelenir.
   - Oyuncu hazır hissettiğinde **"DEVAM ET"** butonuna basarak bir sonraki tura geçer.
6. **Monetizasyon (Google AdMob)**:
   - Her turun sonunda "Devam Et" butonuna basıldığında Geçiş Reklamı (Interstitial Ad) oynatılır.
   - Çevrimdışıyken veya reklam yüklenemediğinde oyunu bekletmez, akıcı şekilde tura devam eder.

---

## 🛠️ Kurulum ve Çalıştırma

### Bağımlılıkları İndirme
```bash
flutter pub get
```

### Kod Analizi ve Testler
```bash
flutter analyze
flutter test
```

### Uygulamayı Çalıştırma
```bash
flutter run
```

### APK Derleme (Play Store / Test)
```bash
flutter build apk --release
```

---

## 🏷️ Google AdMob Canlı Reklam ID Değişimi

Uygulama şu anda geliştirme ve test amacıyla Google'ın resmi Test ID'leri ile yapılandırılmıştır.

Play Store'da kendi reklam gelirlerinizi kazanmak için aşağıdaki 2 yerde kendi AdMob ID'lerinizi tanımlayabilirsiniz:

1. **Android App ID**:
   - Dosya: `android/app/src/main/AndroidManifest.xml`
   - Satır: `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-XXXXXXXXXXXX~YYYYYYYYYY"/>`

2. **Geçiş Reklamı (Interstitial) ID**:
   - Dosya: `lib/services/ad_service.dart`
   - Sabit: `_androidDefaultInterstitialId = 'ca-app-pub-XXXXXXXXXXXX/ZZZZZZZZZZ';`
