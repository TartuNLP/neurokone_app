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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Text to Speech', langs: langs),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.title,
    required this.langs,
  }) : super(key: key);

  final String title;
  final List<String> langs;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _lang = 'Eesti';
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
  TextEditingController textEditingController = TextEditingController();
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
        textEditingController.clear();
        setState(() {
          _lang = value!;
          fieldText = defaultText[value]!;
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
              _speed = speed;
            });
          },
        ),
        onTap: () => setState(() {
          _speed = speed;
        }),
        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      ),
    );
  }

  _inputTextField() {
    return TextField(
        decoration: InputDecoration(hintText: fieldText),
        minLines: 1,
        maxLines: 10,
        controller: textEditingController,
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

/*
  List<String> _splitSentences() {
    String remainingText = fieldText;
    RegExp sentenceSplit = RegExp(
        r'([,;!?]"? )|([.!?]((" )| |( "))(?![a-zäöüõšž]))|((?<!^) ((ja)|(ning)|(ega)|(ehk)|(või)) )');
    String leadingText = '';
    List<String> sentences = [];
    while (sentenceSplit.hasMatch(remainingText)) {
      Iterable<RegExpMatch> matches = sentenceSplit.allMatches(remainingText);
      RegExpMatch match = matches.first;
      if (match.group(1) != null && match.group(1)!.contains(RegExp('[.!?]')) ||
          (leadingText.length + match.start > 20 &&
                  remainingText.substring(match.start).length > 20) &&
              match.end < remainingText.length) {
        sentences.add(leadingText + remainingText.substring(0, match.start));
        leadingText = '';
        remainingText = remainingText
                .substring(match.start, match.end)
                .contains(RegExp(' ((ja)|(ning)|(ega)|(ehk)|(või)) '))
            ? remainingText.substring(match.start).trim()
            : remainingText.substring(match.end).trim();
        continue;
      }
      leadingText += remainingText.substring(0, match.end);
      remainingText = remainingText.substring(match.end).trim();
    }
    sentences
        .add(leadingText + remainingText.replaceAll(RegExp(r'[.!?]"?$'), '.'));
    log('Split sentences:' + sentences.toString());
    //sentences.add(' ');
    return sentences;
  }
*/

  List<String> _splitSentences() {
    String remainingText = fieldText;
    RegExp sentencesSplit =
        RegExp(r'[.!?]((((" )| |( "))(?![a-zäöüõšž]))|("?$))');
    RegExp sentenceSplit =
        RegExp(r'(?<!^)([,;!?]"? )|( ((ja)|(ning)|(ega)|(ehk)|(või)) )');
    RegExp strip = RegExp(r'^[,;!?]?"? ?');
    List<String> sentences = [];
    int currentSentId = 0;
    for (RegExpMatch match in sentencesSplit.allMatches(remainingText)) {
      String sentence = remainingText.substring(currentSentId, match.start);
      currentSentId = match.end;
      int currentCharId = 0;
      for (RegExpMatch split in sentenceSplit.allMatches(sentence)) {
        if (split.start > 20 + currentCharId &&
            split.end < sentence.length - 20) {
          sentences.add(sentence
                  .substring(currentCharId, split.start)
                  .replaceAll(strip, '') +
              '.');
          currentCharId = split.start;
        }
      }
      sentences
          .add(sentence.substring(currentCharId).replaceAll(strip, '') + '.');
    }
    log('Split sentences:' + sentences.toString());
    return sentences;
  }

  _textToSpeech() async {
    int id = 0;
    for (String sentence in _splitSentences()) {
      List output = processor.textToIds(sentence);
      output = synth.getMelSpectrogram(output, _synthvoice, _speed);
      output = vocoder.getAudio(output);

      List<double> audioBytes = [];
      if (output[0].length > 1) {
        for (int i = 0; i < output[0].length; i++) {
          audioBytes.add(output[0][i][0]);
        }
      } else {
        audioBytes = output[0][0];
      }
      await _audioPlayer.playAudio(sentence, audioBytes, _speed, id);
      if (id >= 2) {
        id = 0;
      } else {
        id++;
      }
    }
  }
}
