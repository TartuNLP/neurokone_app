import 'tfmodel.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class Vocoder extends TfModel {
  Vocoder(super.TAG);

  //Prepares the input dimensions for vocoder model, runs the model on the input, returns output waveform.
  List getAudio(List spectrogram) {
    List<Object> inputList = [spectrogram];

    Tensor outputTensor = invokeModel(inputList);

    List output = List<double>.filled(outputTensor.numElements(), 0)
        .reshape(outputTensor.shape);
    outputTensor.copyTo(output);
    
    return output;
  }
}
