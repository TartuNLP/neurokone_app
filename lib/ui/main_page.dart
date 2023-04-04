import 'dart:io' show Platform;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:eesti_tts/ui/header.dart';
import 'package:eesti_tts/ui/voice.dart';
import 'package:eesti_tts/synth/tts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:android_intent_plus/android_intent.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    Key? key,
    //required this.title,
    required this.lang,
    required this.langText,
    required this.switchLangs,
    //required this.changeColors,
    required this.voices,
  }) : super(key: key);

  //final String title;
  final String lang;
  final Map<String, String> langText;
  final Function switchLangs;
  //final Function changeColors;
  final List<Voice> voices;

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> with WidgetsBindingObserver {
  //Initial voice data.
  Voice _currentVoice = const Voice('Mari', Colors.red, '1');
  double voiceTileHeight = 48;

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
    //color = _currentVoice.getColor();
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
        if (isSystemVoice) tts.setDefaultEngine();
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
        title: Header(widget.switchLangs, widget.lang), //_appBar(),
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
    return DropdownButtonHideUnderline(
      child: ButtonTheme(
        //alignedDropdown: true,
        child: DropdownButton2(
          dropdownStyleData: DropdownStyleData(
              elevation: 16,
              decoration: BoxDecoration(color: Colors.transparent)),
          value: _currentVoice,
          items: widget.voices
              .map((Voice voice) => DropdownMenuItem(
                    value: voice,
                    child: _voiceBox(voice),
                  ))
              .toList(),
          selectedItemBuilder: (BuildContext ctxt) {
            return widget.voices.map<Widget>((Voice voice) {
              return DropdownMenuItem(child: _voiceBox(voice), value: voice);
            }).toList();
          },
          onChanged: (value) => setState(() {
            _currentVoice = value as Voice;
          }),
        ),
      ),
    );
    /*
        PopupMenuButton(
          color: Colors.transparent,
          offset: Offset(
              0, (widget.voices.indexOf(_currentVoice) + 1) * voiceTileHeight),
          elevation: 24,
          initialValue: _currentVoice,
          child: _voiceBox(_currentVoice, arrow: true),
          // Callback that sets the selected popup menu item.
          onSelected: (item) {
            setState(() {
              _currentVoice = item as Voice;
            });
          },
          itemBuilder: (context) => widget.voices
              .map((Voice voice) => PopupMenuItem(
                    value: voice,
                    child: _voiceBox(voice),
                  ))
              .toList(),
        ),*/
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
      //height: voiceTileHeight,
      constraints: BoxConstraints.expand(width: 250, height: 40),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Lottie.asset('assets/icons_logos/${voice.getIcon()}.json',
              animate: true),
          Text(
            voice.getName(),
            overflow: TextOverflow.visible,
          ),
          /*Visibility(
            child: Icon(Icons.arrow_drop_down),
            visible: arrow,
          ),*/
        ],
      ),
    );
  }

  //Takes the user to Android 'Text-to-speech output' settings.
  _ttsSettingsButton() {
    return TextButton(
      child: Text(widget.langText['Choose']!),
      onPressed:
          _openCustomTtsSelect, //isIOS ? _openCustomTtsSelect : _openAndroidTtsSettings,
    );
  }

  //Opens a view on iOS where custom speech synthesis engines can be enabled.
  _openCustomTtsSelect() {
    Navigator.pushNamed(context, '/select');
  }

  //Opens Android Text-to-Speech output settings screen.
  _openAndroidTtsSettings() async {
    await AndroidIntent(action: 'com.android.settings.TTS_SETTINGS').launch();
  }

  //A slider for voice speaking speed with minimum 0.5 and maximum 2.0 value.
  _speedControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(
          widget.langText['Tempo']!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(
          width: 55,
          child: Container(
            alignment: Alignment.centerRight,
            child: SvgPicture.asset(
              'assets/icons_logos/snail-clean.svg',
              color: Colors.blue, //this.color,
              //theme: SvgTheme(currentColor: _currentVoice.getColor()),
            ),
          ),
        ),
        Expanded(
          child: Slider(
            thumbColor: Colors
                .blue, //_currentVoice.getColor(), //const Color.fromARGB(255, 49, 133, 255),
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
              'assets/icons_logos/horse-clean.svg',
              color: Colors.blue, //this.color,
              //theme: SvgTheme(currentColor: _currentVoice.getColor()),
            ),
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
              hintText: widget.langText['Hint'],
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
            widget.langText['Speak']!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        //if (!isIOS)
        TextButton(
          onPressed: _stop,
          child: Text(widget.langText['Stop']!),
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
      tts.nativeTts!.audioPlayer.stopAudio();
      if (isNativePlaying) tts.stopNative = true;
      setState(() {
        isNativePlaying = false;
      });
    }
  }
}
