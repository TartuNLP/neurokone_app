import 'dart:developer';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:eesti_tts/synth/native_tts.dart';
import 'package:eesti_tts/synth/est_processor.dart';

class Tts {
  /////////////////////////////////////////////////////////
  // FlutterTts uses Android system's text-to-speech engine
  // and so for this application works only for Android.
  /////////////////////////////////////////////////////////
  // NativeTts uses application's native text-to-speech
  // implementation, supports both Android and iOS.
  /////////////////////////////////////////////////////////
  late FlutterTts systemTts;
  late NativeTts nativeTts;
  bool stopNative = false;
  String engine = '';

  //Loads Android system's tts engine.
  //Currently always sets the engine to eesti_tts.
  void initTtsAndroid() {
    systemTts = FlutterTts();
    _setAwaitOptions();
  }

  //Loads the application's tts engine.
  void initTtsNative(bool isIOS) {
    nativeTts = NativeTts('fastspeech2-est', 'hifigan-est.v2', isIOS);
    log('TtsEngine: native');
  }

  //Synchronizes the tts output so that an audio clip is not played until the previous one has finished.
  Future _setAwaitOptions() async {
    await systemTts.awaitSpeakCompletion(true);
  }

  Future setDefaultEngine() async {
    String newEngine = await systemTts.getDefaultEngine;
    if (this.engine != newEngine) {
      this.engine = newEngine;
      print('TtsEngine:' + this.engine.toString());
      systemTts.setEngine(this.engine);
    }
  }

  //Processes the text before input to the model.
  final EstProcessor _processor = EstProcessor();

  speak(String text, double speed, int? voice) async {
    List<String> sentences = await _processor.preprocess(text);
    if (voice != null) {
      for (String sentence in sentences) {
        if (stopNative) break;
        await nativeTts.nativeTextToSpeech(sentence, voice, speed);
      }
      stopNative = false;
    } else {
      //await systemTts.setVolume(volume);
      await systemTts.setSpeechRate(speed / 2);
      //await systemTts.setPitch(pitch);
      await systemTts.speak(sentences.join(' . '));
    }
  }
}
