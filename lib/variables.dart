import 'package:neurokone/ui/voice.dart';
import 'package:flutter/material.dart';

const String packageName = 'com.tartunlp.neurokone';
const String appVersion = 'Neurokõne v1.1.0';

const String synthModel = 'fastspeech2-est';
const String vocModel = 'hifigan-est.v2';

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
        'Vali sünteeshääl, kirjuta tekst alla lahtrisse ning saad kuulata sünteesitud kõne.',
    'instructionText':
        'Valikus on süsteemi hääl ning meie 10 sünteeshäält. Süsteemi hääle puhul esitatakse teksti telefoni eelistatud kõnesünteesi mootori abil, selle muutmiseks tuleb suunduda telefoni kõnesünteesi seadetesse.',
    'instructionTextAndroid':
        'Süsteemi kõnesünteesi seadetesse saab liikuda läbi rakenduse vajutades häälevalikust paremal olevat seadete nuppu või päismenüüst valida "Kõnesünteesi seaded"',
    'instructionTextiOS':
        'Meie hääli saab süsteemi lisada vajutades hääle valikust paremal asuvat seadete nuppu ning uues aknas valida tahetud hääled. Süsteemi kõnesünteesi häält saab muuta liikudes seadetesse:\nSettings -> Accessibility -> Spoken content -> Voices -> Language (-> Language variant) (-> Engine)\nning valides soovitud kõneleja.',
    'enableEngineAppText':
        'Vaikimisi kõnesünteesimootori muutmine rakenduse kaudu',
    'enableEngineAppLabel':
        'Avage süsteemi kõnesünteesi seaded vajutades sünteeshääle valikust paremal olevat nuppu või avades päise menüü ja vajutades "Kõnesünteesi seaded". Avage valik "Eelistatud kõnesünteesi mootor" ning valige soovitud mootor. Avanenud hüpikaknas vajutage OK. Seejärel liikuge tagasi. Veelkord tagasi liikudes jõuate uuesti rakendusse.',
    'enableEngineApp': 'assets/tutorials/muuda_mootor_rakendusest.gif',
    'enableEngineSettingsText':
        'Vaikimisi kõnesünteesimootori muutmine seadetest',
    'enableEngineSettingsLabel':
        'Rakenduseväliselt kõnesünteesimootori muutmiseks liikuge Seadete rakendusse, avage valik Süsteem - Keeled ja sisend - Kõnesünteesi väljund. Avage valik "Eelistatud kõnesünteesi mootor" ning valige soovitud mootor. Avanenud hüpikaknas vajutage OK. Liikuge tagasi.',
    'enableEngineSettings': 'assets/tutorials/muuda_mootor.gif',
    'configureEngineText': 'Neurokõne süsteemi hääle vahetamine',
    'configureEngineLabel':
        'Liikuge kõnesünteesi seadetesse. Kui eelistatud kõnesünteesi mootoriks on valitud TartuNLP Neurokõne, siis avage sellest valikust paremal olevast nupust menüü. Valige soovitud hääl.',
    'configureEngine': 'assets/tutorials/muuda_hääl.gif',
    'understood': 'Sain aru',
    'Eesti': 'Raadionupp, Rakenduse keel, Eesti',
    'English': 'Raadionupp, Rakenduse keel, Inglise',
    'more': 'Menüü nupp, Rohkem',
    'system': 'Süsteemi hääl',
    'slider': 'Kõne tempo',
    'normal': 'standard',
    'minimum': 'minimaalne',
    'maximum': 'maksimaalne',
    'reset': 'Lähtesta',
    'resetLabel': 'Lähtesta kõne tempo',
    'clearLabel': 'Kustuta tekst',
    'copyLabel': 'Kopeeri tekst',
    'copy': 'Tekst kopeeritud!',
    'speak': 'Räägi',
    'stop': 'Peata',
    'slow': 'Aeglane',
    'fast': 'Kiire',
    'dropdown': 'Vali hääl',
    'hint': 'Kirjuta siia...',
    'tempo': 'Tempo:',
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
        'Choose a synthesis engine, write something into the textfield below and you can listen to synthesized speech.',
    'instructionText':
        'There are System voice and 10 of our voices to select from. In case of the System voice, you will need to head to the system\'s text-to-speech settings in order to change the used engine and its options.',
    'instructionTextAndroid':
        'The system\'s text-to-speech settings can be opened through this app by tapping on the right gear icon next to the voice selection or by opening the menu on the upper-right corner and tapping "Text-to-speech settings".\nTo access text-to-speech settings externally, go to Settings -> System -> Languages & input -> (Advanced ->) subcategory Speech -> Text-to-speech output.',
    'instructionTextiOS':
        'Our voices can be added to the system by tapping on the gear icon next to the voice selection and toggling the desired voices by tapping on them. The system text-to-speech voice can be changed by going to:\nSettings -> Accessibility -> Spoken content -> Voices -> Language (-> Language variant) (-> Engine)\nand selecting the desired voice.',
    'enableEngineAppText':
        'Changing the system speech synthesis engine from the app',
    'enableEngineAppLabel':
        'Open Text-to-speech settings by tapping on the gear on the right side of the voice selection or by opening the header menu and tapping Text-to-speech settings. Open the Preferred engine option and choose an engine, in our case TartuNLP Neurokone. Confirm by tapping OK in the pop-up window. Finally, go back. Going back once more takes you back to the app.',
    'enableEngineApp': 'assets/tutorials/enable_engine_from_app.gif',
    'enableEngineSettingsText':
        'Changing the system speech synthesis engine from settings',
    'enableEngineSettingsLabel':
        'To change the system\'s text-to-speech engine without using the app, open Settings. Navigate to System - Languages and input - Text-to-speech output. Open the Preferred engine option and choose an engine, in out case TartuNLP Neurokone. Confirm by tapping OK in the pop-up window. Finally, go back.',
    'enableEngineSettings': 'assets/tutorials/enable_engine.gif',
    'configureEngineText': 'Changing the default speaker',
    'configureEngineLabel':
        'Go to Text-to-speech settings. If the chosen preferred engine is TartuNLP Neurokõne, tap the gear icon next to the option. Choose your preferred speaker.',
    'configureEngine': 'assets/tutorials/configure_engine.gif',
    'understood': 'I understand',
    'Eesti': 'Radiobutton, App language, Estonian',
    'English': 'Radiobutton, App language, English',
    'more': 'Menu button, More',
    'system': 'System voice',
    'slider': 'Speech tempo',
    'normal': 'standard',
    'minimum': 'minimum',
    'maximum': 'maximum',
    'reset': 'Reset',
    'resetLabel': 'Reset speech tempo',
    'clearLabel': 'Clear text',
    'copyLabel': 'Copy text',
    'copy': 'Text copied!',
    'speak': 'Speak',
    'stop': 'Stop',
    'slow': 'Slow',
    'fast': 'Fast',
    'dropdown': 'Choose voice',
    'hint': 'Write here...',
    'tempo': 'Tempo:',
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

const String slowTempoIconPath = 'assets/icons_logos/snail-clean.svg';
const String fastTempoIconPath = 'assets/icons_logos/horse-clean.svg';
