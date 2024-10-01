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
  late final Map<String, String> text;
  final String language;
  final Function switchLanguage;
  final SystemChannel channel;

  LanguageSelectionPage(
      {super.key,
      required this.language,
      required this.switchLanguage,
      required this.channel}) {
    text = vars.langs[language]!;
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

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return NewPage.createScaffoldView(
          appBarTitle: Header(widget.switchLanguage, widget.language),
          body: Column(
            children: [
              ListTile(
                onTap: () => _toggleVoices(),
                title: Text(
                  widget.text['allVoices']!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                width: MediaQuery.of(context).size.width,
                child: Scrollbar(
                  thumbVisibility: true,
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
              ),
              TextButton(
                onPressed: _confirm,
                child: Text(widget.text['selected']!),
              )
            ],
          ),
        );
      default:
        throw UnsupportedError('Unsupported platform view');
    }
  }

  _toggleVoices() {
    for (int index = 0; index < widget.voices.length; index++) {
      _toggleVoice(index);
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
