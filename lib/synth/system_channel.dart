import 'dart:io';
import 'package:eestitts/ui/voice.dart';
import 'package:logger/logger.dart';
import 'package:eestitts/variables.dart';
import 'package:flutter/services.dart';

class SystemChannel {
  Logger logger = Logger();
  late final MethodChannel channel = new MethodChannel(Variables.packageName);
  List<Voice> enabledVoices = [];

  SystemChannel() {
    _getEnabledVoices();
  }

  _getEnabledVoices() async {
    if (Platform.isIOS) {
      List enabledVoiceNames =
          await this.channel.invokeMethod("getDefaultVoices");
      List<String> enabledVoiceNamesString =
          enabledVoiceNames.map((e) => e as String).toList();
      this.enabledVoices = _namesToVoices(enabledVoiceNamesString);
      this.logger.d("Voices: " + this.enabledVoices.toString());
    } else {
      this.enabledVoices = Variables.voices;
    }
  }

  List<Voice> _namesToVoices(List<String> names) {
    List<Voice> voices = [];
    for (Voice voice in Variables.voices) {
      if (names.contains(voice.getName())) voices.add(voice);
    }
    return voices;
  }

  List<Voice> getDefaultVoices() {
    return this.enabledVoices;
  }

  void setNewVoices(List<Voice> newVoices) async {
    this.enabledVoices = newVoices;
    this.logger.d("Now enabled: " + this.enabledVoices.toString());
  }

  Future<void> save() async {
    this.logger.d("Saving " + this.enabledVoices.toString() + " to defaults.");
    this.logger.i(await this.channel.invokeMethod('setDefaultVoices',
        this.enabledVoices.map((e) => e.getName()).toList()));
  }
}
