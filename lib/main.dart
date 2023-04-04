import 'package:eesti_tts/ui/main_page.dart';
import 'package:eesti_tts/ui/selection_page.dart';
import 'package:eesti_tts/ui/voice.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const TtsApp());
}

class TtsApp extends StatefulWidget {
  const TtsApp({Key? key}) : super(key: key);

  //Defaults for Estonian and English UI.
  static final Map<String, Map<String, String>> langs = {
    'Eesti': {
      'Choose': 'Süsteemiseadete hääl',
      'Speak': 'Räägi',
      'Stop': 'Peata',
      'Slow': 'Aeglane',
      'Fast': 'Kiire',
      'Dropdown': 'Vali hääl',
      'Hint': 'Kirjuta siia...',
      'Tempo': 'Tempo',
      'Selected': 'Lubatud Keeled',
    },
    'English': {
      'Choose': 'Default system voice',
      'Speak': 'Speak',
      'Stop': 'Stop',
      'Slow': 'Slow',
      'Fast': 'Fast',
      'Dropdown': 'Choose voice',
      'Hint': 'Write here...',
      'Tempo': 'Tempo',
      'Selected': 'Enabled Languages',
    }
  };

  //Voice data: speakers, their background colors and decoration icon file names.
  static final List<Voice> voices = [
    const Voice('Mari', Colors.red, /*Color(0xFFEF6650), */ '1'),
    const Voice('Tambet', Colors.purple, /*Color(0xFF7268D8), */ '2'),
    const Voice('Liivika', Colors.yellow, /*Color(0xFFE0B12B), */ '3'),
    const Voice('Kalev', Colors.cyan, /*Color(0xFF4DB6AC), */ '4'),
    const Voice('Külli', Colors.red, /*Color(0xFFEF6650), */ '3'),
    const Voice('Meelis', Colors.purple, /*Color(0xFF7268D8), */ '2'),
    const Voice('Albert', Colors.yellow, /*Color(0xFFE0B12B), */ '1'),
    const Voice('Indrek', Colors.cyan, /*Color(0xFF4DB6AC), */ '3'),
    const Voice('Vesta', Colors.red, /*Color(0xFFEF6650), */ '2'),
    const Voice('Peeter', Colors.purple, /*Color(0xFF7268D8), */ '4'),
  ];

  @override
  State<TtsApp> createState() => _TtsAppState();
}

class _TtsAppState extends State<TtsApp> {
  //Initialise app in Estonian by default
  String lang = 'Eesti';
  final MaterialColor themeColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TartuNLP',
      theme: ThemeData(
        primarySwatch: themeColor,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MainPage(
            //title: 'Neurokõne',
            lang: lang,
            langText: TtsApp.langs[lang]!,
            switchLangs: this.switchLanguages,
            //changeColors: this.changeThemeColor,
            voices: TtsApp.voices),
        '/select': (context) => LanguageSelectionPage(
            langText: TtsApp.langs[lang]!,
            lang: lang,
            switchLangs: this.switchLanguages),
      },
    );
  }

  /*
  void changeThemeColor(MaterialColor color) {
    setState(() {
      themeColor = color;
    });
  }
  */

  void switchLanguages(String newLang) {
    setState(() {
      lang = newLang;
    });
  }
}
