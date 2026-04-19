import Flutter
import UIKit
import workmanager

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register Workmanager for background tasks
    WorkmanagerPlugin.registerTask(withIdentifier: "dailySync")
    WorkmanagerPlugin.registerTask(withIdentifier: "refreshReturningSeries")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
