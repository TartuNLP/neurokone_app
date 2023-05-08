import 'package:logger/logger.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TfModel {
  var logger = Logger();
  final String TAG;
  late String modulePath;
  late Interpreter mModule;

  TfModel(this.TAG) {
    modulePath = this.TAG + '.tflite';
    loadModel();
  }

  loadModel() async {
    mModule = await Interpreter.fromAsset(modulePath);
    logger.d(modulePath);
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
