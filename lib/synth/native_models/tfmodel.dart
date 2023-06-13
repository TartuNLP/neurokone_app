import 'package:logger/logger.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TfModel {
  Logger logger = Logger();
  final String TAG;
  late String modulePath;
  late Interpreter mModule;

  TfModel(this.TAG) {
    this.modulePath = this.TAG + '.tflite';
    loadModel();
  }

  loadModel() async {
    this.mModule = await Interpreter.fromAsset(this.modulePath);
    this.logger.d(modulePath);
    /*
    for (Tensor tensor in mModule.getInputTensors()) {
      logger.d('$TAG (in): ' +
          'name:' +
          tensor.name +
          ', shape:' +
          tensor.shape.toString() +
          ', type:' +
          tensor.type.toString());
    }
    for (Tensor tensor in mModule.getOutputTensors()) {
      logger.d('$TAG (out): ' +
          'name:' +
          tensor.name +
          ', shape:' +
          tensor.shape.toString() +
          ', type:' +
          tensor.type.toString());
    }
    */
  }

  //Performs inference on the model and returns model's output as Tensor.
  //Input should already formatted to to model's input shape.
  Tensor invokeModel(List<Object> inputList) {
    var inputTensors = this.mModule.getInputTensors();

    for (int i = 0; i < inputList.length; i++) {
      Tensor tensor = inputTensors.elementAt(i);
      final newShape = tensor.getInputShapeIfDifferent(inputList[i]);
      if (newShape != null) {
        this.mModule.resizeInputTensor(i, newShape);
      }
    }
    this.mModule.allocateTensors();

    inputTensors = this.mModule.getInputTensors();
    for (int i = 0; i < inputList.length; i++) {
      inputTensors.elementAt(i).setTo(inputList[i]);
    }

    this.mModule.invoke();

    return this.mModule.getOutputTensor(0);
  }
}
