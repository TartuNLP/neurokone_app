import 'package:eesti_tts/synth/text_encoder.dart';
import 'package:eesti_tts/synth/native_models/fastspeech.dart';
import 'package:eesti_tts/synth/native_models/vocoder.dart';
import 'package:eesti_tts/synth/audio_player.dart';

class NativeTts {
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
    _synth = FastSpeech(modelName, isIOS);
    _vocoder = Vocoder(vocName, isIOS);
  }

  //Text preprocessing, models' inference and playing of the resulting audio
  //Saves maximum of 3 audio files to memory.
  nativeTextToSpeech(String sentence, int voiceId, double invertedSpeed) async {
    double speed = 1.0 / invertedSpeed;
    List output = encoder.textToIds(sentence);
    output = await _synth.getMelSpectrogram(output, voiceId, speed);
    output = _vocoder.getAudio(output);

    List<double> audioBytes = [];
    if (output[0].length > 1) {
      for (int i = 0; i < output[0].length; i++) {
        audioBytes.add(output[0][i][0]);
      }
    } else {
      audioBytes = output[0][0];
    }
    await audioPlayer.playAudio(sentence, audioBytes, fileId);
    if (fileId >= 2) {
      fileId = 0;
    } else {
      fileId++;
    }
  }
}
