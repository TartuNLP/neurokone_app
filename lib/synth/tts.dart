import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:neurokone/variables.dart' as Variables;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:neurokone/synth/native_tts.dart';
import 'package:neurokone/synth/processors.dart';
import 'package:path_provider/path_provider.dart';

class Tts {
  final bool isIOS;
  String lang = 'et-EE';

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
    this.nativeTts = NativeTts();
    initSystemTts();
  }

  //Loads Android system's tts engine.
  void initSystemTts() async {
    if (!this.isIOS) {
      //copies models to platform application assets
      _copyModel(Variables.synthModel + '.tflite');
      _copyModel(Variables.vocModel + '.tflite');
    }
    this.systemTts = FlutterTts();
    //Synchronizes the tts output so that an audio clip is not played until the previous one has finished.
    await this.systemTts.awaitSpeakCompletion(true);
  }

  void _copyModel(String model) async {
    final Directory docDir = await getApplicationSupportDirectory();
    final String localPath = docDir.path;
    File file = File('$localPath/$model');
    if (file.existsSync()) {
      logger.d('Model ' + model + ' exists, no need to copy.');
    } else {
      logger.d('Copying model ' + model + ' to ' + file.path);
      final asset = await rootBundle.load('assets/' + model);
      final buffer = asset.buffer;
      await file.writeAsBytes(
          buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes));
    }
  }

  Future loadSystemDefaultEngine() async {
    if (this.isIOS) {
      if (await this.systemTts.isLanguageAvailable(this.lang)) {
        this.systemTts.setLanguage(this.lang);
      }
    } else {
      String newEngine = await this.systemTts.getDefaultEngine;
      this.logger.d('TtsEngine:' + newEngine);
      this.engine = newEngine;
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
    await this.systemTts.setEngine(this.engine);
    await this.systemTts.setLanguage(this.lang);
    await this.systemTts.speak(text);
  }

  _nativeSynthesis(String text, double speed, int voice) async {
    List<String> sentences = _sentProcessor.splitSentences(text);
    for (String sentence in sentences) {
      String processedSentence = await _preprocessor.preprocess(sentence);
      if (this.stopNative) break;
      await this.nativeTts.nativeTextToSpeech(processedSentence, voice, speed);
    }
    this.stopNative = false;
  }
}
