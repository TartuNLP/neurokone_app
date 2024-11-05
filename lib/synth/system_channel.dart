import 'dart:io';
import 'package:neurokone/ui/voice.dart';
import 'package:logger/logger.dart';
import 'package:neurokone/variables.dart' as vars;
import 'package:flutter/services.dart';

class SystemChannel {
  Logger logger = Logger();
  late final MethodChannel channel = const MethodChannel(vars.packageName);
  List<Voice> enabledVoices = [];

  SystemChannel() {
    if (Platform.isAndroid) {
      enabledVoices = vars.voices;
    }
  }

  List<Voice> getDefaultVoices() {
    return enabledVoices;
  }
}
