import 'package:flutter/services.dart';

class NativeChannel {
  late final MethodChannel channel;
  late List voices;

  NativeChannel(String channelPath) {
    this.channel = new MethodChannel(channelPath);
    _loadVoices();
  }

  void _loadVoices() async {
    this.voices = await this.channel.invokeMethod('getDefaults') as List;
  }

  List getDefaults() {
    return this.voices;
  }

  void setNewVoices(newVoices) async {
    voices = [];
    for (dynamic voice in newVoices) {
      if (voice[1]! as bool) {
        voices.add(voice[0]! as String);
      }
    }
  }

  Future<void> save() {
    return this.channel.invokeMethod('setDefaults', this.voices);
  }
}
