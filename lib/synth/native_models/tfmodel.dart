import 'dart:developer';
import 'package:tflite_flutter/tflite_flutter.dart';

class TfModel {
  final String TAG;
  late String modulePath;
  late Interpreter mModule;

  TfModel(this.TAG) {
    modulePath = this.TAG + '.tflite';
    loadModel();
  }

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

  Tensor invokeModel(List<Object> inputList) {
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

    return mModule.getOutputTensor(0);
  }
}
