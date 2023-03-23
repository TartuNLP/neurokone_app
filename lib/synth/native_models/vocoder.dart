import 'dart:developer';
import 'package:tflite_flutter/tflite_flutter.dart';

class Vocoder {
  final String TAG;
  final bool isIOS;
  late String modulePath;
  late Interpreter vocModule;

  Vocoder(this.TAG, this.isIOS) {
    modulePath = '../android/app/src/main/assets/' + this.TAG + '.tflite';
    //modulePath = 'voc_models/' + vocName + '.tflite';
    loadModel();
  }

  loadModel() async {
    vocModule = await Interpreter.fromAsset(modulePath);
    for (Tensor tensor in vocModule.getInputTensors()) {
      log('$TAG (in): ' +
          'name:' +
          tensor.name +
          ', shape:' +
          tensor.shape.toString() +
          ', type:' +
          tensor.type.toString());
    }
    for (Tensor tensor in vocModule.getOutputTensors()) {
      log('$TAG (out): ' +
          'name:' +
          tensor.name +
          ', shape:' +
          tensor.shape.toString() +
          ', type:' +
          tensor.type.toString());
    }
  }

  //Prepares the input dimensions for vocoder model, runs the model on the input, returns output float array
  List getAudio(List spectrogram) {
    List<Object> inputList = [spectrogram];
    var outputTensor;
    if (isIOS) {
      Map<int, Object> outputList = {0: dynamic};
      vocModule.runForMultipleInputs(inputList, outputList);
      outputTensor = outputList[0] as Tensor;
    } else {
      var inputTensors = vocModule.getInputTensors();

      for (int i = 0; i < inputList.length; i++) {
        var tensor = inputTensors.elementAt(i);
        final newShape = tensor.getInputShapeIfDifferent(inputList[i]);
        if (newShape != null) {
          vocModule.resizeInputTensor(i, newShape);
        }
      }

      vocModule.allocateTensors();

      inputTensors = vocModule.getInputTensors();
      for (int i = 0; i < inputList.length; i++) {
        inputTensors.elementAt(i).setTo(inputList[i]);
      }

      vocModule.invoke();
      outputTensor = vocModule.getOutputTensor(0);
    }
    List output = List<double>.filled(outputTensor.numElements(), 0)
        .reshape(outputTensor.shape);
    outputTensor.copyTo(output);
    return output;
  }
}
