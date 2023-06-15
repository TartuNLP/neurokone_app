import 'package:eestitts/ui/voice.dart';
import 'package:flutter/material.dart';

class Variables {
  static final String channelPath = 'com.tartunlp.eestitts';

  //Defaults for Estonian and English UI.
  static const Map<String, Map<String, String>> langs = {
    'Eesti': {
      'TTS Settings': 'Kõnesünteesi seaded',
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
      'TTS Settings': 'Text-to-speech settings',
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
}
