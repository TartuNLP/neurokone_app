import 'dart:io';
import 'package:neurokone/ui/voice.dart';
import 'package:logger/logger.dart';
import 'package:neurokone/variables.dart' as vars;
import 'package:flutter/services.dart';

class SystemChannel {
  Logger logger = Logger();
  late final MethodChannel channel =
      MethodChannel((Platform.isAndroid ? 'com.' : '') + vars.packageName);
  List<Voice> enabledVoices = [];

  SystemChannel() {
    _getEnabledVoices();
  }

  _getEnabledVoices() async {
    if (Platform.isIOS) {
      List enabledVoiceNames = await channel.invokeMethod("getDefaultVoices");
      List<String> enabledVoiceNamesString =
          enabledVoiceNames.map((e) => e as String).toList();
      enabledVoices = _namesToVoices(enabledVoiceNamesString);
      logger.d("Voices: $enabledVoices");
    } else {
      enabledVoices = vars.voices;
    }
  }

  List<Voice> _namesToVoices(List<String> names) {
    List<Voice> voices = [];
    for (Voice voice in vars.voices) {
      if (names.contains(voice.getName())) voices.add(voice);
    }
    return voices;
  }

  List<Voice> getDefaultVoices() {
    return enabledVoices;
  }

  void setNewVoices(List<Voice> newVoices) async {
    enabledVoices = newVoices;
    logger.d("Now enabled: $enabledVoices");
  }

  Future<void> save() async {
    logger.d("Saving $enabledVoices to defaults.");
    logger.i(await channel.invokeMethod(
        'setDefaultVoices', enabledVoices.map((e) => e.getName()).toList()));
  }
}
