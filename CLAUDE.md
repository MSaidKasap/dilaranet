# Dilara Flutter Uygulaması — Proje Notları

Bu dosya, projede çalışırken edinilen bağlamı ve **tekrarlanmaması gereken
hataları** kayıt altına tutar. Yeni bir oturuma başlarken önce bunu oku.

## İlerleme (özet, en son değişiklikler üstte)

- **Xcode Cloud build kuralı:** `main`'e push, "Code push" start condition'ı
  ile otomatik bir Xcode Cloud build'i tetikliyor ve App Store Connect'e
  yüklüyor. `pubspec.yaml`'daki `version: X.Y.Z+N`'de **N (build numarası)
  her push'tan önce artırılmalı** — aksi halde Apple aynı numarayı ikinci
  kez kabul etmez ve build "Preparing build for App Store Connect failed"
  ile başarısız olur (bunu 3 kez art arda unutup 3 başarısız build'e sebep
  oldum). `ITSAppUsesNonExemptEncryption: false` `Info.plist`'e eklendi
  (uygulama sadece standart HTTPS kullanıyor) — export compliance sorusu
  bir daha çıkmamalı.
- **Sunucu altyapısı:** `cdn.dilara.net`'in Let's Encrypt sertifikası süresi
  dolmuştu (27 Tem 2026'da bitmiş, Plesk'in içindeki bozuk/eski bir ACME
  order kaydı yüzünden otomatik yenilenememiş — bkz. "Sunucuya erişim").
  `/opt/psa/var/modules/letsencrypt/orders/` altındaki ilgili stale order
  JSON'u yedeklenip silindi, `plesk bin extension --exec letsencrypt
  cli.php -d cdn.dilara.net -m ...` ile yeniden verildi ve doğrulandı. Bu,
  indirme ekranındaki "CERTIFICATE_VERIFY_FAILED" hatasının kök nedeniydi.
  **Ders:** Bu hatayı görürsen önce `openssl s_client -connect
  <host>:443 -servername <host>` ile sertifika `notAfter` tarihini kontrol
  et — uygulama kodunda arama, çoğunlukla sertifika/altyapı sorunudur.
- **iOS/Android ana ekran widget'ı** (namaz vakitleri) v3'e hiç
  taşınmamıştı: v2 (`lib/core/pages/prayer_times_page.dart`) her vakit
  yüklendiğinde `net.dilara.social/widget` MethodChannel'ı ile
  `savePrayerTimes` çağırıp App Group/SharedPreferences'a yazıyor ve
  `WidgetCenter.reloadAllTimelines()` tetikliyordu; v3'ün
  `V3PrayerRepository`si bunu hiç çağırmıyordu. `_syncWidget()` olarak
  `lib/v3/data/prayer.dart`'a taşındı, `load()` içinde (hem cache hem taze
  veri yolunda) çağrılıyor.
- Karanlık tema tam olarak çalışıyor: `V3Theme.dark()` +
  `MaterialApp(themeMode: ThemeMode.system)`. `V3Colors` (`theme.dart`)
  artık `static const` değil, `WidgetsBinding...platformBrightness`'a göre
  açık/koyu döndüren **getter**'lar (`scaffold`, `surface`, `border`,
  `textPrimary`, `textMuted`, `shadow`) — `primary` marka rengi olduğu için
  sabit kaldı. Bu değişiklik ~37 dosyada `const TextStyle/Icon/BoxDecoration`
  gibi yerlerin çoğunun `const` anahtar kelimesini kaybetmesini gerektirdi
  (derleyicinin `invalid_constant` hatalarını tek tek takip ederek
  düzeltildi — bkz. `git log`). **Yeni bir widget yazarken:** `V3Colors.xxx`
  (primary hariç) bir `const` ifadenin içinde kullanılamaz; o widget/stil
  çağrısından `const` kaldırılmalı.
- Namaz bildirimi ayarları v2'deki gibi ayrıntılı hale getirildi: yeni
  `lib/v3/pages/prayer_notification_settings_page.dart` (genel aç/kapa,
  önce/sonra süre presetleri, vakit başına aç/kapa + sessiz bildirim).
  `V3PrayerRepository` (`lib/v3/data/prayer.dart`) artık bu ayarları
  saklıyor ve `rescheduleAll()` ile bugün+yarın için toplu zamanlıyor
  (`NotificationService.scheduleForDay`). Erişim: Bildirimler sekmesi ve
  Namaz sekmesindeki ayarlar ikonu.
- Kitaplar yeniden düzenlendi: "Bölümler" sekmesinden kitap şeridi
  kaldırıldı; ana sayfadaki 2 kitaplık kısayol artık 3 kitabın tamamını
  aynı (gradyanlı buton) formatta, `compact: true` ile küçültülmüş
  gösteriyor (`V3BookShortcut`, `lib/v3/widgets/book_card.dart`). Profil >
  Market bölümünün altına yeni bir "Kitaplar" kısayolu eklendi
  (`lib/v3/pages/books_page.dart`).
- Adres defteri sunucu tarafına taşındı: `mobileapi.php`'ye `addresses`,
  `addressSave`, `addressDelete` eklenip production'a deploy edildi (bkz.
  "Sunucuya erişim" bölümü). Checkout artık kayıtlı adresi gösterip
  "Düzenle"/"Devam Et" sunuyor; profilde "Adreslerim" sayfası var.
- Sepet/oturum/para birimi/HTML açıklama düzeltmeleri: bkz. "Bilinen
  tuhaflıklar" ve "Tekrar tekrar yapılan hata" bölümleri aşağıda.

## Proje yapısı

- `lib/core/*` — eski (v2) WordPress tabanlı ekranlar. Dokunulmuyor, sadece
  bazı yardımcıları (`html_character_entities` kullanımı gibi) referans
  alınıyor.
- `lib/v3/*` — aktif geliştirilen yeni arayüz.
  - `lib/v3/data/` — API istemcileri ve modeller.
  - `lib/v3/pages/` — ekranlar; `pages/market/` OpenCart entegrasyonu.
  - `lib/v3/widgets/` — paylaşılan bileşenler (`V3AppBar`, `V3CartIconButton`).
- Global state için dış paket yok; `MarketAuth.customer`,
  `MarketApi.cartCount` gibi **singleton + `ValueNotifier`** deseni
  kullanılıyor. Yeni global state eklerken aynı deseni izle.

## Backend: dilarayayinlari.com (OpenCart 3.0.3.2)

Uygulama iki tür uç nokta kullanır:

1. **Özel `mobileapi` eklentisi** — sunucuda
   `catalog/controller/extension/module/mobileapi.php`
   (`index.php?route=extension/module/mobileapi/<action>`). Bu dosya **bu
   repoda yok** (PHP backend, ayrı bir sunucuda). Kaynağı incelemek/değiştirmek
   gerekirse SSH ile çekilmeli (aşağıya bakınız).
   Uçlar: `categories`, `products`, `product`, `register`, `login`, `logout`,
   `me`, `cart`, `addresses`, `addressSave`, `addressDelete`,
   `shippingQuotes`, `paymentQuotes`, `paytrToken`, `orders`, `orderDetail`.
2. **Standart OpenCart storefront rotaları** — sepet/checkout mutasyonları
   için: `checkout/cart/add`, `checkout/cart/edit`, `checkout/cart/remove`,
   `checkout/shipping_address/save`, `checkout/payment_address/save`,
   `checkout/shipping_method/save`, `checkout/payment_method/save`,
   `checkout/confirm`. Bunlar JSON API olarak tasarlanmadı, bazıları HTML/
   redirect döner (aşağıdaki "Bilinen tuhaflıklar" kısmına bak).
3. **İl/zone listesi** sitenin "QuickCheckout" eklentisinden geliyor:
   `extension/quickcheckout/checkout/country&country_id=215` — auth
   gerektirmiyor, Türkiye'nin 81 ilini `zone_id` ile birlikte JSON döner.
   Adres formundaki şehir seçimi buradan besleniyor, statik liste tutulmuyor.

### Sunucuya erişim

- SSH anahtarı: `~/.ssh/dilara360_deploy` → `root@panel.dilarabilgisayar.tr`.
- Site kökü: `/var/www/vhosts/dilarayayinlari.com/httpdocs/`.
- **ÖNEMLİ GÜVENLİK BAĞLAMI:** Bu sunucu 16 Ağustos–4 Eylül 2026 arasında
  ciddi şekilde ele geçirilmişti (webshell, sahte admin, backdoor — 4 farklı
  site + ERP). Tam rapor: `~/Desktop/dilara-adli-rapor-2026-09-04.md`.
  `dilarayayinlari.com` aynı paylaşımlı Linux kullanıcısını (24 alan adı)
  paylaşıyor. **Her production dosya değişikliğinde:**
  1. Önce mevcut dosyayı indirip elindeki kopyayla `diff`'le (aradan
     başkası değiştirmiş mi kontrol et).
  2. `cp -p dosya dosya.bak-$(date +%Y%m%d-%H%M%S)` ile yedek al.
  3. Yeni dosyayı yükledikten sonra sunucunun kendi `php -l`'i ile
     sözdizimini doğrula.
  4. Sahiplik/izinleri koru (`chown <site_kullanıcısı>:psacln`, `644`).
  5. Deploy sonrası ilgili uç noktaları `curl` ile test et (en azından
     404→401 gibi beklenen davranış değişikliğini doğrula).
  6. **Asla kullanıcıya sormadan production'a deploy etme** — özellikle bu
     sunucunun yakın geçmişte ihlal edildiği göz önüne alınırsa.

### Bilinen tuhaflıklar (zaman kaybettirmesin diye not edildi)

- `extension/module/mobileapi/logout` **sadece GET** kabul ediyor; POST 403
  ile reddediliyor (PHP'ye hiç ulaşmıyor — WAF/route seviyesinde).
- `checkout/cart/edit` (miktar güncelleme) klasik bir form-submit rotası;
  JSON değil, 302 redirect + HTML döner. Güncelleme sonrası sepeti ayrıca
  `cart()` ile yeniden çekmek gerekir.
- `product.description` alanı **çift HTML-encode** geliyor
  (`&lt;p style=&quot;...&quot;&gt;`). `HtmlWidget`'a vermeden önce mutlaka
  `HtmlCharacterEntities.decode()` uygulanmalı, yoksa etiketler kullanıcıya
  düz metin olarak görünür.
- Fiyat/tutar metinleri backend'den `₺180,00` gibi sembol solda formatlanmış
  gelir. Unicode `₺` (U+20BA) uygulamanın fontlarında (ör. Google Fonts PT
  Serif) güvenilir şekilde bulunmuyor ve yanlış bir glif çiziliyor — font
  fallback denemeleri de platform bağımlılığı yüzünden kırılgan çıktı.
  Çözüm: `market_models.dart`'taki `_formatPrice()` sembolü tamamen kaldırıp
  düz metin `"<tutar> TL"` üretiyor. Yeni bir yerde tutar göstereceksen bu
  fonksiyonu kullan, ham `₺` karakterini asla ekrana basma.
- Sepet/oturum çerezi (`OCSESSID`) diske kalıcı yazılıyor
  (`PersistCookieJar` + `FileStorage`, bkz. `market_api.dart`). Bellekte
  tutulan `CookieJar()`'a asla geri dönme — hot restart/uygulama kapat-aç'ta
  sepet sıfırlanır.

## Tekrar TEKRAR yapılan hata: `setState` içine `Future` ataması

Bu oturumda **üç ayrı kez** aynı hata yapıldı (`cart_page.dart`,
`bookmarks_page.dart`, sonra tekrar `address_list_page.dart`,
`checkout_address_page.dart`, `address_form_page.dart`):

```dart
// YANLIŞ — Dart'ta atama ifadesinin değeri, atanan değerin kendisidir.
// _future bir Future<T> olduğu için bu ok fonksiyonu bir Future DÖNDÜRÜR.
setState(() => _future = MarketApi.instance.cart());
```

Flutter bunu debug modda şu hatayla durdurur: *"setState() callback argument
returned a Future."* Doğrusu blok gövde kullanmak (blok gövde her zaman
`null`/`void` döner):

```dart
setState(() {
  _future = MarketApi.instance.cart();
});
```

**Kural:** `setState(() => x = ...)` yazarken, `...` ifadesinin sonucu bir
`Future` (ya da genel olarak `void` olmayan, önemli bir değer) ise **her
zaman** blok gövdeye çevir. Yeni bir `_reload()`/`_refresh()` fonksiyonu
yazarken bunu otomatik kontrol et.

## Diğer genel dersler

- `FutureBuilder` kullanılan her ekranda `snapshot.hasError` **açıkça**
  kontrol edilmeli. Kontrol edilmezse gerçek hatalar sessizce "boş/veri yok"
  durumuna düşer, hem kullanıcı hem geliştirici hatayı asla görmez.
- Yeni bir API bulgusu/varsayımı (ör. bir endpoint'in var olduğu, belirli bir
  formatta veri döndüğü) **canlı `curl` ile doğrulanmadan** koda gömülmemeli
  — bu projede birkaç kez varsayımlar yanlış çıktı (ör. `logout`'un POST
  kabul ettiği varsayımı, adres defteri endpoint'inin zaten var olduğu
  varsayımı).
- PHP backend kaynağı bu repoda yok; üzerinde çalışmak gerekirse SSH ile
  sunucudan çekilip yerelde (scratchpad) düzenlenip, yukarıdaki deploy
  protokolüyle geri yüklenir.
