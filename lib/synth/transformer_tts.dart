import 'dart:developer';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'abstract_module.dart';

class TransformerTTS implements AbstractModule {
  static const String TAG = 'TransformerTTS';
  late String modulePath;
  late Interpreter mModule;

  TransformerTTS(String voiceName) {
    modulePath = 'synth_models/' +
        voiceName.toLowerCase() +
        '_tts_weights_step260k'
            //'-tf2.2' +
            //'-tf2.3.1' +
            '_tf2.5_xl'
            '.tflite';

    loadModel();
  }

  @override
  loadModel() async {
    mModule = await Interpreter.fromAsset(modulePath);
    for (Tensor tensor in mModule.getInputTensors()) {
      log('$TAG (in): ' 'name:' +
          tensor.name +
          ', shape:' +
          tensor.shape.toString() +
          ', type:' +
          tensor.type.toString());
    }
    for (Tensor tensor in mModule.getOutputTensors()) {
      log('$TAG (out): ' 'name:' +
          tensor.name +
          ', shape:' +
          tensor.shape.toString() +
          ', type:' +
          tensor.type.toString());
    }
    return Future.value(0);
  }

  @override
  List getMelSpectrogram(List inputIds, int voiceId, double speed) {
    log('input id length: ' + inputIds.length.toString());
    mModule.resizeInputTensor(0, [1, inputIds.length]);
    mModule.allocateTensors();
    List<Object> inputList = [
      [inputIds]
    ];
    var out = List<double>.filled(2, 0);
    Map<int, Object> map = {
      0: out,
    };
    mModule.runForMultipleInputs(inputList, map);

    Tensor outputTensor = mModule.getOutputTensor(0);
    int len = outputTensor.numElements();
    var output = List<double>.filled(len, 0).reshape(outputTensor.shape);
    outputTensor.copyTo(output);
    return _transposeList(output, len);
  }

  List _transposeList(List oldList, int len) {
    List<int> shape = [oldList.shape[0], oldList.shape[2], oldList.shape[1]];
    List newList = List<double>.filled(len, 0).reshape(shape);
    for (int ch = 0; ch < shape[1]; ch++) {
      for (int tick = 0; tick < shape[2]; tick++) {
        newList[0][ch][tick] = oldList[0][tick][ch];
      }
    }
    return newList;
  }

  /*
  Float32List _transposeFlatArray(Float32List spectrogram, int channels) {
    int counter = 0;
    Float32List out = Float32List(spectrogram.length);
    for (int ch = 0; ch < channels; ch++) {
      for (int tick = 0; tick < (spectrogram.length / channels); tick++) {
        int id = channels * tick + ch;
        out[counter] = spectrogram[id];
        counter++;
      }
    }
    return out;
  }
  */
}
