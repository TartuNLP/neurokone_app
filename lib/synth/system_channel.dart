import 'dart:io';

import 'package:logger/logger.dart';
import 'package:eestitts/variables.dart';
import 'package:flutter/services.dart';

class SystemChannel {
  Logger logger = Logger();
  late final MethodChannel channel = new MethodChannel(Variables.channelPath);
  List enabledVoices = [];

  SystemChannel() {
    _getEnabledVoices();
  }

  _getEnabledVoices() async {
    if (Platform.isIOS) {
      this.enabledVoices = await this.channel.invokeMethod("getDefaultVoices");
      this.logger.d("Voices: " + this.enabledVoices.toString());
    }
  }

  List getDefaultVoices() {
    return this.enabledVoices;
  }

  void setNewVoices(List<String> newVoices) async {
    this.enabledVoices = newVoices;
    this.logger.d("Now enabled: " + this.enabledVoices.toString());
  }

  Future<void> save() async {
    this.logger.d("Saving " + this.enabledVoices.toString() + " to defaults.");
    this.logger.i(await this
        .channel
        .invokeMethod('setDefaultVoices', this.enabledVoices));
  }
}
