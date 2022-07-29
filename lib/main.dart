import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:tflite_app/audio_player.dart';
//import 'package:tflite_app/processors/eng_processor.dart';
import 'package:tflite_app/processors/est_processor.dart';
import 'package:tflite_app/processors/processor.dart';
import 'package:tflite_app/synth/abstract_module.dart';
import 'package:tflite_app/synth/fastspeech.dart';
//import 'package:tflite_app/synth/transformer_tts.dart';
import 'package:tflite_app/synth/vocoder.dart';
//import 'package:tflite_app/synth/torch_vocoder.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'voice.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  //Voice data: speakers, their background colors and decoration icon file names
  static final List<Voice> voices = [
    const Voice('Mari', Color.fromARGB(255, 239, 102, 80), '1'),
    const Voice('Tambet', Color.fromARGB(255, 114, 104, 216), '2'),
    const Voice('Liivika', Color.fromARGB(255, 224, 177, 43), '3'),
    const Voice('Kalev', Color.fromARGB(255, 77, 182, 172), '4'),
    const Voice('Külli', Color.fromARGB(255, 239, 102, 80), '3'),
    const Voice('Meelis', Color.fromARGB(255, 114, 104, 216), '2'),
    const Voice('Albert', Color.fromARGB(255, 224, 177, 43), '1'),
    const Voice('Indrek', Color.fromARGB(255, 77, 182, 172), '3'),
    const Voice('Vesta', Color.fromARGB(255, 239, 102, 80), '2'),
    const Voice('Peeter', Color.fromARGB(255, 114, 104, 216), '4'),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TartuNLP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Neurokõne', voices: voices),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.title,
    required this.voices,
  }) : super(key: key);

  final String title;
  final List<Voice> voices;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  //Initial voice data
  Voice _currentVoice = const Voice('Mari', Colors.red, '1');
  String _lang = 'Eesti';

  //Defaults for Estonian and English UI
  static final Map<String, Map<String, String>> _langs = {
    'Eesti': {
      'Speak': 'Räägi',
      'Stop': 'Peata',
      'Slow': 'Aeglane',
      'Fast': 'Kiire',
      'Dropdown': 'Vali hääl',
      'Hint': 'Kirjuta siia...',
      'Tempo': 'Tempo',
    },
    'English': {
      'Speak': 'Speak',
      'Stop': 'Stop',
      'Slow': 'Slow',
      'Fast': 'Fast',
      'Dropdown': 'Choose voice',
      'Hint': 'Write here...',
      'Tempo': 'Tempo',
    }
  };

  //Speed of the synthetic voice
  double _speed = 1.0;

  //Controller for the text in Textfield
  late TextEditingController _textEditingController;
  String _fieldText = '';

  //For preprocessing text and numbers before synthesis
  final mProcessor _processor = EstProcessor();
  //Synthesis model
  final AbstractModule _synth = FastSpeech('fs2.v2_0-8k-bs10-200k_quant');
  //Vocoder model
  final Vocoder _vocoder = Vocoder(
      'hifigan-generator-0-8k-1320k-finetuned-380k'); //Vocoder('MBMelGan')
  //Player of the predicted audio
  final TtsPlayer _audioPlayer = TtsPlayer();

  //Every time the controller detects a change, the updated text is saved to _fieldText
  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _textEditingController.addListener(() {
      setState(() {
        _fieldText = _textEditingController.text;
      });
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  //Creates a scrollable screen in case content doesn't fit
  //Upmost component is dropdown list of voices on the left and two language toggle buttons on the right
  //Next is a slider for the speed parameter.
  //Next is textfield for input text
  //Lastly, speak/predict and play button
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        title: SvgPicture.asset('assets/icons_logos/neurokone-logo-clean.svg'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _dropDownVoices(),
                      const Spacer(),
                      _langRadioButtons(),
                    ],
                  ),
                  _speedControl(),
                  _inputTextField(),
                  _speakStopButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //Dropdown list of voices
  _dropDownVoices() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
        color: _currentVoice.getColor(),
      ),
      child: DropdownButton(
        dropdownColor: Colors.transparent,
        hint: Text(_langs[_lang]!['Dropdown']!),
        value: _currentVoice,
        items: widget.voices.map((Voice voice) {
          return DropdownMenuItem<Voice>(
            value: voice,
            child: _voiceBox(voice),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _currentVoice = value as Voice;
          });
        },
      ),
    );
  }

  _voiceBox(Voice voice) {
    return Container(
      decoration: BoxDecoration(
        color: voice.getColor(),
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          Lottie.asset('assets/icons_logos/${voice.getIcon()}.json',
              animate: true),
          const SizedBox(
            width: 20,
          ),
          Text(voice.getName()),
          const SizedBox(
            width: 20,
          ),
        ],
      ),
    );
  }

  //Toggle buttons for UI language
  _langRadioButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _radioButton('ET', 'Eesti'),
        _radioButton('EN', 'English'),
      ],
    );
  }

  //Button has a blueish background and is disabled if it is selected
  _radioButton(String langCode, String language) {
    return TextButton(
        style: _lang == language
            ? ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    const Color.fromARGB(255, 228, 251, 255)))
            : null,
        onPressed: _lang == language
            ? null
            : () => setState(() {
                  _lang = language;
                }),
        child: Text(langCode));
  }

  //A slider for voice speaking speed with minimum 0.5 and maximum 2.0 value
  _speedControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(
          _langs[_lang]!['Tempo']!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(
          width: 55,
          child: Container(
            alignment: Alignment.centerRight,
            child: SvgPicture.asset(
                'assets/icons_logos/snail-clean.svg'), //Text(_langs[_lang]!['Slow']!),
          ),
        ),
        Expanded(
          child: Slider(
            thumbColor: const Color.fromARGB(255, 49, 133, 255),
            min: 0.5,
            max: 2.0,
            value: _speed,
            onChanged: (value) => setState(() {
              _speed = value;
            }),
          ),
        ),
        SizedBox(
          width: 55,
          child: Container(
            alignment: Alignment.centerLeft,
            child: SvgPicture.asset(
                'assets/icons_logos/horse-clean.svg'), //Text(_langs[_lang]!['Fast']!),
          ),
        ),
      ],
    );
  }

  //Textfield for input text, with copy and clear buttons
  _inputTextField() {
    return Center(
      child: SizedBox(
        //width: MediaQuery.of(context).size.width * 0.9,
        child: TextField(
          minLines: 4,
          maxLines: 25,
          controller: _textEditingController,
          decoration: InputDecoration(
              hintText: _langs[_lang]!['Hint'],
              suffixIcon: _fieldText.isNotEmpty
                  ? Column(
                      children: [
                        IconButton(
                          padding: const EdgeInsets.all(0),
                          onPressed: () => setState(() {
                            _textEditingController.clear();
                          }),
                          icon: const Icon(Icons.clear),
                        ),
                        IconButton(
                          onPressed: () => Clipboard.setData(
                            ClipboardData(text: _fieldText),
                          ),
                          icon: const Icon(Icons.copy),
                        )
                      ],
                    )
                  : null),
        ),
      ),
    );
  }

  //Speak button that triggers the models to synthesize audio from the input text
  //Button is enabled only when there is text in the textfield
  //Button is the same color as the selected voice from dropdown
  _speakStopButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(
                _fieldText.isNotEmpty ? Colors.white : Colors.grey),
            backgroundColor:
                MaterialStateProperty.all<Color>(_currentVoice.getColor()),
            fixedSize:
                MaterialStateProperty.all<Size>(const Size.fromWidth(100.0)),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0),
                //side: const BorderSide(color: Colors.black12),
              ),
            ),
          ),
          onPressed: _fieldText.isNotEmpty ? _textToSpeech : null,
          child: Text(
            _langs[_lang]!['Speak']!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        /*
        TextButton(
          onPressed:
              _fieldText.isNotEmpty && _speaking ? _stopTextToSpeech : null,
          child: Text(_langs[_lang]!['Stop']!),
        ),
        */
      ],
    );
  }

  //Splits the input text into sentences, if the sentence is too long then tries to split where there are pauses
  List<String> _splitSentences() {
    String remainingText = _fieldText;
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

  //Text preprocessing, models' inference and playing of the resulting audio
  //Saves maximum of 3 audio files to memory.
  _textToSpeech() async {
    int id = 0;
    int voiceId = widget.voices.indexOf(_currentVoice);
    double speed = 1.0 / _speed;
    for (String sentence in _splitSentences()) {
      List output = _processor.textToIds(sentence);
      output = _synth.getMelSpectrogram(output, voiceId, speed);
      output = _vocoder.getAudio(output);

      List<double> audioBytes = [];
      if (output[0].length > 1) {
        for (int i = 0; i < output[0].length; i++) {
          audioBytes.add(output[0][i][0]);
        }
      } else {
        audioBytes = output[0][0];
      }
      await _audioPlayer.playAudio(sentence, audioBytes, id);
      if (id >= 2) {
        id = 0;
      } else {
        id++;
      }
    }
  }
}
