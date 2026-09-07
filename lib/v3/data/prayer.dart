import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utill/notifications.dart';

/// V3 namaz vakitleri veri katmanı.
///
/// Eski `lib/core/pages/prayer_times_page.dart` ile aynı kaynaklar/mantık:
/// - Konum: geolocator (15 sn zaman sınırı)
/// - Ters coğrafi kodlama: nominatim.openstreetmap.org
/// - Vakitler: api.aladhan.com (method=13 Diyanet, adjustment=1)
/// - **30 günlük** ön yükleme (v2 ile aynı), önbellek SharedPreferences'ta.
/// - **Konum değişikliği tespiti** (v2 ile aynı ~10 km eşiği): önbellek
///   açılışta anında döner, arka planda konum kontrol edilir; şehir
///   değiştiyse taze veri çekilip [revision] artırılır (dinleyen ekran
///   yeniden yükler).
class V3PrayerTimes {
  final String locationName;
  final DateTime date;
  final Map<String, String> times; // Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha

  /// Bir sonraki günün ilk vakti (İmsak) — bugünkü vakitlerin hepsi geçince
  /// geri sayımın yarına dönebilmesi için (v2 davranışı).
  final DateTime? tomorrowFajr;

  const V3PrayerTimes({
    required this.locationName,
    required this.date,
    required this.times,
    this.tomorrowFajr,
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

  /// Bugünün sıradaki vakti; hepsi geçtiyse yarının İmsak'ı (`tomorrow: true`).
  ({String key, DateTime at, bool tomorrow})? get nextPrayer {
    final now = DateTime.now();
    for (final key in const ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
      final at = _dateTimeFor(key);
      if (at != null && at.isAfter(now)) {
        return (key: key, at: at, tomorrow: false);
      }
    }
    if (tomorrowFajr != null && tomorrowFajr!.isAfter(now)) {
      return (key: 'Fajr', at: tomorrowFajr!, tomorrow: true);
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

  static const _cacheKey = 'v3_prayer_cache';
  static const _locKey = 'v3_prayer_loc'; // "lat,lng"
  static const _prefetchDays = 30;
  static const _notifyDays = 7; // iOS 64 bekleyen bildirim sınırının altında
  static const _locChangeThreshold = 0.1; // ~10 km (v2 ile aynı)

  /// Arka planda konum kontrolü taze veri çekince artar; ekranlar dinleyip
  /// yeniden yükler (proje deseni: singleton + ValueNotifier).
  static final ValueNotifier<int> revision = ValueNotifier(0);
  static bool _bgRefreshing = false;

  /// Konum al → vakitleri çek (30 gün) → önbelleğe yaz → bugünü döndür.
  /// Önbellek varsa anında döner ve arka planda konum değişikliği kontrolü
  /// yapar. Her çağrıda ana ekran widget'ını da günceller.
  static Future<V3PrayerTimes> load({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh) {
      final cached = _readCache(prefs, DateTime.now());
      if (cached != null) {
        final withTomorrow = _attachTomorrow(prefs, cached);
        await _syncWidget(withTomorrow);
        // Arka planda: şehir değiştiyse taze veri çek (beklenmez).
        unawaited(_maybeRefreshForLocation(prefs));
        return withTomorrow;
      }
    }

    final pos = await _position();
    final locationName = await _reverseGeocode(pos.latitude, pos.longitude);
    final week =
        await _fetchDays(pos.latitude, pos.longitude, locationName, _prefetchDays);
    await _writeCache(prefs, week, pos.latitude, pos.longitude);

    final today = _pickToday(week);
    final withTomorrow = _attachTomorrow(prefs, today);
    await _syncWidget(withTomorrow);
    return withTomorrow;
  }

  // ---- Önbellek yazımı / okuması ----

  static Future<void> _writeCache(SharedPreferences prefs,
      List<V3PrayerTimes> days, double lat, double lng) async {
    final map = {
      for (final day in days)
        DateFormat('yyyy-MM-dd').format(day.date): {
          'location': day.locationName,
          'times': day.times,
        }
    };
    await prefs.setString(_cacheKey, json.encode(map));
    await prefs.setString(_locKey, '$lat,$lng');
  }

  static V3PrayerTimes _pickToday(List<V3PrayerTimes> week) {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return week.firstWhere(
      (d) => DateFormat('yyyy-MM-dd').format(d.date) == todayKey,
      orElse: () => week.first,
    );
  }

  static V3PrayerTimes _attachTomorrow(
      SharedPreferences prefs, V3PrayerTimes today) {
    final tomorrow =
        _readCache(prefs, DateTime.now().add(const Duration(days: 1)));
    final fajr = tomorrow?.dateTimeFor('Fajr');
    return V3PrayerTimes(
      locationName: today.locationName,
      date: today.date,
      times: today.times,
      tomorrowFajr: fajr,
    );
  }

  static V3PrayerTimes? _readCache(SharedPreferences prefs, DateTime day) {
    final raw = prefs.getString(_cacheKey);
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

  // ---- Konum değişikliği tespiti (arka plan) ----

  static Future<void> _maybeRefreshForLocation(SharedPreferences prefs) async {
    if (_bgRefreshing) return;
    _bgRefreshing = true;
    try {
      // İzin zaten yoksa dokunma (kullanıcıya arka planda dialog çıkmasın).
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return;

      Position pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        return;
      }

      final saved = prefs.getString(_locKey);
      if (saved != null) {
        final parts = saved.split(',');
        final sLat = double.tryParse(parts.first);
        final sLng = parts.length > 1 ? double.tryParse(parts[1]) : null;
        if (sLat != null && sLng != null) {
          final moved = (sLat - pos.latitude).abs() > _locChangeThreshold ||
              (sLng - pos.longitude).abs() > _locChangeThreshold;
          if (!moved) return; // şehir aynı → önbellek geçerli
        }
      }

      // Şehir değişti (veya kayıt yok): taze veri çek.
      final locationName = await _reverseGeocode(pos.latitude, pos.longitude);
      final days = await _fetchDays(
          pos.latitude, pos.longitude, locationName, _prefetchDays);
      await _writeCache(prefs, days, pos.latitude, pos.longitude);
      await _syncWidget(_attachTomorrow(prefs, _pickToday(days)));
      revision.value++;
    } catch (_) {
      // sessiz — önbellek ile devam
    } finally {
      _bgRefreshing = false;
    }
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

  // ---- Konum + API ----

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
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  static Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final res = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=tr'),
        headers: {'User-Agent': 'DilaraApp/1.0'},
      ).timeout(const Duration(seconds: 10));
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

  static Future<List<V3PrayerTimes>> _fetchDays(
      double lat, double lng, String locationName, int count) async {
    final today = DateTime.now();
    final result = List<V3PrayerTimes?>.filled(count, null);

    // v2 gibi paralel — ancak API'yi yormamak için 8'erli gruplar.
    for (var start = 0; start < count; start += 8) {
      final end = (start + 8).clamp(0, count);
      await Future.wait([
        for (var i = start; i < end; i++)
          _fetchDay(lat, lng, locationName, today.add(Duration(days: i)))
              .then((d) => result[i] = d),
      ]);
    }

    final days = result.whereType<V3PrayerTimes>().toList();
    if (days.isEmpty) {
      throw Exception('Namaz vakitleri alınamadı. İnternet bağlantınızı '
          'kontrol edin.');
    }
    return days;
  }

  static Future<V3PrayerTimes?> _fetchDay(
      double lat, double lng, String locationName, DateTime day) async {
    try {
      final dateStr = DateFormat('dd-MM-yyyy').format(day);
      final res = await http.get(Uri.parse(
              'https://api.aladhan.com/v1/timings/$dateStr?latitude=$lat&longitude=$lng&method=13&adjustment=1'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body);
      final timings =
          (data['data']?['timings'] ?? {}) as Map<String, dynamic>;
      if (timings.isEmpty) return null;
      return V3PrayerTimes(
        locationName: locationName,
        date: DateTime(day.year, day.month, day.day),
        times: {
          for (final k in V3PrayerTimes.order) k: _clean('${timings[k] ?? ''}'),
        },
      );
    } catch (_) {
      return null;
    }
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

  /// Önbellekteki önümüzdeki [_notifyDays] gün için, kayıtlı vakit/offset/
  /// sessiz ayarlarına göre tüm bildirimleri iptal edip yeniden zamanlar.
  /// Bildirimler kapalıysa sadece iptal eder.
  static Future<void> rescheduleAll({V3PrayerTimes? today}) async {
    await _notifications.cancelAllNotifications();
    if (!await notificationsEnabled()) return;

    final prefs = await SharedPreferences.getInstance();

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

    final now = DateTime.now();
    for (var i = 0; i < _notifyDays; i++) {
      final dayDate = now.add(Duration(days: i));
      final data = (i == 0 && today != null)
          ? today
          : _readCache(prefs, dayDate);
      if (data == null) continue;
      await _notifications.scheduleForDay(
        day: data.date,
        times: data.times,
        locationText: data.locationName,
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
