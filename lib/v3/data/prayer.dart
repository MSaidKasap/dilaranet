import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utill/notifications.dart';

/// V3 namaz vakitleri veri katmanı.
///
/// Eski `lib/core/pages/prayer_times_page.dart` ile aynı kaynaklar:
/// - Konum: geolocator
/// - Ters coğrafi kodlama: nominatim.openstreetmap.org
/// - Vakitler: api.aladhan.com (method=13, adjustment=1)
/// Önbellek sqflite yerine SharedPreferences (7 gün) ile tutulur.
class V3PrayerTimes {
  final String locationName;
  final DateTime date;
  final Map<String, String> times; // Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha

  const V3PrayerTimes({
    required this.locationName,
    required this.date,
    required this.times,
  });

  static const order = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  static const trNames = {
    'Fajr': 'İmsak',
    'Sunrise': 'Güneş',
    'Dhuhr': 'Öğle',
    'Asr': 'İkindi',
    'Maghrib': 'Akşam',
    'Isha': 'Yatsı',
  };

  /// Bugünün geçmiş/sıradaki vaktini hesaplar.
  ({String key, DateTime at})? get nextPrayer {
    final now = DateTime.now();
    for (final key in const ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
      final at = _dateTimeFor(key);
      if (at != null && at.isAfter(now)) return (key: key, at: at);
    }
    return null;
  }

  DateTime? _dateTimeFor(String key) {
    final raw = times[key];
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    return DateTime(date.year, date.month, date.day,
        int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
  }

  DateTime? dateTimeFor(String key) => _dateTimeFor(key);
}

class V3PrayerRepository {
  static const _kaabaFallback = 'Mekke';
  static final _notifications = NotificationService();

  /// Konum al → vakitleri çek (7 gün) → önbelleğe yaz → bugünü döndür.
  /// Her çağrıda iOS/Android ana ekran widget'ını da günceller (bkz.
  /// `_syncWidget` — v2'de vardı, v3'e taşınmamıştı).
  static Future<V3PrayerTimes> load({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cached = _readCache(prefs, DateTime.now());
      if (cached != null) {
        await _syncWidget(cached);
        return cached;
      }
    }

    final pos = await _position();
    final locationName = await _reverseGeocode(pos.latitude, pos.longitude);
    final week = await _fetchWeek(pos.latitude, pos.longitude, locationName);

    // Önbelleğe yaz
    final map = {
      for (final day in week)
        DateFormat('yyyy-MM-dd').format(day.date): {
          'location': day.locationName,
          'times': day.times,
        }
    };
    await prefs.setString('v3_prayer_cache', json.encode(map));

    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final today = week.firstWhere(
      (d) => DateFormat('yyyy-MM-dd').format(d.date) == todayKey,
      orElse: () => week.first,
    );
    await _syncWidget(today);
    return today;
  }

  // ---- Ana ekran widget'ı (iOS App Group + Android SharedPreferences) ----

  static const _widgetChannel = MethodChannel('net.dilara.social/widget');

  static Future<void> _syncWidget(V3PrayerTimes day) async {
    try {
      await _widgetChannel.invokeMethod('savePrayerTimes', {
        'fajr': day.times['Fajr'] ?? '',
        'sunrise': day.times['Sunrise'] ?? '',
        'dhuhr': day.times['Dhuhr'] ?? '',
        'asr': day.times['Asr'] ?? '',
        'maghrib': day.times['Maghrib'] ?? '',
        'isha': day.times['Isha'] ?? '',
        'location': day.locationName,
        'date': DateFormat('dd.MM.yyyy').format(DateTime.now()),
      });
    } catch (_) {
      // Widget güncellenemedi (ör. kanal native tarafta hazır değil):
      // uygulamanın kendi akışını bozmasın.
    }
  }

  static V3PrayerTimes? _readCache(SharedPreferences prefs, DateTime day) {
    final raw = prefs.getString('v3_prayer_cache');
    if (raw == null) return null;
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      final key = DateFormat('yyyy-MM-dd').format(day);
      final entry = map[key] as Map<String, dynamic>?;
      if (entry == null) return null;
      return V3PrayerTimes(
        locationName: '${entry['location'] ?? _kaabaFallback}',
        date: DateTime(day.year, day.month, day.day),
        times: Map<String, String>.from(entry['times'] as Map),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Position> _position() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw Exception('Konum servisi kapalı. Lütfen konumu açın.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception(
          'Konum izni kapalı. Ayarlar > Uygulama üzerinden konuma izin verin.');
    }
    if (perm == LocationPermission.denied) {
      throw Exception('Konum izni verilmedi.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  static Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final res = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=tr'),
        headers: {'User-Agent': 'DilaraApp/1.0'},
      );
      if (res.statusCode == 200) {
        final addr = (json.decode(res.body)['address'] ?? {}) as Map;
        final parts = [
          addr['town'] ?? addr['city'] ?? addr['county'] ?? addr['state'],
          addr['country'],
        ].where((e) => e != null && '$e'.isNotEmpty).toList();
        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (_) {}
    return _kaabaFallback;
  }

  static Future<List<V3PrayerTimes>> _fetchWeek(
      double lat, double lng, String locationName) async {
    final result = <V3PrayerTimes>[];
    final today = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final day = today.add(Duration(days: i));
      final dateStr = DateFormat('dd-MM-yyyy').format(day);
      final res = await http.get(Uri.parse(
          'https://api.aladhan.com/v1/timings/$dateStr?latitude=$lat&longitude=$lng&method=13&adjustment=1'));
      if (res.statusCode != 200) {
        throw Exception('Namaz vakitleri alınamadı (${res.statusCode})');
      }
      final timings =
          (json.decode(res.body)['data']['timings'] ?? {}) as Map<String, dynamic>;
      result.add(V3PrayerTimes(
        locationName: locationName,
        date: DateTime(day.year, day.month, day.day),
        times: {
          for (final k in V3PrayerTimes.order)
            k: _clean('${timings[k] ?? ''}'),
        },
      ));
    }
    return result;
  }

