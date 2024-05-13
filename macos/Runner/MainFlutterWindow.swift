import Cocoa
import FlutterMacOS
//import IOKit.ps
//import AVFoundation

class MainFlutterWindow: NSWindow {
    let defaults = UserDefaults(suiteName: "group.tartunlp.neurokone")
    let mainBundle = Bundle.main
    
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)
        
        /*
        addModelPath(assetPath: "assets/fastspeech2-est.tflite", key: "synthesizer", controller: flutterViewController)
        addModelPath(assetPath: "assets/hifigan-est.v2.tflite", key: "vocoder", controller: flutterViewController)
            
        let methodChannel = FlutterMethodChannel(name: "tartunlp.neurokone", binaryMessenger: flutterViewController.engine.binaryMessenger)
            methodChannel.setMethodCallHandler(handleMethodCalls)
        */
        
        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
    }
    
    /*
    private func addModelPath(assetPath: String, key: String, controller: FlutterViewController) {
        let modelKey = controller.lookupKey(forAsset: assetPath)
        let modelPath = mainBundle.path(forResource: modelKey, ofType: nil)
        defaults!.set(modelPath, forKey: key)
      }
      
    private func handleMethodCalls(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "getDefaultVoices":
                result(defaults!.value(forKey: "voices") as? [String] ?? [])
            case "setDefaultVoices":
                let arguments = call.arguments as? [String]
                print("QQQ Enabling voices: \(arguments!.description)")
                defaults!.set(arguments!, forKey: "voices")
                AVSpeechSynthesisProviderVoice.updateSpeechVoices()
                result("QQQ Success!")
            default:
                result(FlutterMethodNotImplemented)
        }
    }*/
}
