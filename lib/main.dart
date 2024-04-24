import 'package:flutter_localizations/flutter_localizations.dart';
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
  final SystemChannel channel = SystemChannel();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('et', 'ET'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      title: 'TartuNLP',
      theme: ThemeData(
        primarySwatch: themeColor,
      ),
      initialRoute: 'home',
      routes: {
        'instructions': (context) => InstructionsPage(
              lang: lang,
              switchLangs: switchLanguages,
            ),
        'home': (context) => MainPage(
              lang: lang,
              switchLangs: switchLanguages,
              channel: channel,
            ),
        //unused
        'about': (context) => AboutPage(
              lang: lang,
              switchLangs: switchLanguages,
            ),
        //iOS only
        'select': (context) => LanguageSelectionPage(
              lang: lang,
              switchLangs: switchLanguages,
              channel: channel,
            ),
      },
    );
  }

  //Switch app language
  void switchLanguages(String newLang) {
    setState(() {
      lang = newLang;
    });
  }
}
