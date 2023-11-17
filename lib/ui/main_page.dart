import 'dart:io' show Platform;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:neurokone/ui/page_view.dart';
import 'package:neurokone/synth/system_channel.dart';
import 'package:neurokone/ui/header.dart';
import 'package:neurokone/ui/voice.dart';
import 'package:neurokone/synth/tts.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  double voiceTileHeight = 52;

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

  //Shows instructions the first time the app is opened
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
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Semantics(
                  hidden: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      widget.langText['engine']!,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                ),
                _ttsEngineChoice(),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: _speedControl(),
                ),
                _inputTextField(),
                _speakStopButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //Voice selection and system's tts engine settings button.
  _ttsEngineChoice() {
    return Flex(
      direction: Axis.horizontal,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: _dropDownVoices(),
        ),
        _ttsSettingsIconButton(),
      ],
    );
  }

  //Dropdown menu button for synthesis voice selection
  _dropDownVoices() {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<Voice>(
        iconStyleData: IconStyleData(
          icon: Container(),
        ),
        customButton: _voiceBox(_currentNativeVoice, arrow: true),
        menuItemStyleData: MenuItemStyleData(padding: EdgeInsets.all(0)),
        dropdownStyleData: DropdownStyleData(
          padding: EdgeInsets.all(0),
          offset: Offset(0, voiceTileHeight),
          elevation: 16,
          decoration: BoxDecoration(color: Colors.transparent),
        ),
        isExpanded: true,
        value: _currentNativeVoice,
        items: ([Voice('system', Colors.black)] + Variables.voices)
            .map((voice) => DropdownMenuItem(
                  value: voice,
                  child: _voiceBox(voice),
                ))
            .toList(),
        onChanged: (item) {
          setState(() {
            _currentNativeVoice = item!;
            isSystemVoice = item.getName() == 'system' ? true : false;
          });
        },
      ),
    );
  }

  //Component that represents a voice in the dropdown list.
  _voiceBox(Voice voice, {bool arrow = false}) {
    return Container(
      decoration: BoxDecoration(
        color: voice.getColor(),
        border: (voice == _currentNativeVoice && !arrow)
            ? Border.all(
                color: Colors.blueAccent,
                width: 2,
              )
            : null,
        borderRadius: const BorderRadius.all(
          Radius.circular(16),
        ),
      ),
      height: voiceTileHeight,
      child: _boxContents(voice, arrow),
    );
  }

  //Contents in the voice representing box
  _boxContents(Voice voice, bool arrow) {
    String voiceName = voice.getName() == 'system'
        ? widget.langText['system']!
        : voice.getName();
    Center speaker = Center(
      child: Text(
        voiceName,
        semanticsLabel:
            arrow ? widget.langText['engine']! + " " + voiceName : voiceName,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 20,
          //fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        overflow: TextOverflow.visible,
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Container(),
        speaker,
        arrow
            ? Icon(
                Icons.arrow_drop_down,
                size: 28,
                color: Colors.white,
              )
            : Container(),
      ],
    );
  }

  //Takes the user to Android 'Text-to-speech output' settings.
  _ttsSettingsIconButton() {
    return SizedBox(
      height: voiceTileHeight,
      child: Semantics(
        label: widget.langText['TTS settings'],
        child: IconButton(
          icon: Icon(
            Icons.settings,
          ),
          onPressed: () async {
            isIOS
                ? await Navigator.pushNamed(context, 'select')
                : await AndroidIntent(
                        action: 'com.android.settings.TTS_SETTINGS')
                    .launch();
          },
        ),
      ),
    );
  }

  //A slider for voice speaking speed with minimum 0.5 and maximum 1.9 value.
  _speedControl() {
    return Wrap(
      direction: Axis.horizontal,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Semantics(
          hidden: true,
          child: _tempoText(),
        ),
        IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _tempoSlider(),
              _tempoResetButton(),
            ],
          ),
        ),
      ],
    );
  }

  _tempoText() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Text(
        widget.langText['tempo']!,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  _tempoResetButton() {
    return SizedBox(
      width: 98,
      child: TextButton(
        onPressed: _currentNativeVoice.getName() == "system"
            ? null
            : () => setState(() {
                  this._speed = 1.0;
                }),
        style: ButtonStyle(
          alignment: Alignment.center,
        ),
        child: Text(
          widget.langText['reset']!,
          semanticsLabel: widget.langText['resetLabel'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  _tempoSlider() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _sliderEdgeIcon(Variables.slowTempoIconPath),
        _slider(),
        _sliderEdgeIcon(Variables.fastTempoIconPath),
      ],
    );
  }

  _sliderEdgeIcon(iconPath) {
    return SvgPicture.asset(
      iconPath,
      colorFilter: ColorFilter.mode(
        _currentNativeVoice.getName() == "system" ? Colors.grey : Colors.blue,
        BlendMode.srcIn,
      ),
      fit: BoxFit.fitWidth,
    );
  }

  _slider() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.45,
      child: SliderTheme(
        data: SliderThemeData(
          overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
        ),
        child: Slider(
          thumbColor: Colors
              .blue, //_currentVoice.getColor(), //const Color.fromARGB(255, 49, 133, 255),
          min: 0.5,
          max: 1.9,
          value: _speed,
          label: widget.langText['slider']! + ' ' + _speed.toString(),
          onChanged: _currentNativeVoice.getName() == "system"
              ? null
              : (value) => setState(() {
                    _speed = value;
                  }),
          semanticFormatterCallback: (double value) {
            value = (value * 100).round() / 100;
            switch (value) {
              case 1.0:
                return '${widget.langText['slider']!} ${widget.langText['normal']!}';
              case 0.5:
                return '${widget.langText['slider']!} ${widget.langText['minimum']!}';
              case 1.9:
                return '${widget.langText['slider']!} ${widget.langText['maximum']!}';
              default:
                return '${widget.langText['slider']!} $value ';
            }
          },
        ),
      ),
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
    return Semantics(
      label: widget.langText['clearLabel'],
      child: IconButton(
        padding: const EdgeInsets.all(0),
        onPressed: () => setState(() {
          _textEditingController.clear();
        }),
        icon: Icon(
          Icons.clear,
          color: Colors.black54,
        ),
        splashRadius: 10,
      ),
    );
  }

  _copyButton() {
    return Semantics(
      label: widget.langText['copyLabel'],
      child: IconButton(
        onPressed: () => Clipboard.setData(ClipboardData(text: _fieldText))
            .then((result) =>
                Fluttertoast.showToast(msg: widget.langText['copy']!)),
        icon: Icon(
          Icons.copy,
          color: Colors.black54,
        ),
        splashRadius: 10,
      ),
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
