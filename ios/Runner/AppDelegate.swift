import Flutter
import UIKit
import UserNotifications
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Setup MethodChannel for notifications
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "mediavore/notifications", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "requestPermission":
          UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            result(granted)
          }
        case "schedule", "scheduleNotification":
          guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "bad_args", message: "Missing args", details: nil))
            return
          }
          let idVal = args["notificationId"] ?? args["id"]
          let id = String(describing: idVal ?? "0")
          let title = args["title"] as? String ?? "Release"
          let body = args["body"] as? String ?? ""
          let timestampAny = args["timeEpochMillis"] ?? args["timestamp"]
          if let tsNum = timestampAny as? NSNumber {
            let date = Date(timeIntervalSince1970: tsNum.doubleValue / 1000.0)
            let interval = date.timeIntervalSinceNow
            if interval <= 0 {
              // Past date: don't schedule
              result(false)
              return
            }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = UNNotificationSound.default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
              if let e = error {
                result(FlutterError(code: "schedule_error", message: e.localizedDescription, details: nil))
              } else {
                result(true)
              }
            }
          } else {
            result(FlutterError(code: "bad_timestamp", message: "Missing timestamp", details: nil))
          }
        case "cancel", "cancelNotification":
          guard let args = call.arguments as? [String: Any] else {
            result(nil)
            return
          }
          let idVal = args["notificationId"] ?? args["id"]
          let id = String(describing: idVal ?? "0")
          UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
          UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
