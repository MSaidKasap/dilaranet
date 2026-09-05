import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'core/screen/download_screen.dart';
import 'services/cdn_downloader_service.dart';
import 'v3/app.dart';

Future<void> _initFirebaseOnce() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await _initFirebaseOnce();
    print('📨 [ARKA PLAN] Bildirim: ${message.messageId}');
  } catch (e) {
    print('❌ Arka plan hatası: $e');
  }
}

// -----------------------------------------------
// 🔔 AwesomeNotifications Global Listener Metodları
// Bu metodlar static veya top-level olmak ZORUNDA
// -----------------------------------------------

@pragma('vm:entry-point')
Future<void> onNotificationCreatedMethod(
  ReceivedNotification receivedNotification,
) async {
  print('🔔 Bildirim oluşturuldu: ${receivedNotification.title}');
}

@pragma('vm:entry-point')
Future<void> onNotificationDisplayedMethod(
  ReceivedNotification receivedNotification,
) async {
  print('📺 Bildirim gösterildi: ${receivedNotification.title}');
}

@pragma('vm:entry-point')
Future<void> onDismissActionReceivedMethod(
  ReceivedAction receivedAction,
) async {
  print('❌ Bildirim kapatıldı: ${receivedAction.title}');
}

@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
  print('👆 Bildirime tıklandı: ${receivedAction.title}');
  // Buraya bildirime tıklandığında yapılacak işlemleri ekleyebilirsin
  // Örneğin: belirli bir sayfaya yönlendirme
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('tr_TR', null);
  await initializeDateFormatting('en_US', null);

  await _initFirebaseOnce();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'prayer_channel',
      channelName: 'Prayer Notifications',
      channelDescription: 'Namaz ve sohbet bildirimleri',
      defaultColor: Colors.blue,
      ledColor: Colors.white,
      importance: NotificationImportance.High,
      channelShowBadge: true,
    ),
    NotificationChannel(
      channelKey: 'prayer_ongoing_channel',
      channelName: 'Namaz Vakitleri (Sürekli)',
      channelDescription: 'Bildirim çubuğunda sürekli görünen namaz vakitleri',
      defaultColor: const Color(0xFF1B5E20),
      ledColor: Colors.green,
      importance: NotificationImportance.Low,
      channelShowBadge: false,
      playSound: false,
      enableVibration: false,
    ),
  ], debug: false);
  // ✅ Listener'lar initialize'dan hemen sonra kaydediliyor
  await AwesomeNotifications().setListeners(
    onActionReceivedMethod: onActionReceivedMethod,
    onNotificationCreatedMethod: onNotificationCreatedMethod,
    onNotificationDisplayedMethod: onNotificationDisplayedMethod,
    onDismissActionReceivedMethod: onDismissActionReceivedMethod,
  );

  await _requestNotificationPermissions();

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  _setupFirebaseListeners();

  // Token alma arka planda, uygulamayı bloklamıyor
  _printDeviceTokensSafe();
  await _restoreOngoingNotificationIfNeeded();
  runApp(const MyApp());
}

Future<void> _requestNotificationPermissions() async {
  final fm = FirebaseMessaging.instance;
  final settings = await fm.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('🔔 FCM izin: ${settings.authorizationStatus}');
}

Future<void> _restoreOngoingNotificationIfNeeded() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final fajr = prefs.getString('flutter.widget_fajr');
    if (fajr == null || fajr.isEmpty) return; // Daha önce veri kaydedilmemiş

    final allTimes = {
      'Fajr': prefs.getString('flutter.widget_fajr') ?? '',
      'Sunrise': prefs.getString('flutter.widget_sunrise') ?? '',
      'Dhuhr': prefs.getString('flutter.widget_dhuhr') ?? '',
      'Asr': prefs.getString('flutter.widget_asr') ?? '',
      'Maghrib': prefs.getString('flutter.widget_maghrib') ?? '',
      'Isha': prefs.getString('flutter.widget_isha') ?? '',
    };

    // Sonraki namazı hesapla
    final nextKey = _getNextPrayerKey(allTimes);

    await showPrayerTimesOngoingNotification(
      currentPrayer: nextKey,
      allTimes: allTimes,
      location: prefs.getString('flutter.widget_location') ?? '',
      remainingTime: '',
    );

    print('✅ Ongoing bildirim geri yüklendi');
  } catch (e) {
    print('❌ Bildirim geri yükleme hatası: $e');
  }
}

