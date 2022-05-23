import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:tflite_app/audio_player.dart';
import 'package:tflite_app/processors/eng_processor.dart';
import 'package:tflite_app/processors/est_processor.dart';
import 'package:tflite_app/processors/processor.dart';
import 'package:tflite_app/synth/abstract_module.dart';
import 'package:tflite_app/synth/fastspeech.dart';
//import 'package:tflite_app/synth/torch_vocoder.dart';
//import 'package:tflite_app/synth/transformer_tts.dart';
import 'package:tflite_app/synth/vocoder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static final List<String> langs = ['Eesti', 'English'];

  static final Map<String, String> defaultText = {
    'English': 'Working on a ship is cumbersome.',
    //'Unless you work on a ship, it\'s unlikely that you use the word boatswain in everyday conversation, ' +
    //    'so it\'s understandably a tricky one. The word - which refers to a petty officer in charge of hull maintenance is not pronounced boats-wain Rather, ' +
    //    'it\'s bo-sun to reflect the salty pronunciation of sailors, as The Free Dictionary explains. Blue opinion poll conducted for the National Post.',
    'Eesti': //'Kõik tekkisid sinna ühe suve jooksul.',
        'Peremehe sõnul oli tal sauna räästa alla üks laud löödud ja need pesad tekkisid sinna kõik ühe suve jooksul. '
            '"Kuna saun paikneb tagaseinaga vastu metsa, siis ei käinud suve jooksul sealt keegi läbi ja nii said linnud segamatult ehitada. '
            'Tundub, et üks poolik pesa oli neil seal veel." Andrus lindude käitumises erilist elevust ega saginat ei märganud. "Tundub, et oli suur ja sõbralik pereõrs."',
  };

  /*
  static final Map<String, Map<String, dynamic>> processing = {
    'English': {
      'processor': EngProcessor(),
      'synth': FastSpeech('fastspeech2_quant'),
      'vocoder': Vocoder('MBMelGan'),
      'voices': ['English'],
    },
    'Eesti': {
      'processor': EstProcessor(),
      'synth': FastSpeech(
          'fastspeech2-10voice-400k_quant'), //TransformerTTS('albert'),
      'vocoder': Vocoder(
          'mbmelgan-generator-2200k'), //Vocoder('MBMelGan')  TorchVocoder('own_1265k_generator_v1.ptl')
      'voices': [
        //'Vesta
        'Mari',
        'Tambet',
        'Liivika',
        'Kalev',
        'Külli',
        'Meelis',
        'Albert',
        'Indrek',
        'Vesta', //
        'Peeter',
      ],
    }
  };
  */

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
          title: 'Text to Speech',
          langs: langs,
          //processing: processing,
          defaultText: defaultText),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {Key? key,
      required this.title,
      required this.langs,
      //required this.processing,
      required this.defaultText})
      : super(key: key);

  final String title;
  final List<String> langs;
  //final Map<String, Map<String, dynamic>> processing;
  final Map<String, String> defaultText;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _lang = 'Eesti';
  String fieldText =
      /*
      'I, I will be king. And you, you will be queen. '
      'Though nothing will drive them away. '
      'We can beat them just for one day. '
      'We can be heroes just for one day.';
      */
      'Vesi ojakeses vaikselt vuliseb. '
      'Ta endal laulu laulab, laulab uniselt. '
      'Ta vahtu tekitab, on külm. '
      'Ta päikest peegeldab, on külm.';
  final TtsPlayer _audioPlayer = TtsPlayer();
  double _speed = 1.0;
  int _synthvoice = 0;
  mProcessor processor = EstProcessor();
  AbstractModule synth =
      FastSpeech('fastspeech2-10voice-400k_quant'); //TransformerTTS('albert'),
  Vocoder vocoder = Vocoder(
      'mbmelgan-generator-2200k'); //Vocoder('MBMelGan')  TorchVocoder('own_1265k_generator_v1.ptl')
  List<String> voices = [
    //'Vesta',
    'Mari',
    'Tambet',
    'Liivika',
    'Kalev',
    'Külli',
    'Meelis',
    'Albert',
    'Indrek',
    'Vesta', //
    'Peeter',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _dropDownLanguage(),
                  _dropDownVoiceOrLabel(),
                ],
              ),
              //const Spacer(),
              _speedControl(),
              _inputTextField(),
              _speakStopButtons(),
            ],
          ),
        ),
      ),
    );
  }

  _dropDownLanguage() {
    return DropdownButton<String>(
      items: widget.langs.map((String dropDownItem) {
        return DropdownMenuItem<String>(
          value: dropDownItem,
          child: Text(dropDownItem),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _lang = value!;
          fieldText = widget.defaultText[value]!;
          if (value == 'English') {
            processor = EngProcessor();
            synth = FastSpeech('fastspeech2_quant');
            vocoder = Vocoder('MBMelGan');
            voices = ['English'];
          } else if (value == 'Eesti') {
            processor = EstProcessor();
            synth = FastSpeech(
                'fastspeech2-10voice-400k_quant'); //TransformerTTS('albert'),
            vocoder = Vocoder(
                'mbmelgan-generator-2200k'); //Vocoder('MBMelGan')  TorchVocoder('own_1265k_generator_v1.ptl')
            voices = [
              //'Vesta',
              'Mari',
              'Tambet',
              'Liivika',
              'Kalev',
              'Külli',
              'Meelis',
              'Albert',
              'Indrek',
              'Vesta', //
              'Peeter',
            ];
          }
        });
      },
      value: _lang,
    );
  }

  _dropDownVoiceOrLabel() {
    if (voices.length == 1) {
      setState(() {
        _synthvoice = 0;
      });
      return Text(voices[0]);
    } else {
      //List<DropdownMenuItem<String>> dropDownList =
      return DropdownButton<String>(
        items: voices
            .map((String voice) => DropdownMenuItem<String>(
                  child: Text(voice),
                  value: voice,
                ))
            .toList(),
        onChanged: (chosen) {
          setState(() {
            _synthvoice = voices.indexOf(chosen!);
          });
        },
        value: voices[_synthvoice],
      );
    }
  }

  _speedControl() {
    return Column(
      children: [
        Text(_lang == 'English' ? 'Speed:' : 'Kiirus:'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            _radioButton('Slow', 'Aeglane', 1.2),
            _radioButton('Normal', 'Tavaline', 1.0),
            _radioButton('Fast', 'Kiire', 0.8),
          ],
        ),
      ],
    );
  }

  _radioButton(String engText, String estText, double speed) {
    return Expanded(
      child: ListTile(
        title: Text(_lang == 'English' ? engText : estText),
        leading: Radio(
          value: speed,
          groupValue: _speed,
          onChanged: (double? value) {
            setState(() {
              _speed = value!;
            });
          },
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      ),
    );
  }

  _inputTextField() {
    return TextField(
        decoration: InputDecoration(
          hintText: fieldText,
        ),
        minLines: 1,
        maxLines: 10,
        onChanged: (text) => setState(() {
              fieldText = text;
            }));
  }

  _speakStopButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        TextButton(
          onPressed: _textToSpeech,
          child: Text(_lang == 'English' ? 'Speak' : 'Kõnele'),
        ),
        TextButton(
          onPressed: _audioPlayer.stopAudio,
          child: Text(_lang == 'English' ? 'Stop' : 'Peata'),
        ),
      ],
    );
  }

  List<String> _splitSentences() {
    String remainingText = fieldText;
    RegExp sentenceSplit = RegExp(r'([,;!?]"? )|(\."? "?(?![a-zäöüõšž]))');
    String leadingText = '';
    List<String> sentences = [];
    while (sentenceSplit.hasMatch(remainingText)) {
      RegExpMatch match = sentenceSplit.firstMatch(remainingText)!;
      if (match.group(1) != null &&
          match.group(1)!.contains(',') &&
          (leadingText.length + match.start < 15 ||
              match.end - match.start < 15) &&
          match.end < remainingText.length) {
        leadingText += remainingText.substring(0, match.end);
        remainingText = remainingText.substring(match.end);
        continue;
      }
      sentences.add(leadingText + remainingText.substring(0, match.start));
      leadingText = '';
      remainingText = remainingText.substring(match.end);
    }
    sentences
        .add(leadingText + remainingText.replaceAll(RegExp(r'[.!?]"?$'), '.'));
    log('Split sentences:' + sentences.toString());
    //sentences.add(' ');
    return sentences;
  }

  _textToSpeech() async {
    int id = 0;
    for (String sentence in _splitSentences()) {
      List<int> inputIds = processor.textToIds(sentence);
      List output = synth.getMelSpectrogram(inputIds, _synthvoice, _speed);
      output = vocoder.getAudio(output);

      List<double> audioBytes = [];
      if (output[0].length > 1) {
        for (int i = 0; i < output[0].length; i++) {
          audioBytes.add(output[0][i][0]);
        }
      } else {
        audioBytes = output[0][0];
      }
      /*
      while (_audioPlayer.isPlaying()) {
        continue;
      }
      */
      await _audioPlayer.playAudio(sentence, audioBytes, _speed, id);
      if (id >= 2) {
        id = 0;
      } else {
        id++;
      }
    }
  }
}