  static String _clean(String raw) => raw.split(' ').first.trim();

  // ---- Bildirimler ----

  static const _notifPrefKey = 'v3_prayer_notifications_enabled';
  static const _offsetMinutesKey = 'v3_notify_offset_minutes';
  static const _offsetIsBeforeKey = 'v3_notify_offset_is_before';
  static const _prayerSettingPrefix = 'v3_prayer_setting_';

  static Future<bool> notificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifPrefKey) ?? false;
  }

  static Future<int> offsetMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_offsetMinutesKey) ?? 45;
  }

  static Future<bool> offsetIsBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offsetIsBeforeKey) ?? true;
  }

  static Future<void> setOffset(int minutes, bool isBefore) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_offsetMinutesKey, minutes);
    await prefs.setBool(_offsetIsBeforeKey, isBefore);
  }

  /// Vakit başına açık/kapalı + sessiz ayarı. Kayıt yoksa varsayılan
  /// (Güneş hariç hepsi açık, sesli) döner.
  static Future<Map<String, V3PrayerNotifSetting>> perPrayerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, V3PrayerNotifSetting>{};
    for (final key in V3PrayerTimes.order) {
      final raw = prefs.getString('$_prayerSettingPrefix$key');
      if (raw != null) {
        try {
          result[key] = V3PrayerNotifSetting.fromJson(
              json.decode(raw) as Map<String, dynamic>);
          continue;
        } catch (_) {
          // Bozuk kayıt: varsayılana düş.
        }
      }
      result[key] =
          V3PrayerNotifSetting(enabled: key != 'Sunrise', isSilent: false);
    }
    return result;
  }

  static Future<void> savePrayerSetting(
      String key, V3PrayerNotifSetting setting) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '$_prayerSettingPrefix$key', json.encode(setting.toJson()));
  }

  static Future<void> setNotificationsEnabled(bool value,
      {V3PrayerTimes? today}) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      // Bildirim izni yoksa iste.
      if (!await _notifications.isNotificationAllowed()) {
        final granted = await _notifications.requestNotificationPermission();
        if (!granted) {
          await prefs.setBool(_notifPrefKey, false);
          throw Exception('Bildirim izni verilmedi.');
        }
      }
      await prefs.setBool(_notifPrefKey, true);
      await rescheduleAll(today: today);
    } else {
      await prefs.setBool(_notifPrefKey, false);
      await _notifications.cancelAllNotifications();
    }
  }

  /// Bugün + yarın için, kayıtlı vakit/offset/sessiz ayarlarına göre tüm
  /// bildirimleri iptal edip yeniden zamanlar. Bildirimler kapalıysa hiçbir
  /// şey zamanlamaz (sadece iptal eder).
  static Future<void> rescheduleAll({V3PrayerTimes? today}) async {
    await _notifications.cancelAllNotifications();
    if (!await notificationsEnabled()) return;

    final prefs = await SharedPreferences.getInstance();
    final todayData = today ?? await load();
    final tomorrowData =
        _readCache(prefs, DateTime.now().add(const Duration(days: 1)));

    final offMin = await offsetMinutes();
    final offBefore = await offsetIsBefore();
    final settings = await perPrayerSettings();
    final enabledMap = {
      for (final e in settings.entries) e.key: e.value.enabled
    };
    final silentMap = {
      for (final e in settings.entries) e.key: e.value.isSilent
    };
    final soundMap = {for (final key in V3PrayerTimes.order) key: 'default'};

    await _notifications.scheduleForDay(
      day: todayData.date,
      times: todayData.times,
      locationText: todayData.locationName,
      offsetMinutes: offMin,
      offsetIsBefore: offBefore,
      prayerEnabled: enabledMap,
      prayerSoundId: soundMap,
      prayerIsSilent: silentMap,
      prayerLabels: trNamesFor,
    );

    if (tomorrowData != null) {
      await _notifications.scheduleForDay(
        day: tomorrowData.date,
        times: tomorrowData.times,
        locationText: tomorrowData.locationName,
        offsetMinutes: offMin,
        offsetIsBefore: offBefore,
        prayerEnabled: enabledMap,
        prayerSoundId: soundMap,
        prayerIsSilent: silentMap,
        prayerLabels: trNamesFor,
      );
    }
  }

  static Map<String, String> get trNamesFor => V3PrayerTimes.trNames;
}

/// Tek bir vakit için bildirim tercihi (açık/kapalı + sessiz).
class V3PrayerNotifSetting {
  bool enabled;
  bool isSilent;

  V3PrayerNotifSetting({required this.enabled, required this.isSilent});

  Map<String, dynamic> toJson() => {'enabled': enabled, 'isSilent': isSilent};

  factory V3PrayerNotifSetting.fromJson(Map<String, dynamic> json) =>
      V3PrayerNotifSetting(
        enabled: json['enabled'] as bool? ?? true,
        isSilent: json['isSilent'] as bool? ?? false,
      );
}
