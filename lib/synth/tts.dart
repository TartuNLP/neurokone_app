import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:neurokone/variables.dart' as vars;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:neurokone/synth/native_tts.dart';
import 'package:neurokone/synth/processors.dart';
import 'package:path_provider/path_provider.dart';

class Tts {
  final bool isIOS;
  String lang = 'et';
  String locale = 'EE';

  /////////////////////////////////////////////////////////
  // FlutterTts uses Android system's text-to-speech engine
  // and so for this application works only for Android.
  /////////////////////////////////////////////////////////
  // NativeTts uses application's native text-to-speech
  // implementation, supports both Android and iOS.
  /////////////////////////////////////////////////////////
  late NativeTts nativeTts;
  late FlutterTts systemTts;

  bool stopNative = false;
  String engine = '';

  Logger logger = Logger();

  Tts(this.isIOS) {
    nativeTts = NativeTts();
    initSystemTts();
  }

  //Loads Android system's tts engine.
  void initSystemTts() async {
    if (!isIOS) {
      //copies models to platform application assets
      _copyModel('${vars.synthModel}.tflite');
      _copyModel('${vars.vocModel}.tflite');
    }
    systemTts = FlutterTts();
    //Synchronizes the tts output so that an audio clip is not played until the previous one has finished.
    await systemTts.awaitSpeakCompletion(true);
  }

  void _copyModel(String model) async {
    final Directory docDir = await getApplicationSupportDirectory();
    final String localPath = docDir.path;
    File file = File('$localPath/$model');
    if (file.existsSync()) {
      logger.d('Model $model exists, no need to copy.');
    } else {
      logger.d('Copying model $model to ${file.path}');
      final asset = await rootBundle.load('assets/$model');
      final buffer = asset.buffer;
      await file.writeAsBytes(
          buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes));
    }
  }

  Future loadSystemDefaultEngine() async {
    if (!Platform.isAndroid) {
      if (await systemTts.isLanguageAvailable('$lang-$locale')) {
        systemTts.setLanguage('$lang-$locale');
      }
    } else if (Platform.isAndroid) {
      String newEngine = await systemTts.getDefaultEngine;
      logger.d('TtsEngine:$newEngine');
      engine = newEngine;
    }
  }

  //Splits the whole text into sentences
  final SentProcessor _sentProcessor = SentProcessor();

  //Processes the text before input to the model.
  final Preprocessor _preprocessor = Preprocessor();

  speak(String text, double speed, bool isSystem, int? voice) {
    isSystem ? _systemSynthesis(text) : _nativeSynthesis(text, speed, voice!);
  }

  _systemSynthesis(String text) async {
    if (Platform.isAndroid) {
      await systemTts.setEngine(engine);
      await systemTts.setLanguage('$lang-$locale');
    }
    await systemTts.speak(text);
  }

  _nativeSynthesis(String text, double speed, int voice) async {
    List<String> sentences = _sentProcessor.splitSentences(text);
    for (String sentence in sentences) {
      String processedSentence = await _preprocessor.preprocess(sentence);
      if (stopNative) break;
      await nativeTts.nativeTextToSpeech(processedSentence, voice, speed);
    }
    stopNative = false;
  }
}
