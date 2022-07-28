//import 'dart:developer';

//import 'package:pytorch_mobile/pytorch_mobile.dart';
//import 'package:pytorch_mobile/model.dart';
//import 'package:pytorch_mobile/enums/dtype.dart';

//DEPRECATED
class TorchVocoder {
  static late String TAG;
  late String modulePath;
  //late Model vocModule;

  TorchVocoder(String vocName) {
    TAG = vocName;
    modulePath = 'assets/torch_models/' + vocName; //+ vocName;
    loadModel();
  }

  loadModel() async {
    //vocModule = await PyTorchMobile.loadModel(modulePath);
    /*
    for (var tensor in vocModule.getInputTensors()) {
      log('$TAG (in): ' +
          'name:' +
          tensor.name +
          ', shape:' +
          tensor.shape.toString() +
          ', type:' +
          tensor.type.toString());
    }
    for (var tensor in vocModule.getOutputTensors()) {
      log('$TAG (out): ' +
          'name:' +
          tensor.name +
          ', shape:' +
          tensor.shape.toString() +
          ', type:' +
          tensor.type.toString());
    }
    */
  }

  getAudio(List spectrogram) {
    int bins = 80;
    //List<int> shape = [1, bins, spectrogram[0].length];
    List<int> shape = [1, spectrogram[0].length, bins];
    List<double> input = _transposeToFlatArray(spectrogram[0], shape);
    //Future _prediction = _invokeModel(vocModule, input, shape);
    //var out = _prediction.then((value) => log(value));
    //return out;
  }

  /*
  _invokeModel(Model model, List<double> input, List<int> shape) async {
    List? out = await model.getPrediction(input, shape, DType.float32);
    return out;
  }
  */

  List<double> _transposeToFlatArray(List spectrogram, List<int> channels) {
    List<double> out = [];
    for (int ch = 0; ch < channels[1]; ch++) {
      for (int tick = 0; tick < channels[2]; tick++) {
        //int id = channels * tick + ch;
        out.add(spectrogram[ch][tick]);
        //out.add(spectrogram[tick][ch]);
      }
    }
    return out;
  }
}
