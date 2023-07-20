import 'package:logger/logger.dart';
import 'package:neurokone/synth/text_encoder.dart';
import 'package:neurokone/synth/native_models/fastspeech.dart';
import 'package:neurokone/synth/native_models/vocoder.dart';
import 'package:neurokone/synth/audio_player.dart';

class NativeTts {
  Logger logger = Logger();
  //Processes the text before input to the model.
  final Encoder encoder = Encoder();
  //Model that synthesizes mel spectrogram from processed text.
  late final FastSpeech _synth;
  //Model that predicts audio waves from mel spectrogram.
  late final Vocoder _vocoder;
  //Plays the predicted audio.
  final TtsPlayer audioPlayer = TtsPlayer();

  int fileId = 0;

  NativeTts(String modelName, String vocName, bool isIOS) {
    this._synth = FastSpeech(modelName);
    this._vocoder = Vocoder(vocName);
  }

  //Text preprocessing, models' inference and playing of the resulting audio
  //Saves maximum of 3 audio files to memory.
  nativeTextToSpeech(String sentence, int voiceId, double invertedSpeed) async {
    double speed = 1.0 / invertedSpeed;
    List output = this.encoder.textToIds(sentence);
    this.logger.d('Input ids length: ' + output.length.toString());
    output = await this._synth.getMelSpectrogram(output, voiceId, speed);
    this.logger.d('Spectrogram shape: ' +
        [output[0].length, output[0][0].length].toString());
    output = this._vocoder.getAudio(output);
    this.logger.d('Audio length: ' + output[0].length.toString());

    List<double> audioBytes = [];
    if (output[0].length > 1) {
      for (int i = 0; i < output[0].length; i++) {
        audioBytes.add(output[0][i][0]);
      }
    } else {
      audioBytes = output[0][0];
    }
    await this.audioPlayer.playAudio(sentence, audioBytes, fileId);
    if (fileId >= 2) {
      fileId = 0;
    } else {
      fileId++;
    }
  }
}
