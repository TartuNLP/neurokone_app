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
  late List voicesList;

  @override
  void initState() {
    super.initState();
    _checkVoices();
  }

  _checkVoices() {
    voicesList = [];
    List defaults = widget.channel.getDefaults();
    for (String voice in widget.voices) {
      voicesList.add([voice, defaults.contains(voice)]);
    }
  }

  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = '<platform-view-type>';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};
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
                ListView.builder(
                  itemBuilder: (context, index) => TextButton(
                      onPressed: _toggleVoice(index),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(widget.voices[index][0]),
                          Text(widget.voices[index][1] as bool ? "✓" : ""),
                        ],
                      )),
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
    setState(() {
      voicesList[index][1] = !voicesList[index][1];
    });
    widget.channel.setNewVoices(voicesList);
  }

  _confirm() {
    widget.channel.save();
    Navigator.pop(context);
  }
}
