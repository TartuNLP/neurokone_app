import UIKit
import Flutter
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  let defaults = UserDefaults(suiteName: "group.com.tartunlp.eestitts")
  let mainBundle = Bundle.main

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {
    let flutterController = window?.rootViewController as? FlutterViewController

    addModelPath(assetPath: "assets/fastspeech2-est.tflite", key: "synthesizer", controller: flutterController!)
    addModelPath(assetPath: "assets/hifigan-est.v2.tflite", key: "vocoder", controller: flutterController!)

    let methodChannel = FlutterMethodChannel(name: "com.tartunlp.eestitts", binaryMessenger: flutterController!.binaryMessenger) //binaryMessenger: rootViewController as! FlutterBinaryMessenger
    methodChannel.setMethodCallHandler(handleMethodCalls)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func addModelPath(assetPath: String, key: String, controller: FlutterViewController) {
    let modelKey = controller.lookupKey(forAsset: assetPath)
    let modelPath = mainBundle.path(forResource: modelKey, ofType: nil)
    defaults?.set(modelPath, forKey: key)
  }

  private func handleMethodCalls(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "getDefaultVoices":
        result(defaults?.value(forKey: "voices") as? [String] ?? [])
      case "setDefaultVoices":
        let arguments = call.arguments as? [String]
        print("Enabling voices: " + arguments!.description)
        defaults?.set(arguments!, forKey: "voices")
        AVSpeechSynthesisProviderVoice.updateSpeechVoices()
        result("Success!")
      /*
      case "getDefaultLangs":
        result(defaults?.value(forKey: "langs") as? [String] ?? [])
      case "setDefaultLangs":
        let arguments = call.arguments as? [String]
        print("Enabling languages: " + arguments!.description)
        groupData?.set(arguments!, forKey: "langs")
        AVSpeechSynthesisProviderVoice.updateSpeechVoices()
        result("Success!")
      */
      default:
        //result("fail.")
        result(FlutterMethodNotImplemented)
    }
  }
}
