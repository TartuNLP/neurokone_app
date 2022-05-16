import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
//import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/*
class AudioData {
  final String text;
  final Uint8List data;

  AudioData({required this.text, required this.data});
}
*/

Future<void> save(Uint8List header, String path, int sampleRate) async {
  File recordedFile = File(path);
  /*
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
  */
  return recordedFile.writeAsBytesSync(header, flush: true);
}
/*
class MyByteSource extends StreamAudioSource {
  final Uint8List _buffer;

  MyByteSource(this._buffer) : super(tag: 'MyAudioSource');

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: (start ?? 0) - (end ?? _buffer.length),
      offset: start ?? 0,
      stream: Stream.fromIterable([_buffer.sublist(start ?? 0, end)]),
      contentType: 'audio/wav',
    );
  }
}
*/

class TtsPlayer {
  //AudioPlayer player = AudioPlayer(mode: PlayerMode.MEDIA_PLAYER);
  AudioPlayer player = AudioPlayer();
  DateTime lastStart = DateTime.now();
  int previusDurationInMs = 0;
  int delayInMs = 100;
  int sampleRate = 22050;

  List<int> _convertFloatTo16BitSigned(List<double> pcmDouble) {
    int coeff = 32768;

    String dataLen = (pcmDouble.length * 2).toRadixString(2);
    while (dataLen.length < 32) {
      dataLen = '0' + dataLen;
    }
    int data1 = int.parse(dataLen.substring(16), radix: 2);
    int data2 = int.parse(dataLen.substring(0, 16), radix: 2);

    String fileLen = (pcmDouble.length * 2 + 36).toRadixString(2);
    while (fileLen.length < 32) {
      fileLen = '0' + fileLen;
    }
    int file1 = int.parse(fileLen.substring(16), radix: 2);
    int file2 = int.parse(fileLen.substring(0, 16), radix: 2);

    //List<int> out = [];

    List<int> out = [
      18770,
      17990, //“RIFF” - Marks the file as a riff file. Characters are each 1 byte long.
      file1,
      file2, //File size (integer) - Size of the overall file - 8 bytes, in bytes (32-bit integer).
      16727, 17750, //“WAVE” - File Type Header.
      28006, 8308, //“fmt " - Format chunk marker. Includes trailing null
      16, 0, //16 - Length of format data as listed above
      1, //Type of format (1 is PCM)
      1, //Number of Channels
      sampleRate, 0, //Sample Rate - 32 byte integer
      -21436, 0, // - 65536 + ((Sample Rate * BitsPerSample * Channels)/8)
      2, //(BitsPerSample * Channels)/8: 1 - 8 bit mono; 2 - 8 bit stereo/16 bit mono; 4 - 16 bit stereo
      16, //Bits per sample
      24932,
      24948, //“data” - “data” chunk header. Marks the beginning of the data section.
      data1,
      data2 //Size of the data section.
    ];
    for (double value in pcmDouble) {
      double newValue = (value * coeff);
      //int newInt = newValue.toInt();
      int newInt = newValue.round();
      out.add(newInt);
    }
    return out;
  }

  /*
  Future waitWhile(bool isTrue, [Duration pollInterval = Duration.zero]) {
  var completer = Completer();
  check() {
    if (!isTrue) {
      completer.complete();
    } else {
      Timer(pollInterval, check);
    }
  }
  check();
  return completer.future;
}*/

  playAudio(String sentence, List<double> bytes, double speed) async {
    //player.pause();
    log('Playing audio for sentence "' + sentence + '"');
    String filePath = (await getTemporaryDirectory()).toString().split('\'')[1] + 'tempAudio.wav';
    List<int> intBytes = _convertFloatTo16BitSigned(bytes);
    Int16List intList = Int16List.fromList(intBytes);
    Uint8List playableBytes = intList.buffer
        .asUint8List(intList.offsetInBytes, intList.lengthInBytes);

    while (DateTime.now().isBefore(lastStart
        .add(Duration(milliseconds: previusDurationInMs + delayInMs)))) {
      continue;
    }
    await save(playableBytes, filePath, 22050);
    previusDurationInMs = (intList.length * 1000 / sampleRate).ceil();
    lastStart = DateTime.now();

    int result = await player.play(filePath, isLocal: true);
    //await player.setAudioSource(MyByteSource(playableBytes));
    //await player.setAudioSource(
    //    AudioSource.uri(Uri.parse('file://assets/audio/lause00007.wav')));
    //"https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3"
    //player.play();
    //player.pause();
    //int result = await player.playBytes(playableBytes);
    //log("Audio playing.");
  }

  bool isPlaying() {
    //return player.playing;
    return player.state == PlayerState.PLAYING;
  }

  stopAudio() async {
    //player.stop();
    int result = await player.stop();
    //_player.stopPlayer();
  }
}
