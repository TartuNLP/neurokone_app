import 'package:logger/logger.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

//Adds WAVE file header and saves the audio to memory
Future<void> save(Uint8List data, String path, int sampleRate) async {
  File recordedFile = File(path);

  var channels = 1;

  int byteRate = ((16 * sampleRate * channels) / 8).round();

  var size = data.length;

  var fileSize = size + 36;

  Uint8List header = Uint8List.fromList([
    // "RIFF"
    82, 73, 70, 70,
    fileSize & 0xff,
    (fileSize >> 8) & 0xff,
    (fileSize >> 16) & 0xff,
    (fileSize >> 24) & 0xff,
    // WAVE
    87, 65, 86, 69,
    // fmt
    102, 109, 116, 32,
    // fmt chunk size 16
    16, 0, 0, 0,
    // Type of format
    1, 0,
    // One channel
    channels, 0,
    // Sample rate
    sampleRate & 0xff,
    (sampleRate >> 8) & 0xff,
    (sampleRate >> 16) & 0xff,
    (sampleRate >> 24) & 0xff,
    // Byte rate
    byteRate & 0xff,
    (byteRate >> 8) & 0xff,
    (byteRate >> 16) & 0xff,
    (byteRate >> 24) & 0xff,
    // Uhm
    ((16 * channels) / 8).round(), 0,
    // bitsize
    16, 0,
    // "data"
    100, 97, 116, 97,
    size & 0xff,
    (size >> 8) & 0xff,
    (size >> 16) & 0xff,
    (size >> 24) & 0xff,
    ...data
  ]);
  return recordedFile.writeAsBytesSync(header, flush: true);
}

class TtsPlayer {
  var logger = Logger();
  AudioPlayer player = AudioPlayer();
  DateTime lastStart = DateTime.now();
  int previusDurationInMs = 0;
  int delayInMs = 100;
  int sampleRate = 22050;
  int coeff = 32768;

  //Converts all float values to the int16 range
  List<int> _convertFloatTo16BitSigned(List<double> pcmDouble) {
    List<int> out = [];
    for (double value in pcmDouble) {
      double newValue = (value * this.coeff);
      int newInt = newValue.round();
      out.add(newInt);
    }
    return out;
  }

  //Converts the predicted bytesm adds these to buffer, saves the audio file,
  //waits until the last audio has finished playing and the plays the current audio from memory
  playAudio(String sentence, List<double> bytes, int index) async {
    logger.d('Playing audio for sentence "' + sentence + '"');
    String filePath =
        (await getTemporaryDirectory()).toString().split('\'')[1] +
            '/tempAudio' +
            index.toString() +
            '.wav';
    List<int> intBytes = _convertFloatTo16BitSigned(bytes);
    Int16List intList = Int16List.fromList(intBytes);
    Uint8List playableBytes = intList.buffer
        .asUint8List(intList.offsetInBytes, intList.lengthInBytes);
    while (DateTime.now().isBefore(lastStart
        .add(Duration(milliseconds: previusDurationInMs + delayInMs)))) {
      continue;
    }
    await save(playableBytes, filePath, 22050);
    while (player.state != PlayerState.completed) {
      if (lastStart
              .add(Duration(milliseconds: previusDurationInMs + 200))
              .compareTo(DateTime.now()) <=
          0) {
        player.state = PlayerState.completed;
      }
      continue;
    }
    previusDurationInMs = (intList.length * 1000 / sampleRate).ceil();
    lastStart = DateTime.now();
    await player.play(DeviceFileSource(filePath));
    //await player.play(filePath, isLocal: true);
    logger.d("Audio playing.");
  }

  bool isPlaying() {
    return player.state == PlayerState.playing;
  }

  stopAudio() async {
    await player.stop();
  }
}
