import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:tflite_app/processors/processor.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'number_norm.dart';

class EstProcessor implements mProcessor {
  RegExp CURLY_RE = RegExp(r'(.*?)\{(.+?)\}(.*)');
  RegExp DECIMALS_RE = RegExp(r'([0-9]+[,.][0-9]+)');
  RegExp CURRENCY_RE =
      RegExp(r'([£\$€]((\d+[.,])?\d+))|(((\d+[.,])?\d+)[£\$€])');
  RegExp ORDINAL_RE = RegExp(r'[0-9]+\.');
  RegExp NUMBER_RE = RegExp(r'[0-9]+');
  RegExp DECIMALSCURRENCYNUMBER_RE = RegExp(
      r'(([0-9]+[,.][0-9]+)|([£\$€]((\d+[.,])?\d+))|(((\d+[.,])?\d+)[£\$€])|[0-9]+\.?)');
  static Map<String, String> CURRENCIES = {
    '£s': ' nael',
    '£m': ' naela',
    '£g': ' naela',
    '£cs': ' penn',
    '£cm': ' penni',
    '£cg': ' penni',
    '\$s': ' dollar',
    '\$m': ' dollarit',
    '\$g': ' dollari',
    '\$cs': ' sent',
    '\$cm': ' senti',
    '\$cg': ' sendi',
    '€s': ' euro',
    '€m': ' eurot',
    '€g': ' euro',
    '€cs': ' sent',
    '€cm': ' senti',
    '€cg': ' sendi',
  };
  static List<String> AUDIBLE_CONNECTING_SYMBOLS = ["×", "x", "*", "/", "-"];
  static List<String> GENITIVE_PREPOSITIONS = ["üle", "alla"];
  static List<String> GENITIVE_POSTPOSITIONS = [
    "võrra",
    "ümber",
    "pealt",
    "peale",
    "ringis",
    "paiku",
    "aegu",
    "eest"
  ];
  static List<String> PRONOUNCEABLE_ACRONYMS = [
    "ABBA",
    "AIDS",
    "ALDE",
    "API",
    "ARK",
    "ATKO",
    "BAFTA",
    "BENU",
    "CERN",
    "CRISPR",
    "COVID",
    "DARPA",
    "EFTA",
    "EKA",
    "EKI",
    "EKRE",
    "EKSA",
    "EMO",
    "EMOR",
    "ERM",
    "ERSO",
    "ESTO",
    "ETA",
    "EÜE",
    "FIDE",
    "FIFA",
    "FISA",
    "GAZ",
    "GITIS",
    "IBAN",
    "IPA",
    "ISIC",
    "ISIS",
    "ISO",
    "JOKK",
    "NASA",
    "NATO",
    "PERH",
    "PID",
    "PIN",
    "PRIA",
    "RAF",
    "RET",
    "SALT",
    "SARS",
    "SETI",
    "SIG",
    "SIM",
    "SMIT",
    "SORVVO",
    "TASS",
    "UNESCO",
    "VAZ",
    "VEB",
    "WADA",
    "WiFi"
  ];
  static List<String> SYMBOLS = [
    'pad',
    '-',	//
    ' ',
    '!',
    '\"',
    "'",	//
    ',',
    '.',
    ':',	//
    ';',	//
    '?',
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
    'š',  //
    't',
    'u',
    'v',
    'w',
    'õ',  //
    'ä',  //
    'ö',  //
    'ü',  //
    'x',
    'y',
    'z',
  //  'ä',
  //  'õ',
  //  'ö',
  //  'ü',
  //  'š',
    'ž',
    'eos'
  ];
  static Map<String, String> AUDIBLE_SYMBOLS = {
    '@': 'ät',
    '\$': 'dollar',
    '%': 'protsent',
    '&': 'ja',
    '+': 'pluss',
    '=': 'võrdub',
    '€': 'euro',
    '£': 'nael',
    '§': 'paragrahv',
    '°': 'kraad',
    '±': 'pluss miinus',
    '‰': 'promill',
    '×': 'korda',
    'x': 'korda',
    '*': 'korda',
    '∙': 'korda',
    '/': 'jagada',
    '-': 'miinus',
  };
  static Map<String, String> ABBREVIATIONS = {
    'apr': 'aprill',
    'aug': 'august',
    'aü': 'ametiühing',
    'ca': 'tsirka',
    'Ca': 'CA',
    'CA': 'CA',
    'cl': 'sentiliiter',
    'cm': 'sentimeeter',
    'dB': 'detsibell',
    'dets': 'detsember',
    'dl': 'detsiliiter',
    'dr': 'doktor',
    'e.m.a': 'enne meie ajaarvamist',
    'eKr': 'enne Kristuse sündi',
    'hj': 'hobujõud',
    'hr': 'härra',
    'hrl': 'harilikult',
    'IK': 'isikukood',
    'ingl': 'inglise keeles',
    'j.a': 'juures asuv',
    'jaan': 'jaanuar',
    'jj': 'ja järgmine',
    'jm': 'ja muud',
    'jms': 'ja muud sellised',
    'jmt': 'ja mitmed teised',
    'jn': 'joonis',
    'jne': 'ja nii edasi',
    'jpt': 'ja paljud teised',
    'jr': 'juunior',
    'Jr': 'juunior',
    'jsk': 'jaoskond',
    'jt': 'ja teised',
    'jun': 'juunior',
    'jv': 'järv',
    'k.a': 'kaasa arvatud',
    'kcal': 'kilokalor',
    'kd': 'köide',
    'kg': 'kilogramm',
    'kk': 'keskkool',
    'kl': 'kell',
    'klh': 'kolhoos',
    'km': 'kilomeeter',
    'KM': 'KM',
    'km/h': 'kilomeetrit tunnis',
    'km²': 'ruutkilomeeter',
    'kod': 'kodanik',
    'kpl': 'kauplus',
    'kr': 'kroon',
    'krt': 'korter',
    'kt': 'kohusetäitja',
    'kv': 'kvartal',
    'lg': 'lõige',
    'lk': 'lehekülg',
    'LK': 'looduskaitse',
    'lp': 'lugupeetud',
    'LP': 'LP',
    'lüh': 'lühend',
    'm.a.j': 'meie ajaarvamise järgi',
    'm/s': 'meetrit sekundis',
    'mbar': 'millibaar',
    'mg': 'milligramm',
    'mh': 'muu hulgas',
    'ml': 'milliliiter',
    'mld': 'miljard',
    'mln': 'miljon',
    'mm': 'millimeeter',
    'MM': 'MM',
    'mnt': 'maantee',
    'm²': 'ruutmeeter',
    'm³': 'kuupmeeter',
    'Mr': 'mister',
    'Ms': 'miss',
    'Mrs': 'missis',
    'n-ö': 'nii-öelda',
    'nim': 'nimeline',
    'nn': 'niinimetatud',
    'nov': 'november',
    'nr': 'number',
    'nt': 'näiteks',
    'NT': 'NT',
    'okt': 'oktoober',
    'p.o': 'peab olema',
    'pKr': 'pärast Kristuse sündi',
    'pa': 'poolaasta',
    'pk': 'postkast',
    'pms': 'peamiselt',
    'pr': 'proua',
    'prl': 'preili',
    'prof': 'professor',
    'ps': 'poolsaar',
    'PS': 'PS',
    'pst': 'puiestee',
    'ptk': 'peatükk',
    'raj': 'rajoon',
    'rbl': 'rubla',
    'reg-nr': 'registreerimisnumber',
    'rg-kood': 'registrikood',
    'rmtk': 'raamatukogu',
    'rmtp': 'raamatupidamine',
    'rtj': 'raudteejaam',
    's.a': 'sel aastal',
    's.o': 'see on',
    's.t': 'see tähendab',
    'saj': 'sajand',
    'sealh': 'sealhulgas',
    'seals': 'sealsamas',
    'sen': 'seenior',
    'sept': 'september',
    'sh': 'sealhulgas',
    'skp': 'selle kuu päeval',
    'SKP': 'SKP',
    'sl': 'supilusikatäis',
    'sm': 'seltsimees',
    'SM': 'SM',
    'snd': 'sündinud',
    'spl': 'supilusikatäis',
    'srn': 'surnud',
    'stj': 'saatja',
    'surn': 'surnud',
    'sü': 'säilitusüksus',
    'sünd': 'sündinud',
    'tehn': 'tehniline',
    'tel': 'telefon',
    'tk': 'tükk',
    'tl': 'teelusikatäis',
    'tlk': 'tõlkija',
    'tn': 'tänav',
    'tv': 'televisioon',
    'u': 'umbes',
    'ukj': 'uue); Gregoriuse kalendri järgi',
    'v.a': 'välja arvatud',
    'veebr': 'veebruar',
    'vkj': 'vana); Juliuse kalendri järgi',
    'vm': 'või muud',
    'vms': 'või muud sellist',
    'vrd': 'võrdle',
    'vt': 'vaata',
    'õa': 'õppeaasta',
    'õp': 'õpetaja',
    'õpil': 'õpilane',
    'V': 'volt',
    'Hz': 'herts',
    'W': 'vatt',
    'kW': 'kilovatt',
    'kWh': 'kilovatttund',
  };
  static Map<String, int> ROMAN_NUMBERS = {
    'I': 1,
    'V': 5,
    'X': 10,
    'L': 50,
    'C': 100,
    'D': 500,
    'M': 1000,
  };
  static Map<String, String> ALPHABET = {
    'A': 'aa',
    'B': 'bee',
    'C': 'tsee',
    'D': 'dee',
    'E': 'ee',
    'F': 'eff',
    'G': 'gee',
    'H': 'haa',
    'I': 'ii',
    'J': 'jott',
    'K': 'kaa',
    'L': 'ell',
    'M': 'emm',
    'N': 'enn',
    'O': 'oo',
    'P': 'pee',
    'Q': 'kuu',
    'R': 'err',
    'S': 'ess',
    'Š': 'šaa',
    'Z': 'zett',
    'Ž': 'žee',
    'T': 'tee',
    'U': 'uu',
    'V': 'vee',
    'W': 'kaksisvee',
    'Õ': 'õõ',
    'Ä': 'ää',
    'Ö': 'öö',
    'Ü': 'üü',
    'X': 'iks',
    'Y': 'igrek',
  };
  static Map<String, int> SYMBOL_TO_ID = {};

