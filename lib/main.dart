import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:neurokone/synth/system_channel.dart';
import 'package:neurokone/ui/about_page.dart';
import 'package:neurokone/ui/main_page.dart';
import 'package:neurokone/ui/instructions_page.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'package:neurokone/variables.dart' as vars;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS || Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(450, 575),
      size: Size(450, 575),
      center: true,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const TtsApp());
}

class TtsApp extends StatefulWidget {
  const TtsApp({super.key});

  @override
  State<TtsApp> createState() => _TtsAppState();
}

class _TtsAppState extends State<TtsApp> {
  //Initialise app in Estonian by default
  String currentLanguage = vars.initialLanguage;
  final SystemChannel channel = SystemChannel();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      supportedLocales: vars.locales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      title: vars.appTitle,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: 'home',
      routes: {
        'instructions': (context) => InstructionsPage(
              language: currentLanguage,
              switchLanguage: switchLanguages,
            ),
        'home': (context) => MainPage(
              language: currentLanguage,
              switchLanguage: switchLanguages,
              channel: channel,
            ),
        //unused
        'about': (context) => AboutPage(
              language: currentLanguage,
              switchLanguage: switchLanguages,
            ),
      },
    );
  }

  //Switch app language
  void switchLanguages(String newLanguage) {
    setState(() {
      currentLanguage = newLanguage;
    });
  }
}