String _getNextPrayerKey(Map<String, String> times) {
  final now = DateTime.now();
  final order = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  for (final key in order) {
    final parts = (times[key] ?? '').split(':');
    if (parts.length < 2) continue;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final t = DateTime(now.year, now.month, now.day, h, m);
    if (t.isAfter(now)) return key;
  }
  return 'Fajr'; // Gece yarısı → ertesi gün imsak
}

void _setupFirebaseListeners() {
  FirebaseMessaging.onMessage.listen((message) {
    print("📩 [ÖN PLAN] ${message.notification?.title}");
    showFirebaseNotificationWithAwesome(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    print("📱 Açıldı: ${message.messageId}");
  });
}

void _printDeviceTokensSafe() async {
  final fm = FirebaseMessaging.instance;

  if (Platform.isIOS) {
    String? apns;
    for (int i = 0; i < 3; i++) {
      apns = await fm.getAPNSToken();
      if (apns != null) break;
      print('⏳ APNs bekleniyor (${i + 1}/3)...');
      await Future.delayed(const Duration(seconds: 2));
    }

    if (apns == null) {
      print('⚠️ APNs alınamadı, uygulama normal devam ediyor.');
      return;
    }

    print('🍎 APNs: $apns');
  }

  try {
    final fcm = await fm.getToken();
    print('🔑 FCM: $fcm');
  } catch (e) {
    print('⚠️ FCM token hatası: $e');
  }
}

Future<void> showFirebaseNotificationWithAwesome(RemoteMessage message) async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      channelKey: 'prayer_channel',
      title: message.notification?.title ?? 'Bildirim',
      body: message.notification?.body ?? 'Yeni mesaj',
      notificationLayout: NotificationLayout.Default,
      wakeUpScreen: true,
    ),
  );
}

Future<void> showPrayerTimesOngoingNotification({
  required String currentPrayer,
  required Map<String, String> allTimes,
  String location = '',
  String remainingTime = '',
  BuildContext? context,
}) async {
  final isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) return;

  final vakitLabels = {
    'Fajr': 'İmsak',
    'Sunrise': 'Güneş',
    'Dhuhr': 'Öğle',
    'Asr': 'İkindi',
    'Maghrib': 'Akşam',
    'Isha': 'Yatsı',
  };

  final nextLabel = vakitLabels[currentPrayer] ?? currentPrayer;
  final nextTime = allTimes[currentPrayer] ?? '--:--';

  // Başlık: sonraki vakit
  final title =
      '🕌 $nextLabel — $nextTime'
      '${remainingTime.isNotEmpty ? "  ($remainingTime kaldı)" : ""}';

  // Body: her vakit ayrı satırda, sonraki vurgulu
  final lines = <String>[];

  if (location.isNotEmpty) {
    lines.add('📍 $location');
    lines.add(''); // boş satır
  }

  final order = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  final icons = {
    'Fajr': '🌙',
    'Sunrise': '🌄',
    'Dhuhr': '☀️',
    'Asr': '🌤',
    'Maghrib': '🌇',
    'Isha': '🌙',
  };

  for (final key in order) {
    final label = vakitLabels[key] ?? key;
    final time = allTimes[key] ?? '--:--';
    final icon = icons[key] ?? '•';
    final isNext = key == currentPrayer;

    if (isNext) {
      lines.add('$icon $label  $time  ◀ sonraki');
    } else {
      lines.add('$icon $label  $time');
    }
  }

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 1001,
      channelKey: 'prayer_ongoing_channel',
      title: title,
      body: lines.join('\n'),
      notificationLayout: NotificationLayout.BigText,
      autoDismissible: false,
      locked: true,
      wakeUpScreen: false,
      category: NotificationCategory.Service,
      summary: '🕌 Namaz Vakitleri',
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _needsDownload = true;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    final downloader = CdnDownloaderService();
    final status = await downloader.checkDownloadStatus();
    setState(() {
      _needsDownload = !(status['isComplete'] == true);
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    if (_needsDownload) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: DownloadScreen(
          onComplete: () => setState(() => _needsDownload = false),
        ),
      );
    }
    return const V3App();
  }
}
