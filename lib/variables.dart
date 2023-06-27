import 'package:eestitts/ui/voice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

class Variables {
  static final String packageName = 'com.tartunlp.eestitts';

  //Defaults for Estonian and English UI.
  static const Map<String, Map<String, String>> langs = {
    'Eesti': {
      'loading': 'Mudelite laadimine...',
      'TTS settings': 'Kõnesünteesi seaded',
      'about': 'Meist',
      'back': 'Tagasi',
      'instructions': 'Juhised',
      'understood': 'Sain aru',
      'choose': 'Süsteemihääl',
      'speak': 'Räägi',
      'stop': 'Peata',
      'slow': 'Aeglane',
      'fast': 'Kiire',
      'dropdown': 'Vali hääl',
      'hint': 'Kirjuta siia...',
      'tempo': 'Tempo',
      'selected': 'Lubatud Keeled',
    },
    'English': {
      'loading': 'Models loading...',
      'TTS settings': 'Text-to-speech settings',
      'about': 'About us',
      'back': 'Back',
      'instructions': 'Instructions',
      'understood': 'I understand',
      'choose': 'System voice',
      'speak': 'Speak',
      'stop': 'Stop',
      'slow': 'Slow',
      'fast': 'Fast',
      'dropdown': 'Choose voice',
      'hint': 'Write here...',
      'tempo': 'Tempo',
      'selected': 'Enabled Languages',
    }
  };

  static voiceIcon(Voice voice) =>
      Lottie.asset('assets/icons_logos/${voice.getIcon()}.json', animate: true);

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

  static final SvgPicture slowTempoIcon = SvgPicture.asset(
    'assets/icons_logos/snail-clean.svg',
    color: Colors.blue,
  );

  static final SvgPicture fastTempoIcon = SvgPicture.asset(
    'assets/icons_logos/horse-clean.svg',
    color: Colors.blue,
  );
}
