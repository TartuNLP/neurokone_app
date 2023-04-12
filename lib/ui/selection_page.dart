import 'package:logger/logger.dart';
import 'package:eesti_tts/synth/native_channel.dart';
import 'package:eesti_tts/ui/header.dart';
import 'package:eesti_tts/ui/voice.dart';
import 'package:eesti_tts/variables.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LanguageSelectionPage extends StatefulWidget {
  final List<String> voices =
      Variables.voices.map((Voice voice) => voice.getName()).toList();
  late final Map<String, String> langText;
  final String lang;
  final Function switchLangs;
  final NativeChannel channel;

  LanguageSelectionPage(
      {required this.lang, required this.switchLangs, required this.channel}) {
    langText = Variables.langs[this.lang]!;
  }

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  var logger = Logger();
  late List<bool> currentDefaults;

  @override
  void initState() {
    super.initState();
    _checkVoices();
  }

  _checkVoices() {
    List allDefaults = widget.channel.getDefaults();
    currentDefaults =
        widget.voices.map((voice) => allDefaults.contains(voice)).toList();
  }

  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      /*
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        );*/
      case TargetPlatform.iOS:
        return Scaffold(
            backgroundColor: const Color.fromARGB(255, 238, 238, 238),
            appBar: AppBar(
              backgroundColor: Colors.white,
              shadowColor: Colors.white,
              title: Header(widget.switchLangs, widget.lang),
            ),
            body: Column(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height - 150,
                  width: MediaQuery.of(context).size.width,
                  child: ListView.builder(
                    itemCount: widget.voices.length,
                    itemBuilder: (context, index) => ListTile(
                      onTap: () => _toggleVoice(index),
                      title: Container(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(widget.voices[index]),
                          Text(currentDefaults[index] ? "✓" : ""),
                        ],
                      )),
                    ),
                  ),
                ),
                TextButton(
                  child: Text(widget.langText['Selected']!),
                  onPressed: _confirm,
                )
              ],
            ));
      default:
        throw UnsupportedError('Unsupported platform view');
    }
  }

  _toggleVoice(int index) {
    bool newVal = !currentDefaults[index];
    logger.d("id:" + index.toString());
    setState(() {
      currentDefaults[index] = newVal;
    });
    widget.channel.setNewVoices(currentDefaults);
  }

  _confirm() async {
    widget.channel.save();
    Navigator.pop(context);
  }
}
