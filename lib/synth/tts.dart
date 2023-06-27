import 'package:logger/logger.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:eestitts/synth/native_tts.dart';
import 'package:eestitts/synth/est_processor.dart';

class Tts {
  /////////////////////////////////////////////////////////
  // FlutterTts uses Android system's text-to-speech engine
  // and so for this application works only for Android.
  /////////////////////////////////////////////////////////
  // NativeTts uses application's native text-to-speech
  // implementation, supports both Android and iOS.
  /////////////////////////////////////////////////////////
  final bool isIOS;
  String lang = 'et-EE';
  late NativeTts nativeTts;
  late FlutterTts systemTts;
  bool stopNative = false;
  String? engine;

  Logger logger = Logger();

  Tts(this.isIOS) {
    initTtsNative();
    initSystemTts();
  }

  //Loads the application's tts engine.
  void initTtsNative() {
    this.nativeTts = NativeTts('fastspeech2-est', 'hifigan-est.v2', this.isIOS);
  }

  //Loads Android system's tts engine.
  void initSystemTts() async {
    this.systemTts = FlutterTts();
    //Synchronizes the tts output so that an audio clip is not played until the previous one has finished.
    await this.systemTts.awaitSpeakCompletion(true);
  }

  Future loadSystemDefaultEngine() async {
    if (this.isIOS) {
      if (await this.systemTts.isLanguageAvailable(this.lang)) {
        this.systemTts.setLanguage(this.lang);
        //this.systemTts.setVoice({lang: (await this.systemTts.getVoices)[0]});
      }
    } else {
      String newEngine = await this.systemTts.getDefaultEngine;
      this.logger.d(newEngine);
      if (this.engine != newEngine) {
        this.engine = newEngine;
        this.logger.d('TtsEngine:' + this.engine.toString());
        this.systemTts.setEngine(this.engine!);
      }
    }
  }

  //Processes the text before input to the model.
  final EstProcessor _processor = EstProcessor();

  speak(String text, double speed, bool isSystem, int? voice) {
    isSystem
        ? _systemSynthesis(text, speed)
        : _nativeSynthesis(text, speed, voice!);
  }

  _systemSynthesis(String text, double speed) async {
    await this.systemTts.setLanguage(this.lang);
    await this.systemTts.setSpeechRate(speed / 2);
    await this.systemTts.speak(text);
  }

  _nativeSynthesis(String text, double speed, int voice) async {
    List<String> sentences = await _processor.preprocess(text);
    for (String sentence in sentences) {
      if (this.stopNative) break;
      await this.nativeTts.nativeTextToSpeech(sentence, voice, speed);
    }
    this.stopNative = false;
  }
}
