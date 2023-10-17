import 'package:neurokone/ui/voice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

final String packageName = 'com.tartunlp.neurokone';
final String appVersion = 'Neurokõne v1.0.4';

final String synthModel = 'fastspeech2-est';
final String vocModel = 'hifigan-est.v2';

//Defaults for Estonian and English UI.
const Map<String, Map<String, String>> langs = {
  'Eesti': {
    'loading': 'Mudelite laadimine...',
    'engine': 'Sünteeshääl:',
    'chooseVoice': 'Hääle valik',
    'TTS settings': 'Kõnesünteesi seaded',
    'about': 'Meist',
    'back': 'Tagasi',
    'instructions': 'Juhised',
    'introductionText':
        'Vali sünteeshääl, kirjuta midagi alla lahtrisse ning saad kuulata sünteesitud kõne.\n\nVasakpoolse sünteeshääle valiku puhul saad valida, kes meie häältest teksti esitab.\nParempoolse valiku puhul tuleb mootori ja selle häälte muutmiseks suunduda süsteemi kõnesünteesi seadetesse.',
    'instructionTextAndroid':
        'Süsteemi kõnesünteesi seadetesse saab liikuda läbi rakenduse vajutades parempoolset sünteesivaliku nuppu "Süsteemi hääl" või avades valikud paremalt ülevalt nurgast ja vajutades "Kõnesünteesi seaded".\nRakenduseväliselt saab sinna liikuda ka minnes Seaded -> Süsteem -> Keel ja sisend -> (Täpsemalt ->) alamkategooria Kõne -> Kõnesünteesi väljund.',
    'instructionTextiOS':
        'Meie hääli saab süsteemi lisada vajutades parempoolset sünteesivaliku nuppu "Süsteemi hääl" ning seal vajutades tahetud häältele. Süsteemi vaikimisi kõnesünteesi häält saab muuta liikudes seadetesse:\nSettings -> Accessibility -> Spoken content -> Voices -> Language (-> Language variant) (-> Engine)\nning valides soovitud kõneleja.',
    'enableEngineAppText': 'Vaikimisi kõnesünteesimootori muutmine rakendusest',
    'enableEngineApp': 'assets/tutorials/muuda_mootor_rakendusest.gif',
    'enableEngineSettingsText':
        'Vaikimisi kõnesünteesimootori muutmine seadetest',
    'enableEngineSettings': 'assets/tutorials/muuda_mootor.gif',
    'configureEngineText': 'Kõneleja vahetamine',
    'configureEngine': 'assets/tutorials/muuda_hääl.gif',
    'understood': 'Sain aru',
    'Eesti': 'Eesti keel',
    'English': 'Inglise keel',
    'more': 'Rohkem',
    'system': 'Süsteemi hääl',
    'slider': 'Kiirus',
    'reset': 'Lähtesta',
    'copy': 'Tekst kopeeritud!',
    'speak': 'Räägi',
    'stop': 'Peata',
    'slow': 'Aeglane',
    'fast': 'Kiire',
    'dropdown': 'Vali hääl',
    'hint': 'Kirjuta siia...',
    'tempo': 'Tempo',
    'selected': 'Luba hääled',
  },
  'English': {
    'loading': 'Models loading...',
    'engine': 'Text-to-speech voice:',
    'chooseVoice': 'Voice selection',
    'TTS settings': 'Text-to-speech settings',
    'about': 'About us',
    'back': 'Back',
    'instructions': 'Instructions',
    'introductionText':
        'Choose a synthesis engine, write something into the textfield below and you can listen to synthesized speech.\n\nChoosing the left text-to-speech option, you can change the speaking voice from its dropdown. Choosing the right option, in order to change the default engine and its options, you will need to head to the system\'s text-to-speech settings.',
    'instructionTextAndroid':
        'The system\'s text-to-speech settings can be opened through this app by tapping on the right synthesizer option button "System voice" or by opening the menu on the upper-right corner and tapping "Text-to-speech settings".\nTo access text-to-speech settings externally, go to Settings -> System -> Languages & input -> (Advanced ->) subcategory Speech -> Text-to-speech output.',
    'instructionTextiOS':
        'Our voices can be added to the system by tapping on the right synthesizer option button "System voice" and toggling the desired voices by tapping on them. The system text-to-speech voice can be changed by going to:\nSettings -> Accessibility -> Spoken content -> Voices -> Language (-> Language variant) (-> Engine)\nand tapping on the desired voice.',
    'enableEngineAppText':
        'Changing the system speech synthesis engine from the app',
    'enableEngineApp': 'assets/tutorials/enable_engine_from_app.gif',
    'enableEngineSettingsText':
        'Changing the system speech synthesis engine from settings',
    'enableEngineSettings': 'assets/tutorials/enable_engine.gif',
    'configureEngineText': 'Changing the default speaker',
    'configureEngine': 'assets/tutorials/configure_engine.gif',
    'understood': 'I understand',
    'Eesti': 'Estonian',
    'English': 'English',
    'more': 'More',
    'system': 'System voice',
    'slider': 'Speed',
    'reset': 'Reset',
    'copy': 'Text copied!',
    'speak': 'Speak',
    'stop': 'Stop',
    'slow': 'Slow',
    'fast': 'Fast',
    'dropdown': 'Choose voice',
    'hint': 'Write here...',
    'tempo': 'Tempo',
    'selected': 'Enable voices',
  }
};

const Map<String, Color> colors = {
  'cyan': Color(0xff4cb6ac),
  'red': Color(0xffef6650),
  'yellow': Color(0xffe0b12b),
  'purple': Color(0xff7268d8),
};

//Voice data: speakers, their background colors and decoration icon file names.
final List<Voice> voices = [
  Voice('Mari', colors['red']!),
  Voice('Tambet', colors['purple']!),
  Voice('Liivika', colors['yellow']!),
  Voice('Kalev', colors['cyan']!),
  Voice('Külli', colors['red']!),
  Voice('Meelis', colors['purple']!),
  Voice('Albert', colors['yellow']!),
  Voice('Indrek', colors['cyan']!),
  Voice('Vesta', colors['red']!),
  Voice('Peeter', colors['purple']!),
];

final SvgPicture slowTempoIcon = SvgPicture.asset(
  'assets/icons_logos/snail-clean.svg',
  color: Colors.blue,
  fit: BoxFit.fitWidth,
);

final SvgPicture fastTempoIcon = SvgPicture.asset(
  'assets/icons_logos/horse-clean.svg',
  color: Colors.blue,
  fit: BoxFit.fitWidth,
);
