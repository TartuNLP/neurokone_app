import 'dart:io' show Platform;
import 'package:eesti_tts/tts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:android_intent_plus/android_intent.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  //Defaults for Estonian and English UI.
  static final Map<String, Map<String, String>> langs = {
    'Eesti': {
      'Choose': 'Süsteemiseadete hääl',
      'Speak': 'Räägi',
      'Stop': 'Peata',
      'Slow': 'Aeglane',
      'Fast': 'Kiire',
      'Dropdown': 'Vali hääl',
      'Hint': 'Kirjuta siia...',
      'Tempo': 'Tempo',
    },
    'English': {
      'Choose': 'Default system voice',
      'Speak': 'Speak',
      'Stop': 'Stop',
      'Slow': 'Slow',
      'Fast': 'Fast',
      'Dropdown': 'Choose voice',
      'Hint': 'Write here...',
      'Tempo': 'Tempo',
    }
  };

  //Voice data: speakers, their background colors and decoration icon file names.
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
      home: MyHomePage(title: 'Neurokõne', langs: langs, voices: voices),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.title,
    required this.langs,
    required this.voices,
  }) : super(key: key);

  final String title;
  final Map<String, Map<String, String>> langs;
  final List<Voice> voices;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  //Initial voice data.
  Voice _currentVoice = const Voice('Mari', Colors.red, '1');
  String _lang = 'Eesti';

  //Speed of the synthetic voice.
  double _speed = 1.0;

  //Controller for the text in Textfield.
  late TextEditingController _textEditingController;
  String _fieldText = '';

  bool isSystemPlaying = false;
  bool isNativePlaying = false;

  bool get isIOS => Platform.isIOS;

  bool isSystemVoice = false;

  late Tts tts;

  //Every time the controller detects a change, the updated text is saved to _fieldText.
  //Also loads up the selected text to speech engine.
  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _textEditingController.addListener(() {
      setState(() {
        _fieldText = _textEditingController.text;
      });
    });
    _initTts();
    WidgetsBinding.instance.addObserver(this);
  }

  //Loads tts engine
  void _initTts() {
    tts = Tts(isIOS);
    if (isSystemVoice) {
      //initVoice();
      tts.initSystemTts();
      tts.setDefaultEngine();
      _setHandlers();
    } else {
      tts.initTtsNative();
    }
  }

  //Sets the handlers for the system's engine
  _setHandlers() {
    tts.systemTts.setStartHandler(() {
      setState(() {
        print("Playing");
        isSystemPlaying = true;
      });
    });

    tts.systemTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        isSystemPlaying = false;
      });
    });

    tts.systemTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        isSystemPlaying = false;
      });
    });

    tts.systemTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        isSystemPlaying = false;
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        tts.setDefaultEngine();
        print("app in resumed");
        break;
      case AppLifecycleState.inactive:
        print("app in inactive");
        break;
      case AppLifecycleState.paused:
        print("app in paused");
        break;
      case AppLifecycleState.detached:
        print("app in detached");
        break;
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    if (isSystemVoice) tts.systemTts.stop();
  }

  //Creates a scrollable screen in case content doesn't fit.
  //Upmost component is dropdown list of voices on the left and two language toggle buttons on the right.
  //Next is a slider for the speed parameter.
  //Next is textfield for input text.
  //Lastly, speak/predict and play button.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 238, 238),
      appBar: AppBar(
        backgroundColor: Colors.white,
        shadowColor: Colors.white,
        title: _appBar(),
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
                  //isIOS ? _dropDownVoices() : _radioEngines(),
                  _radioEngines(),
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

  //Appbar consisting of logo and UI language toggle switch.
  _appBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SvgPicture.asset('assets/icons_logos/neurokone-logo-clean.svg'),
        Spacer(),
        _langRadioButtons(),
      ],
    );
  }

  //Toggle switch between the native and system's tts engine.
  _radioEngines() {
    return Column(
      children: [
        ListTile(
          title: _dropDownVoices(),
          leading: Radio<bool>(
            fillColor: MaterialStateColor.resolveWith((states) => Colors.green),
            focusColor:
                MaterialStateColor.resolveWith((states) => Colors.green),
            value: false,
            groupValue: isSystemVoice,
            onChanged: (bool? value) {
              setState(() {
                isSystemVoice = value!;
              });
              _initTts();
            },
          ),
        ),
        ListTile(
          title: _ttsSettingsButton(),
          leading: Radio<bool>(
            fillColor: MaterialStateColor.resolveWith((states) => Colors.green),
            focusColor:
                MaterialStateColor.resolveWith((states) => Colors.green),
            value: true,
            groupValue: isSystemVoice,
            onChanged: (bool? value) {
              setState(() {
                isSystemVoice = value!;
              });
              _initTts();
            },
          ),
        ),
      ],
    );
  }

  //Dropdown list of tts engine's voices.
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
        hint: Text(widget.langs[_lang]!['Dropdown']!),
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

  //Component that represents a voice in the dropdown list.
  _voiceBox(Voice voice) {
    return Container(
      decoration: BoxDecoration(
        color: voice.getColor(),
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      height: 40,
      width: 120,
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

  //Takes the user to Android 'Text-to-speech output' settings.
  _ttsSettingsButton() {
    return TextButton(
      child: Text(widget.langs[_lang]!['Choose']!),
      onPressed: () async =>
          await AndroidIntent(action: 'com.android.settings.TTS_SETTINGS')
              .launch(),
    );
  }

  //Toggle buttons for UI language.
  _langRadioButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _radioButton('ET', 'Eesti'),
        _radioButton('EN', 'English'),
      ],
    );
  }

  //Button that, when selected, has a blueish background and is disabled.
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

  //A slider for voice speaking speed with minimum 0.5 and maximum 2.0 value.
  _speedControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(
          widget.langs[_lang]!['Tempo']!,
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

  //Textfield for input text, with copy and clear buttons.
  _inputTextField() {
    return Center(
      child: SizedBox(
        //width: MediaQuery.of(context).size.width * 0.9,
        child: TextField(
          minLines: 4,
          maxLines: 25,
          controller: _textEditingController,
          decoration: InputDecoration(
              hintText: widget.langs[_lang]!['Hint'],
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

  //Speak button that triggers the models to synthesize audio from the input text.
  //Button is enabled only when there is text in the textfield.
  //Button is the same color as the selected voice from dropdown.
  _speakStopButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(
                _fieldText.isNotEmpty ? Colors.white : Colors.grey),
            backgroundColor: MaterialStateProperty.all<Color>(
                isSystemVoice ? Colors.black : _currentVoice.getColor()),
            fixedSize:
                MaterialStateProperty.all<Size>(const Size.fromWidth(100.0)),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0),
                //side: const BorderSide(color: Colors.black12),
              ),
            ),
          ),
          onPressed: _fieldText.isNotEmpty ? _speak : null,
          child: Text(
            widget.langs[_lang]!['Speak']!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        //if (!isIOS)
        TextButton(
          onPressed: _stop,
          child: Text(widget.langs[_lang]!['Stop']!),
        ),
      ],
    );
  }

  //Executes the text-to-speech.
  Future _speak() async {
    if (!isSystemVoice) isNativePlaying = true;
    tts.speak(_fieldText, _speed,
        isSystemVoice ? null : widget.voices.indexOf(_currentVoice));
  }

  //Stops the synthesis.
  Future _stop() async {
    if (isSystemVoice) {
      var result = await tts.systemTts.stop();
      if (result == 1) setState(() => isSystemPlaying = false);
    } else {
      tts.nativeTts.audioPlayer.stopAudio();
      if (isNativePlaying) tts.stopNative = true;
      setState(() {
        isNativePlaying = false;
      });
    }
  }
}

class Voice {
  final String _name;
  final Color _color;
  final String _icon;

  String getName() {
    return _name;
  }

  Color getColor() {
    return _color;
  }

  String getIcon() {
    return _icon;
  }

  const Voice(this._name, this._color, this._icon);

  @override
  bool operator ==(Object other) => other is Voice && other._name == _name;

  @override
  int get hashCode => super.hashCode;
}
