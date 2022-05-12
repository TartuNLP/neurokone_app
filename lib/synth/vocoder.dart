import 'dart:developer';
import 'package:tflite_flutter/tflite_flutter.dart';

class Vocoder {
  static late String TAG;
  late String modulePath;
  late Interpreter vocModule;

  Vocoder(String vocName) {
    TAG = vocName;
    modulePath = 'voc_models/' + vocName + '.tflite';
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

  List getAudio(List spectrogram) {
    vocModule.resizeInputTensor(0, spectrogram.shape);
    vocModule.allocateTensors();

    //List<List<Float32List>> inputArray = List<List<Float32List>>.filled(length, fill)

    //TensorBuffer output = TensorBuffer.createDynamic(TfLiteType.float32);
    //var out = List<double>.filled(2, 0);
    var out = [List.generate(43264, (_) => List<double>.filled(1, 0))];
    //var input = spectrogram.getBuffer();
    vocModule.run(spectrogram, out);

    //var tensors = vocModule.getOutputTensors();
    Tensor outputTensor = vocModule.getOutputTensor(0);
    List output = List<double>.filled(outputTensor.numElements(), 0)
        .reshape(outputTensor.shape);
    outputTensor.copyTo(output);

    //TensorBuffer audioArray =
    //    TensorBuffer.createFixedSize(outShape, TfLiteType.float32);
    //Uint8List outData = outputTensor.data.buffer.asUint8List(
    //    outputTensor.data.offsetInBytes, outputTensor.data.lengthInBytes);
    //audioArray.loadList(outData, shape: outShape);

    return output;
  }
}
