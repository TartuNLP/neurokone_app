import 'package:neurokone/synth/system_channel.dart';
import 'package:neurokone/ui/about_page.dart';
import 'package:neurokone/ui/main_page.dart';
import 'package:neurokone/ui/selection_page.dart';
import 'package:neurokone/ui/instructions_page.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TtsApp());
}

class TtsApp extends StatefulWidget {
  const TtsApp({Key? key}) : super(key: key);

  @override
  State<TtsApp> createState() => _TtsAppState();
}

class _TtsAppState extends State<TtsApp> {
  //Initialise app in Estonian by default
  String lang = 'Eesti';
  final MaterialColor themeColor = Colors.blue;
  final SystemChannel channel = new SystemChannel();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TartuNLP',
      theme: ThemeData(
        primarySwatch: this.themeColor,
      ),
      initialRoute: 'home',
      routes: {
        'instructions': (context) => InstructionsPage(
              lang: this.lang,
              switchLangs: this.switchLanguages,
            ),
        'home': (context) => MainPage(
              lang: this.lang,
              switchLangs: this.switchLanguages,
              channel: this.channel,
            ),
        'about': (context) => AboutPage(
              lang: this.lang,
              switchLangs: this.switchLanguages,
            ),
        'select': (context) => LanguageSelectionPage(
              lang: this.lang,
              switchLangs: this.switchLanguages,
              channel: this.channel,
            ),
      },
    );
  }

  void switchLanguages(String newLang) {
    setState(() {
      this.lang = newLang;
    });
  }
}
