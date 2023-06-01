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
  late FlutterTts systemTts;
  NativeTts? nativeTts;
  bool stopNative = false;
  String engine = '';

  var logger = Logger();

  Tts(this.isIOS);

  //Loads Android system's tts engine.
  void initSystemTts() async {
    systemTts = FlutterTts();
    //Synchronizes the tts output so that an audio clip is not played until the previous one has finished.
    await systemTts.awaitSpeakCompletion(true);
  }

  //Loads the application's tts engine.
  void initTtsNative() {
    if (nativeTts == null)
      nativeTts = NativeTts('fastspeech2-est', 'hifigan-est.v2', this.isIOS);
    logger.d('TtsEngine: native');
  }

  Future setDefaultEngine() async {
    if (isIOS) {
      if (await systemTts.isLanguageAvailable(this.lang)) {
        systemTts.setLanguage(this.lang);
        //systemTts.setVoice({lang: (await systemTts.getVoices)[0]});
      }
    } else {
      String newEngine = await systemTts.getDefaultEngine;
      if (this.engine != newEngine) {
        this.engine = newEngine;
        print('TtsEngine:' + this.engine.toString());
        systemTts.setEngine(this.engine);
      }
    }
  }

  //Processes the text before input to the model.
  final EstProcessor _processor = EstProcessor();

  speak(String text, double speed, bool isSystem, dynamic voice) async {
    logger.i("Synth voice: " + voice.toString());
    if (!isSystem) {
      List<String> sentences = await _processor.preprocess(text);
      for (String sentence in sentences) {
        if (stopNative) break;
        await nativeTts!.nativeTextToSpeech(sentence, voice, speed);
      }
      stopNative = false;
    } else {
      await systemTts.setLanguage(lang);
      try {
        await systemTts.setVoice({"name": voice, "locale": lang});
      } catch (e) {}
      //await systemTts.setVolume(volume);
      await systemTts.setSpeechRate(speed / 2);
      //await systemTts.setPitch(pitch);
      await systemTts.speak(text);
    }
  }
}
