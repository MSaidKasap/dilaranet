import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'core/screen/download_screen.dart';
import 'core/screen/splashscreen.dart';
import 'services/cdn_downloader_service.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _isChecking
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _needsDownload
          ? DownloadScreen(
              onComplete: () => setState(() => _needsDownload = false),
            )
          : const SplashScreen(),
    );
  }
}
