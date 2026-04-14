import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // AppDelegate will be extended for platform-specific implementations
    // - Biometrics (LocalAuthentication)
    // - Secure storage (Keychain)
    // - Camera capture
    // - Location services
    // - Background blur for app switcher
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
