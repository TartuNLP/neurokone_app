import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:tflite_app/processors/processor.dart';

import 'number_norm.dart';

class EngProcessor implements mProcessor {
  static final List<String> VALID_SYMBOLS = [
    "AA",
    "AA0",
    "AA1",
    "AA2",
    "AE",
    "AE0",
    "AE1",
    "AE2",
    "AH",
    "AH0",
    "AH1",
    "AH2",
    "AO",
    "AO0",
    "AO1",
    "AO2",
    "AW",
    "AW0",
    "AW1",
    "AW2",
    "AY",
    "AY0",
    "AY1",
    "AY2",
    "B",
    "CH",
    "D",
    "DH",
    "EH",
    "EH0",
    "EH1",
    "EH2",
    "ER",
    "ER0",
    "ER1",
    "ER2",
    "EY",
    "EY0",
    "EY1",
    "EY2",
    "F",
    "G",
    "HH",
    "IH",
    "IH0",
    "IH1",
    "IH2",
    "IY",
    "IY0",
    "IY1",
    "IY2",
    "JH",
    "K",
    "L",
    "M",
    "N",
    "NG",
    "OW",
    "OW0",
    "OW1",
    "OW2",
    "OY",
    "OY0",
    "OY1",
    "OY2",
    "P",
    "R",
    "S",
    "SH",
    "T",
    "TH",
    "UH",
    "UH0",
    "UH1",
    "UH2",
    "UW",
    "UW0",
    "UW1",
    "UW2",
    "V",
    "W",
    "Y",
    "Z",
    "ZH"
  ];

  RegExp CURLY_RE = RegExp(r'(.*?)\{(.+?)\}(.*)');
  RegExp COMMA_NUMBER_RE = RegExp(r'([0-9][0-9\,]+[0-9])');
  RegExp DECIMAL_RE = RegExp(r'([0-9]+\.[0-9]+)');
  RegExp POUNDS_RE = RegExp(r'£([0-9\,]*[0-9]+)');
  RegExp DOLLARS_RE = RegExp(r'\$([0-9.\,]*[0-9]+)');
  RegExp ORDINAL_RE = RegExp(r'[0-9]+(st|nd|rd|th)');
  RegExp NUMBER_RE = RegExp(r'[0-9]+');

  static const String PAD = '_';
  static const String EOS = '~';
  static const String SPECIAL = '-';

