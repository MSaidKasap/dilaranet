# 📖 Dilara — İslami İçerik & Namaz Vakitleri Uygulaması

Flutter tabanlı kapsamlı İslami içerik uygulaması. WordPress'ten dinamik içerik çekme, namaz vakitleri, kitaplar, sesli okuma, bildirimler ve Android ana ekran widget'ları içerir.

---

## 📋 İçindekiler

- [Özellikler](#özellikler)
- [Kurulum](#kurulum)
- [Dosya Yapısı](#dosya-yapısı)
- [WordPress Entegrasyonu](#-wordpress-entegrasyonu)
- [Widget Mimarisi](#widget-mimarisi)
- [Flutter ↔ Android Kanalları](#flutter--android-kanalları)
- [Kullanılan Paketler](#kullanılan-paketler)

---

## ✨ Özellikler

- 📰 **WordPress entegrasyonu** — Post listeleme, kategori ayrımı, detay sayfaları
- 🕌 **Namaz vakitleri** — Konuma göre otomatik hesaplama, Android widget'ları
- 📚 **Kitaplar** — 3 kitap içeriği, bölüm listeleme
- 🔊 **Sesli okuma** — TTS (Text-to-Speech) ve ses dosyası oynatma
- 🎬 **Multimedya** — YouTube player, WebView, in-app browser
- 🔔 **Bildirimler** — Firebase Cloud Messaging (FCM) + Awesome Notifications
- 📍 **Konum** — Geolocator ile otomatik şehir tespiti
- 📡 **Bağlantı kontrolü** — Connectivity Plus ile çevrimdışı yönetimi
- 🌐 **Paylaşım** — Share Plus ile içerik paylaşma

---

## 🚀 Kurulum

### Gereksinimler

- Flutter 3.x+
- Android Studio / VS Code
- Android SDK 26+
- Firebase projesi (FCM + Analytics için)

### Adımlar

```bash
# 1. Repoyu klonla
git clone https://github.com/MSaidKasap/dilaranet
cd dilaranet

# 2. Bağımlılıkları yükle
flutter pub get

# 3. Android için build
flutter build apk

# 4. Çalıştır
flutter run
```

### Firebase Kurulumu

1. [Firebase Console](https://console.firebase.google.com)'dan yeni proje oluştur
2. `google-services.json` dosyasını `android/app/` klasörüne koy
3. FCM ve Analytics'i etkinleştir

### Android İzinleri

`AndroidManifest.xml`'de şu izinlerin olduğundan emin ol:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

---

## 📁 Dosya Yapısı

```
dilara_app/
├── lib/                                  # Flutter/Dart kaynak kodları
│   └── main.dart
│
├── assets/                               # Ses dosyaları, görseller, Lottie animasyonları
│
└── android/
    └── app/
        └── src/main/
            ├── AndroidManifest.xml
            ├── kotlin/com/dilara/social/
            │   ├── MainActivity.kt                        # Flutter ↔ Android köprüsü
            │   ├── PrayerTimesWidgetReceiver.kt            # Medium widget (2×4)
            │   ├── PrayerTimesHorizontalWidgetReceiver.kt  # Yatay widget (4×1)
            │   ├── PrayerTimesBigWidgetReceiver.kt         # Büyük widget (4×3+)
            │   ├── PrayerAlarmScheduler.kt                 # Exact alarm yöneticisi
            │   └── PrayerAlarmReceiver.kt                  # Alarm broadcast alıcısı
            │
            └── res/
                ├── layout/
                │   ├── dilara_widget.xml                   # Medium widget layout
                │   ├── dilara_widget_horizontal.xml        # Yatay widget layout
                │   └── dilara_widget_big.xml               # Büyük widget layout
                ├── xml/
                │   ├── prayer_times_widget_info.xml
                │   ├── prayer_times_widget_horizontal_info.xml
                │   └── prayer_times_widget_big_info.xml
                ├── drawable/
                │   ├── camii3.png                          # Büyük widget arka planı
                │   ├── sunset.xml
                │   └── calendar.xml
                └── values/
                    └── strings.xml
```

---

## 🌐 WordPress Entegrasyonu

Uygulama içerik verilerini WordPress REST API üzerinden çeker.

### İçerik Türleri

| Tür | Açıklama |
|-----|----------|
| **Postlar** | Ana haber/makale listesi |
| **Kategoriler** | İçerik ayrımı (Namaz, Dua, Sohbet vb.) |
| **Kitaplar** | 3 adet kitap, bölüm bazlı içerik |

### API Akışı

```
WordPress REST API
        │
        │  http / dio
        ▼
Flutter (liste ekranı)
        │
        ├── Carousel Slider  → Öne çıkan postlar
        ├── Post Listesi     → Kategoriye göre filtrelenmiş
        ├── Post Detay       → flutter_html / flutter_widget_from_html
        └── Kitap İçeriği   → Bölüm bazlı okuma + TTS
```

### HTML İçerik Gösterimi

WordPress'ten gelen HTML içerik iki paketle render edilir:

- `flutter_html` → Genel post içerikleri
- `flutter_widget_from_html` → Daha zengin HTML yapıları (tablo, iframe vb.)
- `html_character_entities` → HTML karakter entity dönüşümü (`&amp;` → `&` gibi)

---

## 🧩 Widget Mimarisi

### Widget Türleri

| Widget | Sınıf | Layout | Boyut |
|--------|-------|--------|-------|
| Medium | `PrayerTimesWidgetReceiver` | `dilara_widget.xml` | 2×4 |
| Yatay | `PrayerTimesHorizontalWidgetReceiver` | `dilara_widget_horizontal.xml` | 4×1 |
| Büyük | `PrayerTimesBigWidgetReceiver` | `dilara_widget_big.xml` | 4×3+ |

### Veri Akışı

```
Flutter (Dart)
    │
    │  MethodChannel: "net.dilara.social/widget"
    │  method: "savePrayerTimes"
    ▼
MainActivity.kt
    │
    │  SharedPreferences("HomeWidget")
    │  widget_fajr, widget_dhuhr, widget_location ...
    ▼
PrayerTimesWidgetReceiver.onUpdate()
    │
    ├── computeCurrentPrayerIndex()   → Aktif vakti hesapla
    ├── calculateRemaining()          → Kalan süreyi hesapla
    ├── RemoteViews                   → Widget'ı güncelle
    │
    └── PrayerAlarmScheduler.scheduleNext()
            │
            │  AlarmManager.setExactAndAllowWhileIdle()
            ▼
        PrayerAlarmReceiver.onReceive()
            └── Tüm widget'ları güncelle
```

### Alarm Sistemi

Android'in `updatePeriodMillis` değeri en erken 30 dakikada bir tetiklenir. Vakit geçişlerini tam dakikasında yakalamak için `PrayerAlarmScheduler`, her güncellemede bir sonraki namaz vaktine `setExactAndAllowWhileIdle` ile alarm kurar.

---

## 🔌 Flutter ↔ Android Kanalları

**Kanal adı:** `net.dilara.social/widget`

### `savePrayerTimes`

```dart
await platform.invokeMethod('savePrayerTimes', {
  'fajr':     '05:09',
  'sunrise':  '06:28',
  'dhuhr':    '12:25',
  'asr':      '15:38',
  'maghrib':  '18:12',
  'isha':     '19:27',
  'location': 'Isparta',
  'date':     '04.03.2026',
});
```

Veriyi iki SharedPreferences'a kaydeder:
- `FlutterSharedPreferences` → Flutter `shared_preferences` paketi erişimi
- `HomeWidget` → Widget receiver'lar tarafından okunur

### `updateAndroidWidget`

```dart
await platform.invokeMethod('updateAndroidWidget');
```

Sadece widget'ı yeniden yükler, veri kaydetmez.

---

## 📦 Kullanılan Paketler

### İçerik & Ağ
| Paket | Kullanım |
|-------|----------|
| `http` | WordPress REST API istekleri |
| `dio` | Gelişmiş HTTP istemcisi |
| `flutter_html` | HTML içerik render |
| `flutter_widget_from_html` | Zengin HTML render |
| `html_character_entities` | HTML entity dönüşümü |
| `flutter_inappwebview` | In-app tarayıcı |
| `webview_flutter` | WebView desteği |
| `url_launcher` | Dış link açma |

### Medya & Ses
| Paket | Kullanım |
|-------|----------|
| `flutter_tts` | Text-to-Speech okuma |
| `audioplayers` | Ses dosyası oynatma |
| `assets_audio_player` | Gelişmiş ses oynatıcı (git) |
| `youtube_player_flutter` | YouTube video oynatıcı |
| `lottie` | Animasyon desteği |

### UI & Navigasyon
| Paket | Kullanım |
|-------|----------|
| `google_fonts` | Özel fontlar |
| `carousel_slider` | Öne çıkan içerik slider |
| `share_plus` | İçerik paylaşma |

### Konum & Bildirim
| Paket | Kullanım |
|-------|----------|
| `geolocator` | Konum tespiti |
| `awesome_notifications` | Yerel bildirimler |
| `firebase_messaging` | Push bildirimler (FCM) |
| `firebase_analytics` | Kullanıcı analitik |
| `permission_handler` | İzin yönetimi |
| `connectivity_plus` | Bağlantı kontrolü |

### Depolama & Diğer
| Paket | Kullanım |
|-------|----------|
| `shared_preferences` | Yerel veri saklama |
| `path_provider` | Dosya sistemi erişimi |
| `flutter_widgetkit` | iOS widget desteği |
| `intl` | Tarih/saat formatlama |

---

## 📝 Notlar

- Widget layout'larında yalnızca `RemoteViews` tarafından desteklenen view tipleri kullanılabilir
- `@drawable/` referansları layout'larda kullanılıyorsa ilgili dosyaların `res/drawable/` içinde mevcut olması zorunludur — aksi halde widget "Can't load widget" hatası verir
- Android 12+ için `USE_EXACT_ALARM` izni manifest'te tanımlı olmalıdır
- `assets_audio_player` paketi git bağımlılığı olarak eklenmiştir, `pub.dev`'den değil
