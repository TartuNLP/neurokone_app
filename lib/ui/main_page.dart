import 'dart:io' show Platform;
import 'dart:math';
import 'package:neurokone/ui/page_view.dart';
import 'package:neurokone/synth/system_channel.dart';
import 'package:neurokone/ui/header.dart';
import 'package:neurokone/ui/voice.dart';
import 'package:neurokone/synth/tts.dart';
import 'package:neurokone/variables.dart' as Variables;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:is_first_run/is_first_run.dart';

class MainPage extends StatefulWidget {
  final String lang;
  late final Map<String, String> langText;
  final Function switchLangs;
  final SystemChannel channel;

  MainPage({
    Key? key,
    required this.lang,
    required this.switchLangs,
    required this.channel,
  }) : super(key: key) {
    this.langText = Variables.langs[this.lang]!;
  }

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> with WidgetsBindingObserver {
  //Initial voice data.
  Voice _currentNativeVoice = Variables.voices[0];
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
    this._textEditingController = TextEditingController();
    this._textEditingController.addListener(() {
      setState(() {
        this._fieldText = _textEditingController.text;
      });
    });
    _initTts();
    WidgetsBinding.instance.addObserver(this);

    _firstTimeInstructions();
  }

  //Loads tts engines
  _initTts() async {
    tts = Tts(this.isIOS);

    // loads system default model
    tts.loadSystemDefaultEngine();
    _setHandlers();
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

  _firstTimeInstructions() async {
    if (await IsFirstRun.isFirstRun()) {
      Navigator.pushNamed(context, 'instructions');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        tts.loadSystemDefaultEngine();
        setState(() {});
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
    return NewPage.createScaffoldView(
      appBarTitle: Header(widget.switchLangs, widget.lang),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ttsEngineChoice(),
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
  _ttsEngineChoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.langText['engine']!,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _radioTile(_dropDownVoices(), false),
            _radioTile(_ttsSettingsButton(), true),
          ],
        ),
      ],
    );
  }

  //Text-to-speech voice option
  _radioTile(title, initialValue) {
    return Expanded(
      flex: 2,
      child: ListTile(
        contentPadding: EdgeInsets.all(10),
        title: title,
        horizontalTitleGap: 0,
        minLeadingWidth: 36,
        leading: Radio<bool>(
          visualDensity: const VisualDensity(
            horizontal: VisualDensity.minimumDensity,
            vertical: VisualDensity.minimumDensity,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          fillColor: MaterialStateColor.resolveWith((states) => Colors.green),
          focusColor: MaterialStateColor.resolveWith((states) => Colors.green),
          value: initialValue,
          groupValue: this.isSystemVoice,
          onChanged: (bool? value) {
            setState(() {
              this.isSystemVoice = value!;
            });
          },
        ),
      ),
    );
  }

  //Dropdown list of tts engine's voices.
  _dropDownVoices() {
    return DropdownButtonHideUnderline(
      child: ButtonTheme(
        child: PopupMenuButton(
          color: Colors.transparent,
          offset: Offset(0,
              Variables.voices.indexOf(_currentNativeVoice) * voiceTileHeight),
          elevation: 16,
          constraints: BoxConstraints(
            maxWidth: min(MediaQuery.of(context).size.width * 0.5, 200),
          ),
          initialValue: _currentNativeVoice,
          child: _voiceBox(_currentNativeVoice, false),
          // Callback that sets the selected popup menu item.
          onSelected: (item) {
            setState(() {
              _currentNativeVoice = item as Voice;
            });
          },
          itemBuilder: (context) => Variables.voices
              .map((Voice voice) => PopupMenuItem(
                    textStyle: TextStyle(),
                    padding: EdgeInsets.all(0),
                    value: voice,
                    child: _voiceBox(voice, true),
                  ))
              .toList(),
        ),
      ),
    );
  }

  //Component that represents a voice in the dropdown list.
  _voiceBox(Voice voice, bool hasSvg) {
    return Container(
      decoration: BoxDecoration(
        color: voice.getColor(),
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
      ),
      //height: voiceTileHeight,
      constraints: BoxConstraints.expand(
          width: min(MediaQuery.of(context).size.width * 0.5, 200),
          height: voiceTileHeight),
      child: _boxContents(voice, hasSvg),
    );
  }

  //Contents in the voice representing box
  _boxContents(Voice voice, bool hasSvg) {
    return Row(
      mainAxisAlignment:
          hasSvg ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        if (hasSvg) Variables.voiceIcon(voice),
        Text(
          voice.getName(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }

  //Takes the user to Android 'Text-to-speech output' settings.
  _ttsSettingsButton() {
    return SizedBox(
      height: voiceTileHeight,
      child: TextButton(
        child: Text(
          widget.langText['choose']!,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13),
        ),
        onPressed: () async {
          isIOS
              ? await Navigator.pushNamed(context, 'select')
              : await AndroidIntent(action: 'com.android.settings.TTS_SETTINGS')
                  .launch();
        },
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(
                Color.fromARGB(255, 208, 225, 255)),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ))),
      ),
    );
  }

  //A slider for voice speaking speed with minimum 0.5 and maximum 2.0 value.
  _speedControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _tempoButton(),
        _sliderEdgeIcon(Variables.slowTempoIcon, Alignment.centerRight),
        _tempoSlider(),
        _sliderEdgeIcon(Variables.fastTempoIcon, Alignment.centerLeft),
      ],
    );
  }

  _tempoButton() {
    return TextButton(
      onPressed: () => setState(() {
        this._speed = 1.0;
      }),
      child: Text(
        widget.langText['tempo']!,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  //Icon indicating minimum or maximum speed
  _sliderEdgeIcon(icon, alignment) {
    return SizedBox(
      width: 55,
      child: Container(
        alignment: alignment,
        child: icon,
      ),
    );
  }

  _tempoSlider() {
    return Expanded(
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
              hintText: widget.langText['hint'],
              suffixIcon: _fieldText.isNotEmpty
                  ? Column(
                      children: [
                        _clearButton(),
                        _copyButton(),
                      ],
                    )
                  : null),
        ),
      ),
    );
  }

  _clearButton() {
    return IconButton(
      padding: const EdgeInsets.all(0),
      onPressed: () => setState(() {
        _textEditingController.clear();
      }),
      icon: const Icon(Icons.clear),
    );
  }

  _copyButton() {
    return IconButton(
      onPressed: () => Clipboard.setData(
        ClipboardData(text: _fieldText),
      ),
      icon: const Icon(Icons.copy),
    );
  }

  _speakStopButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _speakButton(),
        _stopButton(),
      ],
    );
  }

  //Speak button that triggers the models to synthesize audio from the input text.
  //Speak button is enabled only when there is text in the textfield.
  //Speak button is the same color as the selected voice from dropdown.
  _speakButton() {
    return TextButton(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(
            _fieldText.isNotEmpty ? Colors.white : Colors.grey),
        backgroundColor: MaterialStateProperty.all<Color>(
            isSystemVoice ? Colors.black : _currentNativeVoice.getColor()),
        fixedSize: MaterialStateProperty.all<Size>(const Size.fromWidth(100.0)),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
        ),
      ),
      onPressed: _fieldText.isNotEmpty ? _speak : null,
      child: Text(
        widget.langText['speak']!,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  //Executes the text-to-speech.
  Future _speak() async {
    if (!isSystemVoice) isNativePlaying = true;
    tts.speak(_fieldText, _speed, isSystemVoice,
        isSystemVoice ? null : Variables.voices.indexOf(_currentNativeVoice));
  }

  //Button to stop ongoing synthesizing
  _stopButton() {
    return TextButton(
      style: ButtonStyle(
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
        ),
      ),
      onPressed: _stop,
      child: Text(widget.langText['stop']!),
    );
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
