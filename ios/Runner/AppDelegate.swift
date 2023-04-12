import UIKit
import Flutter
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  let defaults = UserDefaults(suiteName: "group.dj.phonix.espeak-n")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as? FlutterViewController
    let methodChannel = FlutterMethodChannel(name: "dj.phonix.espeak-n", binaryMessenger: controller!.binaryMessenger) //binaryMessenger: rootViewController as! FlutterBinaryMessenger
    methodChannel.setMethodCallHandler(handleMethodCalls)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleMethodCalls(call: FlutterMethodCall, result: @escaping FlutterResult) {
    //let defaults = UserDefaults.appGroup
    switch call.method {
      case "getDefaults":
      result(defaults?.value(forKey: "voices") as? [String] ?? [])
      case "setDefaults":
        let arguments = call.arguments as? [String]
        print("Enabling voices: " + arguments!.description)
        defaults?.set(arguments!, forKey: "voices")
        AVSpeechSynthesisProviderVoice.updateSpeechVoices()
        result("Success!")
      default:
        result(FlutterMethodNotImplemented)
    }
  }
}

fileprivate let userLangs = Set(Locale.preferredLanguages.map({ Locale(identifier: $0).language.universal }))
fileprivate let systemLangs = Set(Locale.Language.systemLanguages.flatMap({ [$0] + $0.parents }).map({ $0.universal }))
fileprivate let allLangs = Set(Locale.availableIdentifiers.map({ Locale(identifier: $0).language }).flatMap({ [$0] + $0.parents }).map({ $0.universal }))
fileprivate let currentLocale = Locale.autoupdatingCurrent

extension Locale.Language {
  var parents: [Locale.Language] {
    guard let parent, !parent.isEquivalent(to: self) else { return [] }
    guard parent.languageCode?.identifier(.alpha2) != nil else { return [] }
    return [parent] + parent.parents
  }
  var universalId: String {
    return [
      languageCode?.identifier(.alpha2),
      region?.identifier
    ].compactMap({$0}).joined(separator: "-")
  }
  var universal: Locale.Language { .init(identifier: universalId) }
  var localizedTitle: String {
    guard let langTitle = languageCode.flatMap({ currentLocale.localizedString(forLanguageCode: $0.identifier)?.localizedCapitalized }) else { return self.maximalIdentifier }
    if let regionTitle = region.flatMap({ currentLocale.localizedString(forRegionCode: $0.identifier) }) {
      return "\(langTitle) (\(regionTitle))"
    } else {
      return langTitle
    }
  }
}
