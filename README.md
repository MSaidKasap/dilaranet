# 🕌 Dilara — Namaz Vakitleri Uygulaması

Flutter tabanlı namaz vakitleri uygulaması. Android ana ekran widget'ları, Firebase bildirimleri ve konum bazlı vakit hesaplama içerir.

---

## 📋 İçindekiler

- [Kurulum](#kurulum)
- [Dosya Yapısı](#dosya-yapısı)
- [Widget Mimarisi](#widget-mimarisi)
- [Flutter ↔ Android Kanalları](#flutter--android-kanalları)

---

## 🚀 Kurulum

### Gereksinimler

- Flutter 3.x+
- Android Studio / VS Code
- Android SDK 26+
- Firebase projesi (FCM için)

### Adımlar

```bash
# 1. Repoyu klonla
git clone https://github.com/kullanici/dilara_app.git
cd dilara_app

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
3. FCM bildirimlerini etkinleştir

### Android İzinleri

`AndroidManifest.xml`'de şu izinlerin olduğundan emin ol:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```

---

## 📁 Dosya Yapısı

```
dilara_app/
├── lib/                          # Flutter/Dart kaynak kodları
│   └── main.dart
│
└── android/
    └── app/
        └── src/main/
            ├── AndroidManifest.xml
            ├── kotlin/com/dilara/social/
            │   ├── MainActivity.kt                      # Flutter ↔ Android köprüsü
            │   ├── PrayerTimesWidgetReceiver.kt          # Medium widget (2x4)
            │   ├── PrayerTimesHorizontalWidgetReceiver.kt # Yatay widget (4x1)
            │   ├── PrayerTimesBigWidgetReceiver.kt       # Büyük widget (4x3+)
            │   ├── PrayerAlarmScheduler.kt               # Exact alarm yöneticisi
            │   └── PrayerAlarmReceiver.kt                # Alarm broadcast alıcısı
            │
            └── res/
                ├── layout/
                │   ├── dilara_widget.xml                 # Medium widget layout
                │   ├── dilara_widget_horizontal.xml      # Yatay widget layout
                │   └── dilara_widget_big.xml             # Büyük widget layout
                ├── xml/
                │   ├── prayer_times_widget_info.xml      # Medium widget tanımı
                │   ├── prayer_times_widget_horizontal_info.xml
                │   └── prayer_times_widget_big_info.xml
                ├── drawable/
                │   ├── camii3.png                        # Büyük widget arka planı
                │   ├── sunset.xml                        # Akşam ikonu
                │   ├── calendar.xml                      # Takvim ikonu
                │   └── bg_current_prayer_transparent.xml # Aktif vakit vurgu bg
                └── values/
                    └── strings.xml
```

---

## 🧩 Widget Mimarisi

Uygulama 3 farklı Android widget içerir. Her widget bağımsız bir `AppWidgetProvider` sınıfıyla yönetilir.

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
    ├── computeCurrentPrayerIndex()   → Şu anki vakti hesapla
    ├── calculateRemaining()          → Kalan süreyi hesapla
    ├── RemoteViews → widget güncelle
    │
    └── PrayerAlarmScheduler.scheduleNext()
            │
            │  AlarmManager (setExactAndAllowWhileIdle)
            ▼
        PrayerAlarmReceiver.onReceive()
            │
            └── Tüm widget'ları güncelle (broadcast)
```

### Aktif Vakit Tespiti

`computeCurrentPrayerIndex()` fonksiyonu şu anki saati tüm vakitlerle karşılaştırarak hangi vakit diliminde olunduğunu hesaplar:

```kotlin
// Örnek: Saat 14:30 → İkindi başladıysa currentIdx = 3 (İkindi)
// Saat 03:00 → İmsak gelmedi → currentIdx = 5 (Yatsı devam ediyor)
```

### Alarm Sistemi

`updatePeriodMillis` Android tarafından en erken 30 dakikada bir tetiklenir — vakit geçişlerini yakalamak için yetersizdir. Bu nedenle `PrayerAlarmScheduler`, her güncellemede bir sonraki namaz vaktine `setExactAndAllowWhileIdle` ile tam dakikasında alarm kurar.

---

## 🔌 Flutter ↔ Android Kanalları

### MethodChannel

**Kanal adı:** `net.dilara.social/widget`

#### `savePrayerTimes`

Flutter'dan namaz vakitlerini Android'e gönderir ve tüm widget'ları günceller.

**Parametreler:**

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

**Android tarafı** bu verileri iki yere kaydeder:
- `FlutterSharedPreferences` → Flutter `shared_preferences` paketi ile erişim için
- `HomeWidget` → Widget receiver'lar tarafından okunur

#### `updateAndroidWidget`

Sadece widget'ı yeniden yükler, veri kaydetmez.

```dart
await platform.invokeMethod('updateAndroidWidget');
```

---

## 📝 Notlar

- Widget layout'larında yalnızca `RemoteViews` tarafından desteklenen view tipleri kullanılabilir (`TextView`, `ImageView`, `LinearLayout` vb.)
- `@drawable/` referansları layout'larda kullanılıyorsa ilgili dosyaların `res/drawable/` içinde mevcut olması zorunludur — aksi halde widget "Can't load widget" hatası verir
- Android 12+ için `USE_EXACT_ALARM` izni manifest'te tanımlı olmalıdır