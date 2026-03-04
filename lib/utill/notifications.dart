// lib/utill/notifications.dart

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      await AwesomeNotifications().initialize('resource://mipmap/ic_launcher', [
        NotificationChannel(
          channelKey: 'prayer_channel',
          channelName: 'Namaz Vakitleri',
          channelDescription: 'Namaz vakitleri bildirimleri',
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Colors.amber,
        ),
        NotificationChannel(
          channelKey: 'test_default',
          channelName: 'Test (Varsayılan)',
          channelDescription: 'Test bildirimi varsayılan sistem sesi',
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Colors.blue,
        ),
      ], debug: true);

      await Future.delayed(const Duration(milliseconds: 500));
      _isInitialized = true;
      await _requestPermissions();
      print("✅ NotificationService başarıyla initialize edildi");
    } catch (e) {
      print("❌ NotificationService initialize hatası: $e");
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    } catch (e) {
      print("⚠️ Permission request hatası: $e");
    }
  }

  Future<void> _stopCurrentSound() async {
    if (_isPlaying) {
      try {
        await _audioPlayer.stop();
      } catch (e) {
        print("Ses durdurma hatası: $e");
      }
      _isPlaying = false;
    }
  }

  String _channelKeyForSoundId(String soundId) {
    switch (soundId) {
      default:
        return 'test_default';
    }
  }

  String? _iosSoundFileForSoundId(String soundId) {
    switch (soundId) {
      default:
        return null;
    }
  }

  Future<bool> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isInitialized;
  }

  // Test bildirimi
  Future<void> showImmediateNotification({
    required String soundId,
    int remainingMinutes = 5,
  }) async {
    try {
      await _ensureInitialized();

      String remainingText;
      if (remainingMinutes < 60) {
        remainingText = '$remainingMinutes dakika';
      } else {
        final hours = remainingMinutes ~/ 60;
        final minutes = remainingMinutes % 60;
        remainingText = minutes == 0
            ? '$hours saat'
            : '$hours saat $minutes dakika';
      }

      final id = _generateUniqueId();
      final channelKey = _channelKeyForSoundId(soundId);
      final iosSound = _iosSoundFileForSoundId(soundId);

      final created = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: "🔔 Test Bildirimi",
          body: "Namaz vaktine $remainingText kaldı",
          customSound: iosSound,
          category: NotificationCategory.Reminder,
          notificationLayout: NotificationLayout.Default,
          wakeUpScreen: true,
          criticalAlert: true,
          displayOnForeground: true,
          displayOnBackground: true,
          payload: {
            'type': 'test',
            'remainingMinutes': remainingMinutes.toString(),
            'soundId': soundId,
          },
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'DISMISS',
            label: 'Kapat',
            actionType: ActionType.DismissAction,
          ),
        ],
      );

      if (!created) {
        await _showFallbackNotification(remainingMinutes);
      }
    } catch (e) {
      print("❌ Test bildirimi gönderme hatası: $e");
      await _showFallbackNotification(remainingMinutes);
    }
  }

  Future<void> _showFallbackNotification(int remainingMinutes) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _generateUniqueId(),
          channelKey: 'prayer_channel',
          title: "🔔 Test Bildirimi",
          body: "Namaz vaktine $remainingMinutes dakika kaldı",
          category: NotificationCategory.Reminder,
          notificationLayout: NotificationLayout.Default,
          wakeUpScreen: true,
          criticalAlert: true,
        ),
      );
      print("✅ Yedek test bildirimi gönderildi");
    } catch (e) {
      print("❌ Yedek bildirim de başarısız: $e");
    }
  }

  // Tekil namaz bildirimi zamanlama
  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required String arabicName,
    required DateTime prayerTime,
    required int offsetMinutes,
    required bool isBefore,
    required String soundId,
    required bool isSilent,
  }) async {
    try {
      await _ensureInitialized();

      final notificationTime = isBefore
          ? prayerTime.subtract(Duration(minutes: offsetMinutes))
          : prayerTime.add(Duration(minutes: offsetMinutes));

      if (notificationTime.isBefore(DateTime.now())) {
        print(
          "⚠️ Bildirim zamanı geçmiş, atlandı: $prayerName @ $notificationTime",
        );
        return;
      }

      final String title;
      final String body;
      if (isBefore) {
        title = "⏰ $prayerName Vaktine Yaklaşıyor";
        body =
            " — $prayerName vaktine $offsetMinutes dakika kaldı\n\n"
            "İslam'ın beş şartı Şehadet, Namaz, Zekat, Oruç ve Hac'tır.";
      } else {
        title = "🔔 $prayerName Vakti";
        body =
            " — $prayerName vakti $offsetMinutes dakika önce girdi\n\n"
            "Namaz müminler üzerine vakitleri belirlenmiş bir farzdır. (Nisâ, 103)";
      }

      // Sessiz modda sistem kanalı kullan, sesli modda ses kanalı
      final channelKey = isSilent
          ? 'test_default'
          : _channelKeyForSoundId(soundId);
      final iosSound = isSilent ? null : _iosSoundFileForSoundId(soundId);

      final created = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: title,
          body: body,
          customSound: iosSound,
          category: NotificationCategory.Reminder,
          notificationLayout: NotificationLayout.BigText,
          wakeUpScreen: true,
          criticalAlert: !isSilent,
          displayOnForeground: true,
          displayOnBackground: true,
          payload: {
            'type': 'prayer',
            'prayerName': prayerName,
            'arabicName': arabicName,
            'isBefore': isBefore.toString(),
            'offsetMinutes': offsetMinutes.toString(),
            'soundId': soundId,
            'isSilent': isSilent.toString(),
            'prayerTime': prayerTime.toIso8601String(),
          },
        ),
        schedule: NotificationCalendar(
          year: notificationTime.year,
          month: notificationTime.month,
          day: notificationTime.day,
          hour: notificationTime.hour,
          minute: notificationTime.minute,
          second: 0,
          millisecond: 0,
          repeats: false,
          preciseAlarm: true,
          allowWhileIdle: true,
          timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'DISMISS',
            label: 'Kapat',
            actionType: ActionType.DismissAction,
          ),
        ],
      );

      print(
        "✅ Zamanlandı: $prayerName @ $notificationTime (ses: $soundId, sessiz: $isSilent)",
      );
    } catch (e) {
      print("❌ schedulePrayerNotification hatası [$prayerName]: $e");
    }
  }

  /// Bir günün tüm namaz vakitlerini zamanlar.
  ///
  /// [times] — {"Fajr": "05:12", "Sunrise": "06:45", ...} formatında vakit haritası
  /// [prayerSettings] — {"Fajr": PrayerSettingData(...), ...} her vakit için ayarlar
  /// [offsetMinutes] — kaç dakika önce/sonra
  /// [offsetIsBefore] — true = önce, false = sonra
  Future<void> scheduleForDay({
    required DateTime day,
    required Map<String, String> times, // {"Fajr": "05:12", ...}
    required String locationText,
    required int offsetMinutes,
    required bool offsetIsBefore,
    required Map<String, bool> prayerEnabled,
    required Map<String, String> prayerSoundId,
    required Map<String, bool> prayerIsSilent,
    // Türkçe ve Arapça isimler için
    Map<String, String>? prayerLabels,
    Map<String, String>? prayerArabicNames,
  }) async {
    await _ensureInitialized();

    // Varsayılan isimler
    final labels =
        prayerLabels ??
        {
          'Fajr': 'İmsak',
          'Sunrise': 'Güneş',
          'Dhuhr': 'Öğle',
          'Asr': 'İkindi',
          'Maghrib': 'Akşam',
          'Isha': 'Yatsı',
        };
    final arabicNames =
        prayerArabicNames ??
        {
          'Fajr': 'الفجر',
          'Sunrise': 'الشروق',
          'Dhuhr': 'الظهر',
          'Asr': 'العصر',
          'Maghrib': 'المغرب',
          'Isha': 'العشاء',
        };

    int scheduled = 0;
    int skipped = 0;

    for (final entry in times.entries) {
      final prayerKey = entry.key;
      final timeStr = entry.value; // "05:12"

      // Bu vakit aktif değilse atla
      if (!(prayerEnabled[prayerKey] ?? false)) {
        skipped++;
        continue;
      }

      // Saat:dakika ayrıştır
      final parts = timeStr.split(':');
      if (parts.length < 2) {
        print("⚠️ Geçersiz vakit formatı: $timeStr");
        skipped++;
        continue;
      }
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) {
        print("⚠️ Saat parse hatası: $timeStr");
        skipped++;
        continue;
      }

      final prayerTime = DateTime(day.year, day.month, day.day, hour, minute);

      // Benzersiz ID: tarih + vakit
      // dayOfYear * 10 + prayerIndex formatı çakışmayı önler
      final prayerIndex = [
        'Fajr',
        'Sunrise',
        'Dhuhr',
        'Asr',
        'Maghrib',
        'Isha',
      ].indexOf(prayerKey);
      final dayOfYear = day.difference(DateTime(day.year, 1, 1)).inDays;
      final notifId = (dayOfYear * 10 + (prayerIndex >= 0 ? prayerIndex : 0))
          .abs()
          .remainder(2147483647);

      await schedulePrayerNotification(
        id: notifId,
        prayerName: labels[prayerKey] ?? prayerKey,
        arabicName: arabicNames[prayerKey] ?? '',
        prayerTime: prayerTime,
        offsetMinutes: offsetMinutes,
        isBefore: offsetIsBefore,
        soundId: prayerSoundId[prayerKey] ?? 'default',
        isSilent: prayerIsSilent[prayerKey] ?? false,
      );
      scheduled++;
    }

    print(
      "📅 scheduleForDay tamamlandı: $scheduled zamanlandı, $skipped atlandı",
    );
  }

  Future<void> cancelAllNotifications() async {
    try {
      await AwesomeNotifications().cancelAll();
      await _stopCurrentSound();
      print("✅ Tüm bildirimler iptal edildi");
    } catch (e) {
      print("❌ Bildirim iptal hatası: $e");
    }
  }

  Future<bool> isNotificationAllowed() async {
    try {
      return await AwesomeNotifications().isNotificationAllowed();
    } catch (e) {
      print("❌ İzin kontrol hatası: $e");
      return false;
    }
  }

  Future<bool> requestNotificationPermission() async {
    try {
      return await AwesomeNotifications()
          .requestPermissionToSendNotifications();
    } catch (e) {
      print("❌ İzin isteme hatası: $e");
      return false;
    }
  }

  int _generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(1000000).abs();
  }
}
