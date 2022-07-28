import 'dart:developer';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'abstract_module.dart';

//Deprecated
class Tacotron2 implements AbstractModule {
  static const String TAG = 'Tacotron2';
  late String modulePath;
  late Interpreter mModule;

  Tacotron2() {
    modulePath = 'synth_models/tacotron2-' + '114k' + '.tflite';
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
      log('$TAG (out): ' +
          'name:' +
          tensor.name +
          ', shape:' +
          tensor.shape.toString() +
          ', type:' +
          tensor.type.toString());
    }
  }

  @override
  List getMelSpectrogram(List inputIds, int voiceId, double speed) {
    log('input id length: ' + inputIds.length.toString());
    mModule.resizeInputTensor(0, [1, inputIds.length]);
    mModule.allocateTensors();

    List<Object> inputList = [
      [inputIds],
      inputIds.length,
      [voiceId],
    ];
    var out = List<double>.filled(2, 0);
    var map = {
      1: out,
    };

    mModule.runForMultipleInputs(inputList, map);

    Tensor outputTensor = mModule.getOutputTensor(0);
    var output = List<double>.filled(outputTensor.numElements(), 0)
        .reshape(outputTensor.shape);
    outputTensor.copyTo(output);
    return output;
  }
}
