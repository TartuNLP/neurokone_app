import 'package:logger/logger.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TfModel {
  Logger logger = Logger();
  final String TAG;
  late String modulePath;
  late Interpreter mModule;

  TfModel(this.TAG) {
    modulePath = '$TAG.tflite';
    loadModel();
  }

  loadModel() async {
    mModule = await Interpreter.fromAsset(modulePath);
    logger.d(modulePath);
  }

  //Performs inference on the model and returns model's output as Tensor.
  //Input should already formatted to to model's input shape.
  Tensor invokeModel(List<Object> inputList) {
    var inputTensors = mModule.getInputTensors();

    for (int i = 0; i < inputList.length; i++) {
      Tensor tensor = inputTensors.elementAt(i);
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
