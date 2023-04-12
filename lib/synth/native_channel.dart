import 'package:logger/logger.dart';

import 'package:eesti_tts/ui/voice.dart';
import 'package:eesti_tts/variables.dart';
import 'package:flutter/services.dart';

class NativeChannel {
  var logger = Logger();
  late final MethodChannel channel = new MethodChannel(Variables.channelPath);
  final List<String> allVoices =
      Variables.voices.map((Voice voice) => voice.getName()).toList();
  List enabledVoices = [];

  NativeChannel() {
    _getEnabledVoices();
  }

  _getEnabledVoices() async {
    this.enabledVoices = await this.channel.invokeMethod("getDefaults");
    logger.d("Voices: " + this.enabledVoices.toString());
  }

  List getDefaults() {
    return this.enabledVoices;
  }

  void setNewVoices(List<bool> newIds) async {
    this.enabledVoices = [];
    int id = 0;
    for (bool isEnabled in newIds) {
      if (isEnabled) this.enabledVoices.add(allVoices[id]);
      id++;
    }
    logger.d("Now enabled: " + this.enabledVoices.toString());
  }

  Future<void> save() async {
    logger.d("Saving " + this.enabledVoices.toString() + " to defaults.");
    logger
        .i(await this.channel.invokeMethod('setDefaults', this.enabledVoices));
  }
}
