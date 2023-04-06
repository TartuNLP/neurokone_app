import 'dart:developer';

import 'package:eesti_tts/ui/voice.dart';
import 'package:eesti_tts/variables.dart';
import 'package:flutter/services.dart';

class NativeChannel {
  late final MethodChannel channel = new MethodChannel(Variables.channelPath);
  final List<String> allVoices =
      Variables.voices.map((Voice voice) => voice.getName()).toList();
  late List enabledVoices;

  NativeChannel() {
    _getEnabledVoices();
  }

  _getEnabledVoices() async {
    enabledVoices = await this.channel.invokeMethod("getDefaults");
  }

  List getDefaults() {
    return this.enabledVoices;
  }

  void setNewVoices(List<bool> newIds) async {
    enabledVoices = [];
    int id = 0;
    for (bool isEnabled in newIds) {
      if (isEnabled) enabledVoices.add(allVoices[id]);
      id++;
    }
    log("Enabled:" + enabledVoices.toString());
  }

  Future<void> save() {
    return this.channel.invokeMethod('setDefaults', this.enabledVoices);
  }
}
