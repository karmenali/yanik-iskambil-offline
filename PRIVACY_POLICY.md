# Yanık İskambil Offline — Gizlilik Politikası (Privacy Policy)

**Son Güncelleme:** 27 Ekim 2026

Bu Gizlilik Politikası, **Yanık İskambil Offline** ("Uygulama") mobil uygulamasının kullanıcılarına ait verilerin nasıl işlendiğini, hangi üçüncü taraf hizmetlerin kullanıldığını ve kullanıcı haklarını açıklamaktadır.

---

## 1. Genel Bakış ve Çevrimdışı Çalışma Prensibi

Yanık İskambil Offline, tek kişilik ve çevrimdışı oynanabilen bir iskambil oyunudur. 
- Uygulamamız herhangi bir kullanıcı kaydı, hesap oluşturma veya oturum açma gerektirmez.
- Kullanıcıların ad, soyad, e-posta adresi, telefon numarası gibi doğrudan kimliğini tanımlayan kişisel verileri **kesinlikle toplanmaz, sunucularda saklanmaz veya üçüncü taraflarla paylaşılmaz.**
- Oyun ayarları (ses seviyesi, titreşim, yardımlı mod, seçilen avatar ve masa tercihleri) yalnızca kullanıcının kendi cihazında yerel depolama (`SharedPreferences`) kullanılarak saklanır ve cihaz dışına aktarılmaz.

---

## 2. Üçüncü Taraf Reklam Hizmetleri ve Veri İşleme

Uygulama, ücretsiz olarak sunulabilmesi ve bakım maliyetlerinin karşılanması amacıyla üçüncü taraf reklam sağlayıcısı olarak **Google AdMob** (Google LLC) hizmetini kullanmaktadır.

Google AdMob SDK'sı, reklamların sunulması, sıklık sınırlaması (Frequency Capping), reklam sahtekarlığının (ad fraud) önlenmesi ve raporlama amacıyla belirli teknik verileri otomatik olarak toplayabilir ve işleyebilir:

1. **Cihaz ve Diğer Tanımlayıcılar (Device or Other IDs):**
   - Google Reklam Kimliği (Android Google Advertising ID - GAID / iOS IDFV)
   - Cihaz üreticisi, modeli, işletim sistemi sürümü ve ekran boyutu
2. **Uygulama Etkileşim Verileri (App Activity):**
   - Reklam gösterimleri, reklama tıklama veya kapatma olayları
3. **Tanılama Bilgileri (Diagnostics):**
   - Reklam isteklerinin yanıt süreleri ve reklam yükleme hata kodları
4. **Yaklaşık Ağ Bilgisi:**
   - IP adresi (Google AdMob sunucuları tarafından yaklaşık coğrafi bölge tespiti ve ağ güvenliği için aktarım sırasında işlenir; GPS veya kesin konum bilgisi toplanmaz).

Google'ın verileri nasıl işlediği hakkında ayrıntılı bilgi için [Google Gizlilik ve Şartlar](https://policies.google.com/privacy) sayfasını inceleyebilirsiniz.

---

## 3. Rıza Yönetimi (UMP / GDPR / KVKK Uyumu)

Avrupa Ekonomik Alanı (AEA), Birleşik Krallık ve geçerli veri koruma mevzuatlarının geçerli olduğu bölgelerdeki kullanıcılarımız için Google Kullanıcı Mesajlaşma Platformu (**UMP - User Messaging Platform**) entegrasyonu sunulmaktadır:

- Uygulama ilk açıldığında veya yasal gereklilik doğduğunda kullanıcıya rıza tercihlerini belirleyebileceği bir UMP Rıza Formu sunulur.
- Reklam istekleri, yalnızca kullanıcının geçerli izin durumu (`canRequestAds`) doğrultusunda başlatılır. Rıza verilmediği takdirde kişiselleştirilmiş reklam istekleri engellenir.
- Kullanıcılar istedikleri zaman cihazlarının işletim sistemi ayarlarından (Android: *Ayarlar > Google > Reklamlar*, iOS: *Ayarlar > Gizlilik ve Güvenlik*) reklam kimliklerini sıfırlayabilir veya reklam kişiselleştirmesini devre dışı bırakabilirler.

---

## 4. İzinler ve Amaçları

Uygulamamız yalnızca temel işlevler için gereken minimum izinleri kullanır:
- `android.permission.INTERNET`: Yalnızca AdMob reklamlarının ve UMP rıza formunun yüklenmesi için kullanılır.
- `android.permission.ACCESS_NETWORK_STATE`: Reklam isteklerinin yalnızca internet bağlantısı mevcut olduğunda gönderilmesini sağlamak ve çevrimdışı durumda oyunu bekletmemek için ağ durumunu denetler.
- `android.permission.VIBRATE`: Yalnızca oyun sırasında kart çekme, atma ve oyuncu sırası bildirimlerinde dokunsal geri bildirim (haptic feedback) üretmek için kullanılır; herhangi bir veri toplamaz.

Uygulama konum (GPS), kamera, mikrofon, rehber, galeri veya dosya depolama izinleri **talep etmez**.

---

## 5. Çocukların Gizliliği

Uygulamamız 13 yaşın altındaki çocuklara yönelik değildir ve bilerek 13 yaş altı çocuklardan kişisel veri toplamamaktadır.

---

## 6. Google Play Store Veri Güvenliği (Data Safety) Beyan Kılavuzu

Google Play Console'daki "Veri Güvenliği" formunu doldururken aşağıdaki resmi tablo esas alınmalıdır:

| Soru / Kategori | Beyan Durumu | Açıklama |
|---|---|---|
| **Uygulamanız veri topluyor veya paylaşıyor mu?** | **Evet** | Yalnızca entegre edilen Google Mobile Ads (AdMob) SDK'sı aracılığıyla reklam ve analiz verisi işlenir. |
| **Toplanan veriler aktarım sırasında şifreleniyor mu?** | **Evet** | Tüm ağ istekleri HTTPS protokolü üzerinden şifreli aktarılır. |
| **Kullanıcılar için hesap silme seçeneği sunuyor musunuz?** | **Hayır** | Uygulamada üyelik/hesap sistemi bulunmamaktadır; doğrudan çevrimdışı oynanır. |
| **Toplanan Veri Türü: Konum (Location)** | **Hayır** | GPS / kesin konum izni istenmez ve toplanmaz. |
| **Toplanan Veri Türü: Kişisel Bilgiler** | **Hayır** | Ad, e-posta, telefon vb. toplanmaz. |
| **Toplanan Veri Türü: Finansal Bilgiler** | **Hayır** | Uygulama içi satın alma veya ödeme yoktur. |
| **Toplanan Veri Türü: Cihaz veya Diğer Kimlikler** | **Toplanır ve Paylaşılır** | Google Reklam Kimliği (Reklam veya pazarlama, Dolandırıcılığı önleme / Güvenlik). |
| **Toplanan Veri Türü: Uygulama Etkileşimi** | **Toplanır ve Paylaşılır** | Reklam etkileşimleri (Analiz, Reklam veya pazarlama). |
| **Toplanan Veri Türü: Uygulama Bilgileri ve Performans** | **Toplanır ve Paylaşılır** | Hata ve tanılama verileri (Analytics / Diagnostics). |

---

## 7. İletişim

Gizlilik Politikası veya veri uygulamaları hakkında sorularınız için geliştirici e-posta adresi üzerinden iletişime geçebilirsiniz.
