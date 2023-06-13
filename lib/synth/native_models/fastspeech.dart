import 'tfmodel.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class FastSpeech extends TfModel {
  FastSpeech(super.TAG);

  //Prepares the input dimensions, runs the model and returns the model's output mel-scale spectrogram.
  Future<List> getMelSpectrogram(
      List inputIds, int voiceId, double speed) async {
    List<Object> inputList = [
      [inputIds], //input_ids
      [voiceId], //speaker_ids
      [speed], //speed_ratio
      [1.0], //f0_ratios
      [1.0], //energy_ratios
    ];
    if (this.mModule.getInputTensors().length == 6) {
      inputList.insert(1, [
        [0] //attention_mask
      ]);
    }

    Tensor outputTensor = invokeModel(inputList);

    var output = List<double>.filled(outputTensor.numElements(), 0)
        .reshape(outputTensor.shape);
    outputTensor.copyTo(output);

    return output;
  }
}