  EstProcessor() {
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

  /*List<int> _arpabetToSequence(String text) {
    return [1];
  }*/

  /*String _convertToUtf8(String text) {
    throw UnimplementedError();
  }*/

  String _simplifyUnicode(String sentence) {
    sentence = sentence.replaceAll("Ð", "D").replaceAll("Þ", "Th");
    sentence = sentence.replaceAll("ð", "d").replaceAll("þ", "th");
    sentence = sentence.replaceAll("ø", "ö").replaceAll("Ø", "Ö");
    sentence = sentence.replaceAll("ß", "ss").replaceAll("ẞ", "Ss");
    sentence = sentence.replaceAll("S[cC][hH]", "Š");
    sentence = sentence.replaceAll("sch", "š");
    sentence = sentence.replaceAll("[ĆČ]", "Tš");
    sentence = sentence.replaceAll("[ćč]", "tš");

    //sentence = unorm.nfd(sentence)
    sentence = unorm.nfc(sentence);
    //sentence = unorm.nfkc(sentence)
    sentence = sentence.replaceAll(RegExp(r"\\p{M}"), "");

    return sentence;
  }

  String _collapseWhitespace(String text) {
    return text.replaceAll(RegExp(r"\\s+"), " ");
  }

  static String _subBetween(String text, RegExp label, String target) {
    RegExpMatch? m = label.firstMatch(text);
    while (m != null) {
      if (m.groupCount == 2) {
        text = text.replaceFirst(
            label, m.group(1).toString() + target + m.group(2).toString());
      } else if (m.groupCount == 3) {
        text = text.replaceFirst(
            label, m.group(1).toString() + target + m.group(3).toString());
      }
      m = label.firstMatch(text);
    }
    return text;
  }

  static String _romanToArabic(String word) {
    String endingWord = "";
    RegExp pattern = RegExp(r'-?[a-z]+$');
    RegExpMatch? m = pattern.firstMatch(word);
    if (m != null) {
      endingWord = " " +
          (word.substring(m.start, m.end).startsWith("-")
              ? word.substring(m.start + 1, m.end)
              : word.substring(m.start, m.end));
    }
    if (RegExp(r'[IXC]{4}').hasMatch(word)) {
      return word;
    } else if (RegExp(r'[VLD]{2}').hasMatch(word)) {
      return word;
    }
    String newword = word.replaceAll("IV", "IIII").replaceAll("IX", "VIIII");
    newword = newword.replaceAll("XL", "XXXX").replaceAll("XC", "LXXXX");
    newword = newword.replaceAll("CD", "CCCC").replaceAll("CM", "DCCCC");
    if (RegExp(r'[IXC]{5}').hasMatch(newword)) {
      return word;
    }
    int sum = 0;
    int max = 1000;
    for (String ch in newword.split('')) {
      int i = ROMAN_NUMBERS[ch]!;
      if (i > max) {
        return word;
      }
      max = i;
      sum += i;
    }
    return sum.toString() + "." + endingWord;
  }

  String _expandAbbreviations(String text) {
    for (MapEntry<String, String> entry in ABBREVIATIONS.entries) {
      text = text.replaceAll(RegExp(r"\\b" + entry.key + "\\."), entry.value);
    }
    return text;
  }

  String _expandCurrency(String text, String kaane) {
    String s = text;
    if (text.contains(".") && text.contains(",")) {
      s = text.replaceAll(",", "");
    }
    s = s.replaceAll("\\.", ",");
    bool match = CURRENCY_RE.hasMatch(s);
    String curr = 'N';
    if (text.contains('\$')) {
      curr = '\$';
    } else if (text.contains("€")) {
      curr = '€';
    } else if (text.contains("£")) {
      curr = '£';
    }
    if (match) {
      String moneys = "0";
      String cents = "0";
      String spelling = "";
      s = s.replaceAll(RegExp(r"[£$€]"), "");
      List<String> parts = s.split(",");
      if (!s.startsWith(",")) {
        moneys = parts[0];
      }
      if (!s.endsWith(",") && parts.length > 1) {
        cents = parts[1];
      }
      if ("0" != moneys) {
        if (kaane == 'O') {
          spelling += parts[0] + CURRENCIES[curr + "g"]!;
        } else if ("1" == moneys || "01" == moneys) {
          spelling += parts[0] + CURRENCIES[curr + "s"]!;
        } else {
          spelling += parts[0] + CURRENCIES[curr + "m"]!;
        }
      }
      if ("0" != cents && "00" != cents) {
        spelling += " ja -";
        if (kaane == 'O') {
          spelling += parts[0] + CURRENCIES[curr + "cg"]!;
        }

        if ("1" == cents || "01" == cents) {
          spelling += parts[1] + CURRENCIES[curr + "cs"]!;
        } else {
          spelling += parts[1] + CURRENCIES[curr + "cm"]!;
        }
      }
      text = text.replaceFirst(text, spelling);
    }
    return text;
  }

  String _expandDecimals(String text) {
    RegExpMatch? m = DECIMALS_RE.firstMatch(text);
    while (m != null) {
      String s =
          text.substring(m.start, m.end).replaceAll(RegExp(r"[.,]"), " koma ");
      text = text.replaceFirst(text.substring(m.start, m.end), s);
      m = DECIMALS_RE.firstMatch(text);
    }
    return text;
  }

  String _expandOrdinals(String text, String kaane) {
    RegExpMatch? m = ORDINAL_RE.firstMatch(text);
    while (m != null) {
      String s = text.substring(m.start, m.end - 1);
      int l = int.parse(s);
      String spelling = NumberNormEt.toOrdinal(l, kaane);
      text = text.replaceFirst(text.substring(m.start, m.end), spelling);
      m = ORDINAL_RE.firstMatch(text);
    }
    return text;
  }

  String _expandCardinals(String text, String kaane) {
    RegExpMatch? m = NUMBER_RE.firstMatch(text);
    while (m != null) {
      int l = int.parse(text.substring(m.start, m.end));
      String spelling = NumberNormEt.numToString(l, kaane);
      text = text.replaceFirst(text.substring(m.start, m.end), spelling);
      m = NUMBER_RE.firstMatch(text);
    }
    return text;
  }

  String _expandNumbers(String text, String kaane) {
    List<String> parts = text.split(" ");
    for (int i = 0; i < parts.length; i++) {
      parts[i] = _expandCurrency(parts[i], kaane);
      parts[i] = _expandDecimals(parts[i]);
      if (kaane != 'N' || parts[i].endsWith(".")) {
        parts[i] = _expandOrdinals(parts[i], kaane);
      }
      parts[i] = _expandCardinals(parts[i], kaane);
    }
    return parts.join(' ');
  }

  String _processByWord(List<String> tokens) {
    List<String> newTextParts = [];
    for (int i = 0; i < tokens.length; i++) {
      String word = tokens[i];
      if (!RegExp(
              r'([A-ZÄÖÜÕŽŠa-zäöüõšž]+(\.(?!( [A-ZÄÖÜÕŽŠ])))?)|([£$€]?[0-9.,]+[£$€]?)')
          .hasMatch(word)) {
        if (AUDIBLE_SYMBOLS.containsKey(word)) {
          if (AUDIBLE_CONNECTING_SYMBOLS.contains(word) &&
              !(i > 0 &&
                  i < tokens.length - 1 &&
                  DECIMALSCURRENCYNUMBER_RE.hasMatch(tokens[i - 1]) &&
                  DECIMALSCURRENCYNUMBER_RE.hasMatch(tokens[i + 1]))) {
            continue;
          } else {
            newTextParts.add(AUDIBLE_SYMBOLS[word]!);
          }
        } else {
          newTextParts.add(word);
        }
        continue;
      }
      if (RegExp(r'^[IVXLCDM]+-?\w*$').hasMatch(word)) {
        word = _romanToArabic(word);
        if (word.split(' ').length > 1) {
          newTextParts.add(_processByWord(word.split(' ')));
          continue;
        }
      }
      if (DECIMALSCURRENCYNUMBER_RE.hasMatch(word)) {
        String kaane = 'N';
        if ((i > 0 && GENITIVE_PREPOSITIONS.contains(tokens[i - 1])) ||
            (i < tokens.length - 1 &&
                GENITIVE_POSTPOSITIONS.contains(tokens[i + 1]))) {
          kaane = 'O';
        }
        word = _expandNumbers(word, kaane);
      }
      if (word.endsWith('.')) {
        word = word.substring(0, word.length - 1);
      }
      if (ABBREVIATIONS.containsKey(word)) {
        word = ABBREVIATIONS[word]!;
      } else if (RegExp(r'^[A-ZÄÖÜÕŽŠ]+$').hasMatch(word)) {
        if (!PRONOUNCEABLE_ACRONYMS.contains(word)) {
          List<String> newWord = [];
          for (String c in word.split('')) {
            newWord.add(ALPHABET[c]!);
          }
          word = newWord.join('-');
        }
      }
      newTextParts.add(word);
    }
    return newTextParts.join(' ');
  }

  String _cleanTextForEstonian(String text) {
    RegExpMatch? m = RegExp(r'(\d)\.\.\.(\d)').firstMatch(text);
    while (m != null) {
      text = m.group(1).toString() + ' kuni ' + m.group(2).toString();
      m = RegExp(r'(\d)\.\.\.(\d)').firstMatch(text);
    }
    //text = _convertToUtf8(text);
    text = _simplifyUnicode(text);

    text = _subBetween(text, RegExp(r'(\d)([A-ZÄÖÜÕŽŠa-zäöüõšž])'), '-');
    text = _subBetween(text, RegExp(r'([A-ZÄÖÜÕŽŠa-zäöüõšž])(\d)'), '-');

    text = _subBetween(text, RegExp(r'([0-9]) ([0-9]{3})(?!\d)'), '');
    text = text.substring(0, 1).toLowerCase() + text.substring(1);

    RegExp tokenizer = RegExp(r'([A-ZÄÖÜÕŽŠa-zäöüõšž@#0-9.,£$€]+)|\S');
    List<String> tokens = [];
    for (RegExpMatch match in tokenizer.allMatches(text)) {
      tokens.add(text.substring(match.start, match.end));
    }

    text = _processByWord(tokens);
    text = text.toLowerCase();
    text += '.';
    text = _collapseWhitespace(text);
    text = _expandAbbreviations(text);

    log('Text preprocessed:' + text);
    return text;
  }

  @override
  List<int> textToIds(String text) {
    List<int> sequence = [];
    while (text.isNotEmpty) {
      RegExpMatch? m = CURLY_RE.firstMatch(text);
      if (m == null) {
        String newText = _cleanTextForEstonian(text);
        sequence.addAll(_symbolsToSequence(newText));
        break;
      }
      sequence.addAll(_symbolsToSequence(_cleanTextForEstonian(m.group(1)!)));
      //sequence.addAll(_arpabetToSequence(m.group(2)!));
      text = m.group(3)!;
    }
    return sequence;
  }
}
