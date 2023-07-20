import 'package:neurokone/ui/voice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

final String packageName = 'com.tartunlp.neurokone';

//Defaults for Estonian and English UI.
const Map<String, Map<String, String>> langs = {
  'Eesti': {
    'loading': 'Mudelite laadimine...',
    'engine': 'Sünteeshääl:',
    'TTS settings': 'Kõnesünteesi seaded',
    'about': 'Meist',
    'back': 'Tagasi',
    'instructions': 'Juhised',
    'introductionText':
        'Vali sünteeshääl, kirjuta midagi alla lahtrisse ning saad kuulata sünteesitud kõne!\n\nVasakpoolse sünteeshääle valiku puhul saad valida, kes meie häältest teksti esitab.\nParempoolse valiku puhul tuleb mootori ja selle häälte muutmiseks suunduda süsteemi kõnesünteesi seadetesse.',
    'instructionTextAndroid':
        'Süsteemi kõnesünteesi seadetesse saab liikuda läbi rakenduse vajutades parempoolset sünteesivaliku nuppu "Süsteemi hääl" või avades valikud paremalt ülevalt nurgast ja vajutades "Kõnesünteesi seaded".\nRakenduseväliselt saab sinna liikuda ka minnes Seaded -> Süsteem -> Keel ja sisend -> (Täpsemalt ->) alamkategooria Kõne -> Kõnesünteesi väljund.',
    'instructionTextiOS':
        'Meie hääli saab süsteemi lisada vajutades parempoolset sünteesivaliku nuppu "Süsteemi hääl" ning seal vajutades tahetud häältele. Süsteemi vaikimisi kõnesünteesi häält saab muuta liikudes seadetesse:\nSettings -> Accessibility -> Spoken content -> Voices -> Language (-> Language variant) (-> Engine)\nning valides soovitud kõneleja.',
    'understood': 'Sain aru',
    'choose': 'Süsteemi hääl',
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
    'TTS settings': 'Text-to-speech settings',
    'about': 'About us',
    'back': 'Back',
    'instructions': 'Instructions',
    'introductionText':
        'Choose a speech synthesis engine, write something into the textfield below and you can listen to synthesized speech!\n\nChoosing the left text-to-speech option, you can change the speaking voice from the dropdown that opens by tapping on the current voice. Choosing the right option, in order to change the default engine and its options, you will need to head to the system\'s text-to-speech settings.',
    'instructionTextAndroid':
        'The system\'s text-to-speech settings can be opened through this app by tapping on the right synthesizer option button "System voice" or by opening the menu on the upper-right corner and tapping "Text-to-speech settings".\nTo access text-to-speech settings externally, go to Settings -> System -> Languages & input -> (Advanced ->) subcategory Speech -> Text-to-speech output.',
    'instructionTextiOS':
        'Our voices can be added to the system by tapping on the right synthesizer option button "System voice" and toggling the desired voices by tapping on them. The system text-to-speech voice can be changed by going to:\nSettings -> Accessibility -> Spoken content -> Voices -> Language (-> Language variant) (-> Engine)\nand tapping on the desired voice.',
    'understood': 'I understand',
    'choose': 'System voice',
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

voiceIcon(Voice voice) =>
    Lottie.asset('assets/icons_logos/${voice.getIcon()}.json', animate: true);

const Map<String, Color> colors = {
  'cyan': Color(0xff4cb6ac),
  'red': Color(0xffef6650),
  'yellow': Color(0xffe0b12b),
  'purple': Color(0xff7268d8),
};

//Voice data: speakers, their background colors and decoration icon file names.
final List<Voice> voices = [
  Voice('Mari', colors['red']!, '1'),
  Voice('Tambet', colors['purple']!, '2'),
  Voice('Liivika', colors['yellow']!, '3'),
  Voice('Kalev', colors['cyan']!, '4'),
  Voice('Külli', colors['red']!, '3'),
  Voice('Meelis', colors['purple']!, '2'),
  Voice('Albert', colors['yellow']!, '1'),
  Voice('Indrek', colors['cyan']!, '3'),
  Voice('Vesta', colors['red']!, '2'),
  Voice('Peeter', colors['purple']!, '4'),
  /*made up voices*/
  //Voice('Maris', colors['purple']!, '1'),
  //Voice('Tambets', colors['red']!, '2'),
  //Voice('Liivikas', colors['cyan']!, '3'),
  //Voice('Kalevs', colors['yellow']!, '4'),
];

final SvgPicture slowTempoIcon = SvgPicture.asset(
  'assets/icons_logos/snail-clean.svg',
  color: Colors.blue,
);

final SvgPicture fastTempoIcon = SvgPicture.asset(
  'assets/icons_logos/horse-clean.svg',
  color: Colors.blue,
);
