import 'package:eestitts/ui/page_view.dart';
import 'package:logger/logger.dart';
import 'package:eestitts/synth/system_channel.dart';
import 'package:eestitts/ui/header.dart';
import 'package:eestitts/ui/voice.dart';
import 'package:eestitts/variables.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LanguageSelectionPage extends StatefulWidget {
  final List<Voice> voices = Variables.voices;
  late final Map<String, String> langText;
  final String lang;
  final Function switchLangs;
  final SystemChannel channel;

  LanguageSelectionPage(
      {required this.lang, required this.switchLangs, required this.channel}) {
    this.langText = Variables.langs[this.lang]!;
  }

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  var logger = Logger();
  late List<Voice> currentDefaults;

  @override
  void initState() {
    super.initState();
    this.currentDefaults = widget.channel.getDefaultVoices();
  }

  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return NewPage.createScaffoldView(
          appBarTitle: Header(widget.switchLangs, widget.lang),
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
                        Text(widget.voices[index].getName()),
                        Text(currentDefaults.contains(widget.voices[index])
                            ? "✓"
                            : ""),
                      ],
                    )),
                  ),
                ),
              ),
              TextButton(
                child: Text(widget.langText['selected']!),
                onPressed: _confirm,
              )
            ],
          ),
        );
      default:
        throw UnsupportedError('Unsupported platform view');
    }
  }

  _toggleVoice(int index) {
    logger.d("id:" + index.toString());
    Voice voice = widget.voices[index];
    if (currentDefaults.contains(voice)) {
      for (Voice defaultVoice in currentDefaults) {
        if (defaultVoice == voice) {
          setState(() {
            currentDefaults.remove(voice);
          });
          break;
        }
      }
    } else {
      setState(() {
        currentDefaults.add(voice);
      });
    }
    widget.channel.setNewVoices(currentDefaults);
  }

  _confirm() async {
    widget.channel.save();
    Navigator.pop(context);
  }
}
