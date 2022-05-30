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

  /*
  @override
  List getMelSpectrogram(List<int> inputIds, int voiceId, double speed) {
    log('input id length: ' + inputIds.length.toString());
    mModule.resizeInputTensor(0, [1, inputIds.length]);
    mModule.allocateTensors();

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
    //TensorBuffer out = TensorBuffer.createDynamic(TfLiteType.float32);
    //out.resize([1, 1, 80]);
    //var out = List<double>.filled(1, 0);
    List<List<List<double>>> out = [];
    //var out = [List.generate(169, (_) => List<double>.filled(80, 0))];
    Map<int, Object> outputMap = {};
    int counter = 0;
    for (var tensor in mModule.getOutputTensors()) {
      //log(tensor.name);
      outputMap[counter] = out;
      counter++;
    }

    mModule.runForMultipleInputs(inputList, outputMap);

    //var tensors = mModule.getOutputTensors();
    Tensor outputTensor = mModule.getOutputTensor(1);
    var output = List<double>.filled(outputTensor.numElements(), 0)
        .reshape(outputTensor.shape);
    outputTensor.copyTo(output);

    //var outt = output.toString();
    //TensorBuffer spectrogram =
    //    TensorBuffer.createFixedSize(outShape, TfLiteType.float32);
    //Float32List outData = outputTensor.data.buffer.asFloat32List();

    //spectrogram.loadList(outData, shape: outShape);

    return output;
  }*/

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
    var output = List<double>.filled(outputTensor.numElements(), 0)
        .reshape(outputTensor.shape);
    outputTensor.copyTo(output);

    return output;
  }
}
