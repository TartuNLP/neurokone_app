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

  //Loads Android system's tts engine.
  //Currently always sets the engine to eesti_tts.
  void initTtsAndroid() {
    systemTts = FlutterTts();
    systemTts.setEngine('com.tartunlp.eesti_tts');

    _setAwaitOptions();
    _getDefaultEngine();
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

  Future _getDefaultEngine() async {
    var engine = await systemTts.getDefaultEngine;
    if (engine != null) print('TtsEngine:' + engine.toString());
  }

  //Processes the text before input to the model.
  final EstProcessor _processor = EstProcessor();

  speak(String text, double speed, int? voice) async {
    List<String> sentences = _processor.preprocess(text);
    if (voice != null) {
      for (String sentence in sentences) {
        await nativeTts.nativeTextToSpeech(sentence, voice, speed);
      }
    } else {
      //await systemTts.setVolume(volume);
      await systemTts.setSpeechRate(speed / 2);
      //await systemTts.setPitch(pitch);
      await systemTts.speak(sentences.join(' . '));
    }
  }
}
