import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let periodicSyncTaskIdentifier = "fr.zimberts.mediavore.dailySync"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register the periodic BGTaskScheduler identifier used by Workmanager on iOS.
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: periodicSyncTaskIdentifier,
      frequency: NSNumber(value: 24 * 60 * 60)
    )
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