  static const List<String> PUNCTUATION = [
    '!',
    '\'',
    '(',
    ')',
    ',',
    '.',
    ':',
    ';',
    '?',
    ' '
  ];
  static const List<String> LETTERS = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z'
  ];

  static List<String> SYMBOLS = [];
  static Map<String, String> ABBREVIATIONS = {
    'mrs': 'misess',
    'mr': 'mister',
    'dr': 'doctor',
    'st': 'saint',
    'co': 'company',
    'jr': 'junior',
    'maj': 'major',
    'gen': 'general',
    'drs': 'doctors',
    'rev': 'reverend',
    'lt': 'lieutenant',
    'hon': 'honorable',
    'sgt': 'sergeant',
    'capt': 'captain',
    'esq': 'esquire',
    'ltd': 'limited',
    'col': 'colonel',
    'ft': 'fort',
  };
  static Map<String, int> SYMBOL_TO_ID = {};

  EngProcessor() {
    SYMBOLS.add(PAD);
    SYMBOLS.add(SPECIAL);

    for (String p in PUNCTUATION) {
      if (p != '') {
        SYMBOLS.add(p);
      }
    }

    for (String l in LETTERS) {
      if (l != '') {
        SYMBOLS.add(l);
      }
    }

    for (String vs in VALID_SYMBOLS) {
      SYMBOLS.add('@' + vs);
    }

    SYMBOLS.add(EOS);

    for (int i = 0; i < SYMBOLS.length; i++) {
      SYMBOL_TO_ID[SYMBOLS[i]] = i;
    }
  }

  List<int> _symbolsToSequence(String symbols) {
    List<int> sequence = [];
    for (String symbol in symbols.characters) {
      int? id = SYMBOL_TO_ID[symbol];
      if (id == null) {
        log("symbolsToSequence: id is not found for " + symbol);
      } else {
        sequence.add(id);
      }
    }
    return sequence;
  }

  List<int> _arpabetToSequence(String symbols) {
    List<int> sequence = [];
    if (symbols != null) {
      for (String s in symbols.split(' ')) {
        sequence.add(SYMBOL_TO_ID['@' + s]!);
      }
    }
    return sequence;
  }

  /*
  String _convertToAscii(String text) {
    byte[] bytes = text.getBytes(StandardCharsets.US_ASCII);
        return new String(bytes);
    return '';
  }*/

  String _collapseWhitespace(String text) {
    return text.replaceAll("\\s+", " ");
  }

  String _expandAbbreviations(String text) {
    for (MapEntry<String, String> entry in ABBREVIATIONS.entries) {
      text = text.replaceAll("\\b" + entry.key + "\\.", entry.value);
    }
    return text;
  }

  String _removeCommasFromNumbers(String text) {
    RegExpMatch? match = POUNDS_RE.firstMatch(text);
    while (match != null) {
      String s = match.toString().replaceAll(',', '');
      text = text.replaceAll(match.toString(), s);
      match = POUNDS_RE.firstMatch(text);
    }
    return text;
  }

  String _expandPounds(String text) {
    RegExpMatch? match = POUNDS_RE.firstMatch(text);
    while (match != null) {
      String pounds = '0';
      String pennies = '0';
      String spelling = '';
      String s = match.toString().substring(1);
      List<String> parts = s.split('.');
      if (!s.startsWith('.')) {
        pounds = parts[0];
      }
      if (!s.endsWith('.') && parts.length > 1) {
        pennies = parts[1];
      }
      if (pounds != '0') {
        spelling += parts[0] + ' pound';
        if (pounds != '1') {
          spelling += 's';
        }
        spelling += ' ';
      }
      if (pennies != '0' && pennies != '00') {
        if (pennies != '1' && pennies != '01') {
          spelling += parts[1] + ' pence ';
        } else {
          spelling += parts[1] + ' penny ';
        }
      }
      text = text.replaceFirst('\\' + match.toString(), spelling);
      match = DOLLARS_RE.firstMatch(text);
    }
    return text;
  }

  String _expandDollars(String text) {
    RegExpMatch? match = DOLLARS_RE.firstMatch(text);
    while (match != null) {
      String dollars = '0';
      String cents = '0';
      String spelling = '';
      String s = match.toString().substring(1);
      List<String> parts = s.split('.');
      if (!s.startsWith('.')) {
        dollars = parts[0];
      }
      if (!s.endsWith('.') && parts.length > 1) {
        cents = parts[1];
      }
      if (dollars != '0') {
        spelling += parts[0] + ' dollar';
        if (dollars != '1') {
          spelling += 's';
        }
        spelling += ' ';
      }
      if (cents != '0' && cents != '00') {
        spelling += parts[1] + ' cent';
        if (cents != '1' && cents != '01') {
          spelling += 's';
        }
        spelling += ' ';
      }
      text = text.replaceFirst('\\' + match.toString(), spelling);
      match = DOLLARS_RE.firstMatch(text);
    }
    return text;
  }

  String _expandDecimals(String text) {
    RegExpMatch? match = DECIMAL_RE.firstMatch(text);
    while (match != null) {
      String s = match.toString().replaceAll('.', ' point ');
      text = text.replaceFirst(match.toString(), s);
      match = DECIMAL_RE.firstMatch(text);
    }
    return text;
  }

  String _expandOrdinals(String text) {
    RegExpMatch? match = ORDINAL_RE.firstMatch(text);
    while (match != null) {
      String s = match.toString().substring(0, match.toString().length - 2);
      String spelling = NumberNormEn.toOrdinal(int.parse(s));
      text = text.replaceFirst(match.toString(), spelling);
      match = DECIMAL_RE.firstMatch(text);
    }
    return text;
  }

  String _expandCardinals(String text) {
    RegExpMatch? match = NUMBER_RE.firstMatch(text);
    while (match != null) {
      String spelling = NumberNormEn.numToString(int.parse(match.toString()));
      text = text.replaceFirst(match.toString(), spelling);
      match = NUMBER_RE.firstMatch(text);
    }
    return text;
  }

  String _expandNumbers(String text) {
    text = _removeCommasFromNumbers(text);
    text = _expandPounds(text);
    text = _expandDollars(text);
    text = _expandDecimals(text);
    text = _expandOrdinals(text);
    text = _expandCardinals(text);
    return text;
  }

  String _cleanTextForEnglish(String text) {
    //text = _convertToAscii(text);
    text = text.toLowerCase();
    text = _expandAbbreviations(text);
    try {
      text = _expandNumbers(text);
    } catch (e) {
      log('Failed to convert numbers: ' + e.toString());
    }
    text = _collapseWhitespace(text);
    log('text preprocessed: ' + text);
    return text;
  }

  @override
  List<int> textToIds(String text) {
    List<int> sequence = [];
    while (text.isNotEmpty) {
      RegExpMatch? m = CURLY_RE.firstMatch(text);
      if (m == null) {
        String newText = _cleanTextForEnglish(text);
        sequence.addAll(_symbolsToSequence(newText));
        break;
      }
      sequence.addAll(_symbolsToSequence(_cleanTextForEnglish(m.group(1)!)));
      sequence.addAll(_arpabetToSequence(m.group(2)!));
      text = m.group(3)!;
    }
    return sequence;
  }
}
