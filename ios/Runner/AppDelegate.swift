import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  let defaults = UserDefaults(suiteName: "group.com.tartunlp.eesti_tts")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    let methodChannel = FlutterMethodChannel(name: "group.com.tartunlp.eesti_tts-channel", binaryMessenger: controller.binaryMessenger) //binaryMessenger: rootViewController as! FlutterBinaryMessenger
    methodChannel.setMethodCallHandler(handleMethodCalls)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleMethodCalls(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "getDefaults":
      result(defaults.value(forKey: "voices"))
      case "setDefaults":
        let arguments = call.arguments as? [[String]: Any]
        let arg1 = arguments?["arg1"] as? [String] ?? []
        defaults.set(arg1, forKey: "voices")
        AVSpeechSynthesisProviderVoice.updateSpeechVoices()
        result("Success!")
      default:
        result(FlutterMethodNotImplemented)
    }
  }
}
