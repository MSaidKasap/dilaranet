import UIKit
import Flutter
import Firebase
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)

    // ✅ Widget Method Channel
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "net.dilara.social/widget",
      binaryMessenger: controller.binaryMessenger
    )

channel.setMethodCallHandler { call, result in
  if call.method == "savePrayerTimes" {
    guard let args = call.arguments as? [String: String] else {
      result(FlutterError(code: "INVALID_ARGS", message: "String map bekleniyor", details: nil))
      return
    }

    let defaults = UserDefaults(suiteName: "group.net.dilara.social")
    defaults?.set(args["fajr"],     forKey: "flutter.widget_fajr")
    defaults?.set(args["sunrise"],  forKey: "flutter.widget_sunrise")
    defaults?.set(args["dhuhr"],    forKey: "flutter.widget_dhuhr")
    defaults?.set(args["asr"],      forKey: "flutter.widget_asr")
    defaults?.set(args["maghrib"],  forKey: "flutter.widget_maghrib")
    defaults?.set(args["isha"],     forKey: "flutter.widget_isha")
    defaults?.set(args["location"], forKey: "flutter.widget_location")
    defaults?.set(args["date"],     forKey: "flutter.widget_date")

    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }

    result("OK")
  } else {
    result(FlutterMethodNotImplemented)
  }
}

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("📱 ✅ APNs Device Token alındı: \(token)")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ APNs kayıt hatası: \(error.localizedDescription)")
  }
}