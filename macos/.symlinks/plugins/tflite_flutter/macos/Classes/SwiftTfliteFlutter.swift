import FlutterMacOS
import AppKit

public class SwiftTfliteFlutter: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "tflite_flutter", binaryMessenger: registrar.messenger)
    let instance = SwiftTfliteFlutter()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
  }
}
