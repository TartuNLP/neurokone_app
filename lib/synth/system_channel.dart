import 'dart:io';

import 'package:logger/logger.dart';
import 'package:eestitts/variables.dart';
import 'package:flutter/services.dart';

class SystemChannel {
  var logger = Logger();
  late final MethodChannel channel = new MethodChannel(Variables.channelPath);
  List enabledVoices = [];

  SystemChannel() {
    _getEnabledVoices();
  }

  _getEnabledVoices() async {
    if (Platform.isIOS) {
      this.enabledVoices = await this.channel.invokeMethod("getDefaultVoices");
      logger.d("Voices: " + this.enabledVoices.toString());
    }
  }

  List getDefaultVoices() {
    return this.enabledVoices;
  }

  void setNewVoices(List<String> newVoices) async {
    this.enabledVoices = newVoices;
    logger.d("Now enabled: " + this.enabledVoices.toString());
  }

  Future<void> save() async {
    logger.d("Saving " + this.enabledVoices.toString() + " to defaults.");
    logger.i(await this
        .channel
        .invokeMethod('setDefaultVoices', this.enabledVoices));
  }
}
