import 'package:neurokone/ui/page_view.dart';
import 'package:logger/logger.dart';
import 'package:neurokone/synth/system_channel.dart';
import 'package:neurokone/ui/header.dart';
import 'package:neurokone/ui/voice.dart';
import 'package:neurokone/variables.dart' as vars;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

//iOS only page for enabling voices to the system
class LanguageSelectionPage extends StatefulWidget {
  final List<Voice> voices = vars.voices;
  late final Map<String, String> langText;
  final String lang;
  final Function switchLangs;
  final SystemChannel channel;

  LanguageSelectionPage(
      {super.key,
      required this.lang,
      required this.switchLangs,
      required this.channel}) {
    langText = vars.langs[lang]!;
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
    currentDefaults = widget.channel.getDefaultVoices();
  }

  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return NewPage.createScaffoldView(
          appBarTitle: Header(widget.switchLangs, widget.lang),
          body: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height - 150,
                width: MediaQuery.of(context).size.width,
                child: ListView.builder(
                  itemCount: widget.voices.length,
                  itemBuilder: (context, index) => ListTile(
                    onTap: () => _toggleVoice(index),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.voices[index].getName()),
                        Text(currentDefaults.contains(widget.voices[index])
                            ? "✓"
                            : ""),
                      ],
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: _confirm,
                child: Text(widget.langText['selected']!),
              )
            ],
          ),
        );
      default:
        throw UnsupportedError('Unsupported platform view');
    }
  }

  _toggleVoice(int index) {
    logger.d("id:$index");
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
