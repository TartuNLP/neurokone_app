import 'package:eestitts/synth/system_channel.dart';
import 'package:eestitts/ui/main_page.dart';
import 'package:eestitts/ui/selection_page.dart';
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
      initialRoute: '/',
      routes: {
        '/': (context) => MainPage(
              //title: 'Neurokõne',
              lang: this.lang,
              switchLangs: this.switchLanguages,
              channel: this.channel,
              //changeColors: this.changeThemeColor,
            ),
        '/select': (context) => LanguageSelectionPage(
              lang: this.lang,
              switchLangs: this.switchLanguages,
              channel: this.channel,
            ),
      },
    );
  }

  /*
  void changeThemeColor(MaterialColor color) {
    setState(() {
      this.themeColor = color;
    });
  }
  */

  void switchLanguages(String newLang) {
    setState(() {
      this.lang = newLang;
    });
  }
}
