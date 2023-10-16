import 'dart:io' show Platform;
import 'dart:math';
import 'package:fluttertoast/fluttertoast.dart';
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
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: NewPage.createScaffoldView(
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
          child: _voiceBox(_currentNativeVoice, arrow: true),
          // Callback that sets the selected popup menu item.
          onSelected: (item) {
            setState(() {
              _currentNativeVoice = item;
            });
          },
          itemBuilder: (context) => Variables.voices
              .map((Voice voice) => PopupMenuItem(
                    textStyle: TextStyle(),
                    padding: EdgeInsets.all(0),
                    value: voice,
                    child: _voiceBox(voice),
                  ))
              .toList(),
        ),
      ),
    );
  }

  //Component that represents a voice in the dropdown list.
  _voiceBox(Voice voice, {bool arrow = false}) {
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
      child: _boxContents(voice, arrow),
    );
  }

  //Contents in the voice representing box
  _boxContents(Voice voice, bool arrow) {
    Center speaker = Center(
      child: Text(
        voice.getName(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          //fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        overflow: TextOverflow.visible,
      ),
    );
    if (arrow) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(),
          speaker,
          Icon(Icons.arrow_drop_down),
        ],
      );
    } else
      return speaker;
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _tempoText(),
        _tempoSlider(),
        _resetButton(),
      ],
    );
  }

  _tempoText() {
    return Text(
      widget.langText['tempo']!,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  _resetButton() {
    return TextButton(
      onPressed: () => setState(() {
        this._speed = 1.0;
      }),
      child: Text(
        widget.langText['reset']!,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  _tempoSlider() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          //_sliderEdgeIcon(Variables.slowTempoIcon, Alignment.centerRight),
          Variables.slowTempoIcon,
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                thumbColor: Colors
                    .blue, //_currentVoice.getColor(), //const Color.fromARGB(255, 49, 133, 255),
                min: 0.5,
                max: 2.0,
                value: _speed,
                label: widget.langText['slider']! + ' ' + _speed.toString(),
                onChanged: (value) => setState(() {
                  _speed = value;
                }),
                semanticFormatterCallback: (double value) {
                  return '${widget.langText['slider']!} ${(value * 100).round()}%';
                },
              ),
            ),
          ),
          //_sliderEdgeIcon(Variables.fastTempoIcon, Alignment.centerLeft),
          Variables.fastTempoIcon,
        ],
      ),
    );
  }

  //Icon indicating minimum or maximum speed
  _sliderEdgeIcon(icon, alignment) {
    return Container(
      alignment: alignment,
      child: icon,
    );
  }

  //Textfield for input text, with copy and clear buttons.
  _inputTextField() {
    return Center(
      child: SizedBox(
        //width: MediaQuery.of(context).size.width * 0.9,
        child: Stack(
          children: [
            TextField(
              minLines: 7,
              maxLines: 25,
              controller: _textEditingController,
              decoration: InputDecoration(
                hintText: widget.langText['hint'],
                fillColor: Colors.white,
                filled: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(
                    color: Color.fromARGB(0, 0, 0, 0),
                    width: 2.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(
                    color: Color.fromARGB(102, 77, 182, 172),
                    width: 2.0,
                  ),
                ),
              ),
            ),
            if (_fieldText.isNotEmpty)
              Positioned(
                top: 0,
                right: 0,
                child: _clearButton(),
              ),
            if (_fieldText.isNotEmpty)
              Positioned(
                bottom: 0,
                right: 0,
                child: _copyButton(),
              )
          ],
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
      icon: const Icon(Icons.clear, color: Colors.black54),
      splashRadius: 10,
    );
  }

  _copyButton() {
    return IconButton(
      onPressed: () => Clipboard.setData(ClipboardData(text: _fieldText)).then(
          (result) => Fluttertoast.showToast(msg: widget.langText['copy']!)),
      icon: const Icon(Icons.copy, color: Colors.black54),
      splashRadius: 10,
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
        foregroundColor: MaterialStateProperty.all(Colors.white),
        backgroundColor: MaterialStateProperty.all<Color>(
            (isSystemVoice ? Colors.black : _currentNativeVoice.getColor())
                .withOpacity(_fieldText.isNotEmpty ? 1 : 0.5)),
        fixedSize: MaterialStateProperty.all<Size>(const Size.fromWidth(120.0)),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
        ),
      ),
      onPressed: _fieldText.isNotEmpty ? _speak : null,
      child: Text(
        widget.langText['speak']!,
        style: const TextStyle(
          fontSize: 15,
        ),
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
      child: Text(
        widget.langText['stop']!,
        style: TextStyle(
          fontSize: 15,
        ),
      ),
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
