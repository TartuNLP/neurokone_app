import 'package:eesti_tts/synth/native_channel.dart';
import 'package:eesti_tts/ui/main_page.dart';
import 'package:eesti_tts/ui/selection_page.dart';
import 'package:eesti_tts/variables.dart';
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
              switchLangs: this.switchLanguages,
              //changeColors: this.changeThemeColor,
            ),
        '/select': (context) => LanguageSelectionPage(
              lang: lang,
              switchLangs: this.switchLanguages,
              channel: new NativeChannel(Variables.channelPath),
            ),
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
