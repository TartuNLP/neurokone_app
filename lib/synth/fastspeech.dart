import 'dart:developer';
import 'package:tflite_app/synth/abstract_module.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class FastSpeech implements AbstractModule {
  static late String TAG;
  late String modulePath;
  late Interpreter mModule;

  FastSpeech(String modelName) {
    TAG = modelName;
    modulePath = 'synth_models/' + modelName + '.tflite';
    loadModel();
  }

  @override
  loadModel() async {
    mModule = await Interpreter.fromAsset(modulePath);
    log(modulePath);
    for (Tensor tensor in mModule.getInputTensors()) {
      log('$TAG (in): ' +
          'name:' +
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

  //Prepares the input dimensions, runs the model and returns the model's output mel spectrogram
  @override
  List getMelSpectrogram(List inputIds, int voiceId, double speed) {
    log('input id length: ' + inputIds.length.toString());
    List<Object> inputList = [
      [inputIds], //input_ids
      [voiceId], //speaker_ids
      [speed], //speed_ratio
      [1.0], //f0_ratios
      [1.0], //energy_ratios
    ];
    if (mModule.getInputTensors().length == 6) {
      inputList.insert(1, [
        [0] //attention_mask
      ]);
    }
    var inputTensors = mModule.getInputTensors();

    for (int i = 0; i < inputList.length; i++) {
      var tensor = inputTensors.elementAt(i);
      final newShape = tensor.getInputShapeIfDifferent(inputList[i]);
      if (newShape != null) {
        mModule.resizeInputTensor(i, newShape);
      }
    }
    mModule.allocateTensors();

    inputTensors = mModule.getInputTensors();
    for (int i = 0; i < inputList.length; i++) {
      inputTensors.elementAt(i).setTo(inputList[i]);
    }

    mModule.invoke();
    Tensor outputTensor = mModule.getOutputTensor(0);
    log('Spectrogram shape: ' + outputTensor.shape.toString());
    var output = List<double>.filled(outputTensor.numElements(), 0)
        .reshape(outputTensor.shape);
    outputTensor.copyTo(output);

    return output;
  }
}
