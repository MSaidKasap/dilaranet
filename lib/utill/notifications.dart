import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      'resource://mipmap/ic_launcher', // ✅ mipmap kullanıyoruz
      [
        NotificationChannel(
          channelKey: 'prayer_channel',
          channelName: 'Namaz Vakitleri',
          channelDescription: 'Namaz vakitleri bildirimleri',
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          criticalAlerts: true,
        )
      ],
      debug: true,
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await AwesomeNotifications()
        .isNotificationAllowed()
        .then((isAllowed) async {
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> showImmediateNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'prayer_channel',
        title: "Namaz Vakti Yaklaşıyor ⏰",
        body:
            "(Kıyamet gününde) kulun ilk önce hesaba çekileceği şey, namazdır...” (Nesâî, Muhârebe, 2)",
        category: NotificationCategory.Reminder,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        criticalAlert: true,
      ),
    );

    print("✅ Anlık bildirim gönderildi.");
  }

  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // 28 dakika öncesinden bildirim zamanla
    final notificationTime =
        scheduledTime.subtract(const Duration(minutes: 28));

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'prayer_channel',
        title: title,
        body: body,
        category: NotificationCategory.Reminder,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        criticalAlert: true,
      ),
      schedule: NotificationCalendar(
        year: notificationTime.year,
        month: notificationTime.month,
        day: notificationTime.day,
        hour: notificationTime.hour,
        minute: notificationTime.minute,
        second: 0,
        millisecond: 0,
        repeats: false, // Tekrar etmesini istiyorsanız true yapın
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );

    print("✅ Zamanlanmış bildirim ayarlandı: ${notificationTime.toString()}");
  }

  // Günlük tekrarlayan bildirim için
  Future<void> scheduleDailyPrayerNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'prayer_channel',
        title: title,
        body: body,
        category: NotificationCategory.Reminder,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
        criticalAlert: true,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        millisecond: 0,
        repeats: true, // Günlük tekrar
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
  }

  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
    print("✅ Tüm bildirimler iptal edildi.");
  }

  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
    print("✅ Bildirim iptal edildi: ID $id");
  }

  // Aktif bildirimleri listele
  Future<List<NotificationModel>> getScheduledNotifications() async {
    return await AwesomeNotifications().listScheduledNotifications();
  }

  // Bildirim izni durumunu kontrol et
  Future<bool> isNotificationAllowed() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  // Bildirim izni iste
  Future<bool> requestNotificationPermission() async {
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }
}
