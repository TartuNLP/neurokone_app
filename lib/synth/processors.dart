import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'dart:math' as math;
import 'package:unorm_dart/unorm_dart.dart' as unorm;
import 'package:syllables_split_ru/syllables_split_ru.dart' as syllables;

class SentProcessor {
  Logger logger = Logger();
  //For splitting the whole text into sentences.
  RegExp sentencesSplit = RegExp(
    r'[.!?]((((\" )| |( \"))(?![a-zäöüõšž]))|(\"?$))',
  );
  //RegExp sentencesSplit = RegExp(r'(?=[.!?])((((" )| |( "))(?=[a-zõäöüšžA-ZÕÄÖÜŠŽ0-9]))|("?$))');
  //For splitting long sentences into parts
  RegExp sentenceSplit = RegExp(
    r'(?<!^)([,;!?]"? )|( ((ja)|(ning)|(ega)|(ehk)|(või)|–) )',
  );
  //For stripping unnecessary symbols from the beginning
  RegExp strip = RegExp(r'(^[,;!?–]?\"? ?)|([,;!?–]?\"? ?$)');

  List<String> _splitSentence(
    String text,
    int currentSentId,
    RegExpMatch? match,
  ) {
    List<String> sentenceParts = [];
    String sentence;
    if (match != null) {
      sentence = text.substring(currentSentId, match.start + 1);
    } else {
      sentence = text.substring(currentSentId);
    }
    int currentCharId = 0;
    for (RegExpMatch split in sentenceSplit.allMatches(sentence)) {
      if (split.start > 20 + currentCharId &&
          split.end < sentence.length - 20) {
        sentenceParts.add(
          sentence.substring(currentCharId, split.start).replaceAll(strip, ''),
        );
        currentCharId = split.start;
      }
    }
    sentenceParts.add(sentence.substring(currentCharId).replaceAll(strip, ''));
    return sentenceParts;
  }

  //Splits the input text into sentences, if the sentence is too long then tries to split where there are pauses
  List<String> splitSentences(String text) {
    List<String> sentences = [];

    if (text.length == 1) {
      sentences.add(text.toUpperCase());
      return sentences;
    }

    int currentSentId = 0;
    for (RegExpMatch match in sentencesSplit.allMatches(text)) {
      sentences.addAll(_splitSentence(text, currentSentId, match));
      currentSentId = match.end;
    }
    if (currentSentId < text.length) {
      //if last sentence doesn't end with .!?
      sentences.addAll(_splitSentence(text, currentSentId, null));
    }
    logger.d('Text split into sentences/sentence parts:$sentences');
    return sentences;
  }
}

class Preprocessor {
  Logger logger = Logger();

  RegExp CURLY_RE = RegExp(r'(.*?)\{(.+?)\}(.*)');
  RegExp DECIMALS_RE = RegExp(
    r'([0-9]+[,.][0-9]+)|([0-9]{1,3}(,[0-9]{3})+.[0-9]+)',
  );
  RegExp CURRENCY_RE = RegExp(
    r'([£\$€]((\d+[.,])?\d+))|(((\d+[.,])?\d+)[£\$€])',
  );
  RegExp ORDINAL_RE = RegExp(r'[0-9]+\.');
  RegExp NUMBER_RE = RegExp(r'[0-9]+');
  RegExp TRINUMBER_RE = RegExp(r'[0-9][0-9]?[0-9]?( [0-9]{3})+');
  RegExp DECIMALSCURRENCYNUMBER_RE = RegExp(
    r'(([0-9]+[,.][0-9]+)|([£\$€]((\d+[.,])?\d+))|(((\d+[.,])?\d+)[£\$€])|[0-9]+\.?)',
  );

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
    "eest",
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
    "WiFi",
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
    '−': 'miinus',
    '-': 'kuni',
    '–': 'kuni',
  };
  static Map<String, String> ABBREVIATIONS = {
    'apr': 'aprill',
    'aug': 'august',
    'aü': 'ametiühing',
    'ca': 'tsirka',
    'Ca': 'CA',
    'CA': 'CA',
    'cA': 'CA',
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
    'kM': 'KM',
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
    'mM': 'MM',
    'mnt': 'maantee',
    'm²': 'ruutmeeter',
    'm³': 'kuupmeeter',
    'Mr': 'mister',
    'mr': 'mister',
    'Ms': 'miss',
    'ms': 'miss',
    'Mrs': 'missis',
    'mrs': 'missis',
    'n-ö': 'nii-öelda',
    'nim': 'nimeline',
    'nn': 'niinimetatud',
    'nov': 'november',
    'nr': 'number',
    'nt': 'näiteks',
    'NT': 'NT',
    'nT': 'NT',
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
    'pS': 'PS',
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
    'sKP': 'SKP',
    'sl': 'supilusikatäis',
    'sm': 'seltsimees',
    'SM': 'SM',
    'sM': 'SM',
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
    'hz': 'herts',
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
    'A': 'aaa',
    'B': 'beee',
    'C': 'tseee',
    'D': 'deee',
    'E': 'eeee',
    'F': 'eff',
    'G': 'geee',
    'H': 'hhaa',
    'I': 'iii',
    'J': 'jott',
    'K': 'khaa',
    'L': 'ell',
    'M': 'emmm',
    'N': 'ennn',
    'O': 'ooo',
    'P': 'ppee',
    'Q': 'khuu',
    'R': 'errr',
    'S': 'ess',
    'Š': 'šhaa',
    'Z': 'tzett',
    'Ž': 'žžeee',
    'T': 'tteee',
    'U': 'uu',
    'V': 'veee',
    'W': 'kaksisvee',
    'Õ': 'õõõ',
    'Ä': 'ää',
    'Ö': 'öö',
    'Ü': 'üü',
    'X': 'iks',
    'Y': 'igrek',
  };

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
          label,
          m.group(1).toString() + target + m.group(2).toString(),
        );
      } else if (m.groupCount == 3) {
        text = text.replaceFirst(
          label,
          m.group(1).toString() + target + m.group(3).toString(),
        );
      }
      m = label.firstMatch(text);
    }
    return text;
  }

  static String _romanToArabic(String word) {
    String endingWord = "";
    RegExp pattern = RegExp(r'-?[a-z]+$');
    RegExpMatch? m = pattern.firstMatch(word);
    String newword = word;
    if (m != null) {
      endingWord =
          " ${word.substring(m.start).startsWith("-") ? word.substring(m.start + 1) : word.substring(m.start)}";
      newword = word.substring(0, m.start);
    }
    if (RegExp(r'I{4}').hasMatch(word) ||
        RegExp(r'X{4}').hasMatch(word) ||
        RegExp(r'C{4}').hasMatch(word) ||
        RegExp(r'V{2}').hasMatch(word) ||
        RegExp(r'L{2}').hasMatch(word) ||
        RegExp(r'D{2}').hasMatch(word)) {
      return word;
    }
    newword = newword.replaceAll("IV", "IIII").replaceAll("IX", "VIIII");
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
    return "$sum.$endingWord";
  }

  String _expandAbbreviations(String text) {
    for (MapEntry<String, String> entry in ABBREVIATIONS.entries) {
      text = text.replaceAll(RegExp(r"\\b" + entry.key + "\\."), entry.value);
    }
    return text;
  }

  String _unifyNumberPunctuation(String text) {
    if (text.contains(".") && text.contains(",") ||
        text.characters.where((p0) => p0 == ',').length > 1) {
      return text.replaceAll(",", "");
    }
    return text;
  }

  String _expandCurrency(String text, String kaane) {
    String s = text;
    s = s.replaceAll("\\.", ",");
    bool match = CURRENCY_RE.hasMatch(s);
    if (match) {
      String curr = 'N';
      if (text.contains('\$')) {
        curr = '\$';
      } else if (text.contains("€")) {
        curr = '€';
      } else if (text.contains("£")) {
        curr = '£';
      }
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
          spelling += parts[0] + CURRENCIES["${curr}g"]!;
        } else if ("1" == moneys || "01" == moneys) {
          spelling += parts[0] + CURRENCIES["${curr}s"]!;
        } else {
          spelling += parts[0] + CURRENCIES["${curr}m"]!;
        }
      }
      if ("0" != cents && "00" != cents) {
        spelling += " ja -";
        if (kaane == 'O') {
          spelling += parts[0] + CURRENCIES["${curr}cg"]!;
        }

        if ("1" == cents || "01" == cents) {
          spelling += parts[1] + CURRENCIES["${curr}cs"]!;
        } else {
          spelling += parts[1] + CURRENCIES["${curr}cm"]!;
        }
      }
      text = text.replaceFirst(text, spelling);
    }
    return text;
  }

  String _expandDecimals(String text) {
    RegExpMatch? m = DECIMALS_RE.firstMatch(text);
    while (m != null) {
      String s = text.substring(m.start, m.end);
      if (s.contains(".") && s.contains(",")) {
        s = s.replaceAll(",", "");
      }
      s = s.replaceAll(RegExp(r"[.,]"), " koma ");
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
      String numText = text.substring(m.start, m.end);
      String spelling = "";
      while (numText.startsWith("0")) {
        spelling += "null ";
        numText = numText.substring(1);
      }
      if (numText.isNotEmpty) {
        int l = int.parse(numText);
        spelling += NumberNormEt.numToString(l, kaane);
      }
      text = text.replaceFirst(text.substring(m.start, m.end), spelling);
      m = NUMBER_RE.firstMatch(text);
    }
    return text;
  }

  String _expandNumbers(String text, String kaane) {
    List<String> parts = text.split(" ");
    for (int i = 0; i < parts.length; i++) {
      parts[i] = _unifyNumberPunctuation(parts[i]);
      parts[i] = _expandCurrency(parts[i], kaane);
      parts[i] = _expandDecimals(parts[i]);
      if (parts[i].endsWith(".")) {
        parts[i] = _expandOrdinals(parts[i], kaane);
      }
      parts[i] = _expandCardinals(parts[i], kaane);
    }
    return parts.join(' ');
  }

  String _processByWord(List<String> tokens) {
    List<String> newTextParts = [];
    // process every word separately
    for (int i = 0; i < tokens.length; i++) {
      String word = tokens[i];
      String ending = '';
      if (word.endsWith(',')) {
        word = word.substring(0, word.length - 1);
        ending = ',';
      }
      // if current token is a symbol
      if (!RegExp(
        r'([A-ZÄÖÜÕŽŠa-zäöüõšž]+(\.(?!( [A-ZÄÖÜÕŽŠ])))?)|([£$€]?[0-9.,]+[£$€]?)',
      ).hasMatch(word)) {
        if (AUDIBLE_SYMBOLS.containsKey(word)) {
          if (AUDIBLE_CONNECTING_SYMBOLS.contains(word) &&
              !(i > 0 &&
                  i < tokens.length - 1 &&
                  DECIMALSCURRENCYNUMBER_RE.hasMatch(tokens[i - 1]) &&
                  DECIMALSCURRENCYNUMBER_RE.hasMatch(tokens[i + 1]))) {
            continue;
          } else {
            newTextParts.add(AUDIBLE_SYMBOLS[word]! + ending);
          }
        } else {
          newTextParts.add(word + ending);
        }
        continue;
      }
      // roman numbers to arabic
      if (RegExp(r'^[IVXLCDM]+(-\w*)?$').hasMatch(word)) {
        word = _romanToArabic(word);
        if (word.split(' ').length > 1) {
          newTextParts.add(_processByWord(word.split(' ')) + ending);
          continue;
        }
      }
      // numbers & currency to words
      if (DECIMALSCURRENCYNUMBER_RE.hasMatch(word)) {
        String kaane = 'N';
        if ((i > 0 && GENITIVE_PREPOSITIONS.contains(tokens[i - 1])) ||
            (i < tokens.length - 1 &&
                GENITIVE_POSTPOSITIONS.contains(tokens[i + 1])) ||
            (i < tokens.length - 2 &&
                [
                  CURRENCIES['\$g'],
                  CURRENCIES['€g'],
                ].contains(" ${tokens[i + 1]}") &&
                GENITIVE_POSTPOSITIONS.contains(tokens[i + 2]))) {
          kaane = 'O';
        }
        word = _expandNumbers(word, kaane);
      }
      // abbreviations
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
      // single letters
      if (word.length == 1) {
        String character = word.toUpperCase();
        if (ALPHABET.containsKey(character)) {
          word = ALPHABET[character]!;
        }
      }

      newTextParts.add(word + ending);
    }
    return newTextParts.join(' ');
  }

  String _cleanTextForEstonian(String text) {
    //Temporarily remove sentence end symbol
    String sentEnd = '.';
    String lastChar = text.substring(text.length - 1);
    if ('.!?'.contains(lastChar)) {
      sentEnd = lastChar;
      text = text.substring(0, text.length - 1);
    }
    // ... between numbers to kuni
    RegExpMatch? m = RegExp(r'(\d)\.\.\.(\d)').firstMatch(text);
    while (m != null) {
      text = '${m.group(1)} kuni ${m.group(2)}';
      m = RegExp(r'(\d)\.\.\.(\d)').firstMatch(text);
    }
    // reduce Unicode repertoire _before_ inserting any hyphens
    //text = _convertToUtf8(text);
    text = _simplifyUnicode(text);

    // add a hyphen between any number-letter sequences  # TODO should not be done in URLs
    text = _subBetween(text, RegExp(r'(\d)([A-ZÄÖÜÕŽŠa-zäöüõšž])'), '-');
    text = _subBetween(text, RegExp(r'([A-ZÄÖÜÕŽŠa-zäöüõšž])(\d)'), '-');

    // remove grouping between numbers
    // keeping space in 2006-10-27 12:48:50, in general require group of 3
    m = TRINUMBER_RE.firstMatch(text);
    while (m != null) {
      String num = text.substring(m.start, m.end);
      text = text.replaceAll(num, num.replaceAll(" ", ""));
      m = TRINUMBER_RE.firstMatch(text);
    }
    //text = _subBetween(text, RegExp(r'([0-9]) ([0-9]{3})(?!\d)'), '');
    if (text.length > 1 &&
        text.substring(1, 2).toLowerCase() == text.substring(1, 2)) {
      text = text.substring(0, 1).toLowerCase() + text.substring(1);
    }

    //Replace dash with comma
    text = text.replaceAll(" – ", ", ");
    //Remove end of quote before comma
    text = text.replaceAll(",\"", ",");

    bool ru = false;
    if (RuProcessor.alphabet.split('').any(text.contains)) {
      ru = true;
      text = RuProcessor.transcribe(text);
    }

    // split text into words ands symbols
    RegExp tokenizer = RegExp(r'([A-ZÄÖÜÕŽŠa-zäöüõšž@#0-9.,£$€]+)|\S');
    List<String> tokens = [];
    for (RegExpMatch match in tokenizer.allMatches(text)) {
      tokens.add(text.substring(match.start, match.end));
    }

    text = _processByWord(tokens);
    text = text.toLowerCase();
    text += sentEnd;
    text = _collapseWhitespace(text);
    if (!ru) {
      text = _expandAbbreviations(text);
    }
    text = text.toLowerCase();

    logger.d('Text preprocessed:$text');
    return text;
  }

  Future<String> preprocess(String sentence) async {
    if (sentence.length == 1) {
      String? pronunciation = ALPHABET[sentence];
      if (pronunciation != null) {
        return "$pronunciation.";
      }
      return ".";
    }
    List<String> sequence = [];
    while (sentence.isNotEmpty) {
      RegExpMatch? m = CURLY_RE.firstMatch(sentence);
      if (m == null) {
        sequence.addAll(_cleanTextForEstonian(sentence).split(''));
        break;
      }
      sequence.addAll(_cleanTextForEstonian(m.group(1)!).split(''));

      sentence = m.group(3)!;
    }
    return sequence.join('');
  }
}

class RuProcessor {
  static Map<String, String> d = {
    'а': 'a',
    'б': 'b',
    'в': 'v',
    'г': 'g',
    'д': 'd',
    'ж': 'ž',
    'з': 'z',
    'к': 'k',
    'л': 'l',
    'м': 'm',
    'н': 'n',
    'о': 'o',
    'п': 'p',
    'р': 'r',
    'т': 't',
    'у': 'u',
    'ф': 'f',
    'ц': 'ts',
    'ч': 'tš',
    'ш': 'š',
    'щ': 'štš',
    'ъ': '',
    'ы': 'õ',
    'э': 'e',
    'ю': 'ju',
  };

  static String alphabet = "абвгджзклмнопртуфцчшщъыэюийеёсхья";
  static String vowels = "аеёиоуыэюя";

  static int numberOfSyllables(String word) {
    return syllables.splitWord(word).length;
  }

  // "и" : üldjuhul "i"/sõna algul vokaali ees "j"
  // "й" : üldjuhul "i"/sõna algul vokaali ees "j"
  // "ий" : üldjuhul "ii"/kahe- ja enamasilbilise sõna lõpul "i"
  static String i(String word, int id) {
    if (word.length > 1) {
      if (id == 0 && vowels.contains(word[id + 1])) {
        return 'j';
      } else if (id == word.length - 1 &&
          word.endsWith('ий') &&
          numberOfSyllables(word) >= 2) {
        return '';
      }
    }
    return 'i';
  }

  // "e" : üldjuhul "e"/sõna algul, samuti vokaali, ь- ning ъ-märgi järel "je"
  static String e(String word, int id) {
    if (id == 0 || vowels.contains(word[id - 1]) || word[id - 1] == 'ъ') {
      return 'je';
    }
    return 'e';
  }

  // "ё" : üldjuhul "jo"/ж, ч, ш, щ järel "o"; Märkus. Täht е-ga märgitud ё transkribeeritakse nagu ё
  static String jo(String word, int id) {
    if (id > 0 && ['ж', 'ч', 'ш', 'щ', 'ь'].contains(word[id - 1])) {
      return 'o';
    }
    return 'jo';
  }

  // "с" : üldjuhul "s"/vokaalide vahel ja sõna lõpul vokaali järel "ss"; Märkus. Liitsõnalise nime järelkomponendi algul oleva с-i võib asendada ühekordse s-iga (Новосибирск = Novosibirsk)
  static String s(String word, int id) {
    if (id > 0) {
      if (id == word.length - 1 && vowels.contains(word[id - 1]) ||
          id < word.length - 1 &&
              vowels.contains(word[id - 1]) &&
              vowels.contains(word[id + 1])) {
        return 'ss';
      }
    }
    return 's';
  }

  // "х" : üldjuhul "h"/vokaalide vahel ja sõna lõpul vokaali järel "hh"; Märkus. Liitsõnalise nime järelkomponendi algul oleva х võib asendada ühekordse h-ga (Самоходов = Samohodov)
  static String h(String word, int id) {
    if (id > 0) {
      if (id == word.length - 1 && vowels.contains(word[id - 1]) ||
          id < word.length - 1 &&
              vowels.contains(word[id - 1]) &&
              vowels.contains(word[id + 1])) {
        return 'hh';
      }
    }
    return 'h';
  }

  // "ь" : üldjuhul jääb märkimata/vokaali, välja arvatud e, ё, ю, я ees "j"
  static String snak(String word, int id) {
    if (id < word.length - 1) {
      if (['e', 'ё'].contains(word[id + 1])) {
        return 'j';
      }
    }
    return '';
  }

  // "я" : üldjuhul "ja"/Väljaspool dokumente ja teatmeteoseid võib eesnimede lõpul и järel я asendada a-ga (Евгения = Jevgenia, Лидия = Lidia)
  static String ja(String word, int id) {
    return 'ja';
  }

  static String transcribeWord(String word) {
    String lower_word = word.toLowerCase();
    String new_word = '';
    for (int id = 0; id < lower_word.length; id++) {
      switch (lower_word[id]) {
        case 'и' || 'й':
          new_word += i(lower_word, id);
          break;
        case 'е':
          new_word += e(lower_word, id);
          break;
        case 'ё':
          new_word += jo(lower_word, id);
          break;
        case 'с':
          new_word += s(lower_word, id);
          break;
        case 'х':
          new_word += h(lower_word, id);
          break;
        case 'ь':
          new_word += snak(lower_word, id);
          break;
        case 'я':
          new_word += ja(lower_word, id);
          break;
        default:
          if (d.keys.contains(lower_word[id])) {
            new_word += d[lower_word[id]]!;
          }
      }
    }
    if (word != lower_word) {
      return new_word[0].toUpperCase() + new_word.substring(1);
    }
    return new_word;
  }

  static String transcribe(String text) {
    List<String> output = [];
    RegExp regex = RegExp(
      r"[\u0401\u0451\u0410-\u044f]+|[^\u0401\u0451\u0410-\u044f]+",
    );
    while (regex.hasMatch(text)) {
      RegExpMatch match = regex.firstMatch(text)!;
      String word = match.group(0)!;
      if (alphabet.contains(word[0].toLowerCase())) {
        word = transcribeWord(word);
      }
      output.add(word);
      text = text.substring(match.end);
    }
    return output.join('');
  }
}

//Processing of numbers into Estonian
class NumberNormEt {
  static final Map<String, String> ordinalMap = {
    'null': 'nullis',
    'üks': 'esimene',
    'kaks': 'teine',
    'kolm': 'kolmas',
    'neli': 'neljas',
    'viis': 'viies',
    'kuus': 'kuues',
    'seitse': 'seitsmes',
    'kaheksa': 'kaheksas',
    'üheksa': 'üheksas',
    'kümmend': 'kümnes',
    //'kümme': 'kümnes',
    'teist': 'teistkümnes',
    'sada': 'sajas',
    'tuhat': 'tuhandes',
    'miljon': 'miljones',
    'miljard': 'miljardes',
    'triljon': 'triljones',
    'kvadriljon': 'kvadriljones',
    'kvintiljon': 'kvintiljones',
    //'sekstiljon': 'sekstiljones',
    //'septiljon': 'septiljones','
  };
  static final Map<String, String> genitiveMap = {
    'null': 'nulli',
    'üks': 'ühe',
    'kaks': 'kahe',
    'kolm': 'kolme',
    'neli': 'nelja',
    'viis': 'viie',
    'kuus': 'kuue',
    'seitse': 'seitsme',
    'kaheksa': 'kaheksa',
    'üheksa': 'üheksa',
    'kümmend': 'kümne',
    //'kümme': 'kümne',
    'teist': 'teistkümne',
    'sada': 'saja',
    'tuhat': 'tuhande',
    'miljon': 'miljoni',
    'miljard': 'miljardi',
    'triljon': 'triljoni',
    'kvadriljon': 'kvadriljoni',
    'kvintiljon': 'kvintiljoni',
    //'sekstiljon': 'sekstiljoni',
    //'septiljon': 'septiljoni',
  };
  static final Map<String, String> ordinalGenitiveMap = {
    'null': 'nullinda',
    'üks': 'esimese',
    'kaks': 'teise',
    'kolm': 'kolmanda',
    'neli': 'neljanda',
    'viis': 'viienda',
    'kuus': 'kuuenda',
    'seitse': 'seitsmenda',
    'kaheksa': 'kaheksanda',
    'üheksa': 'üheksanda',
    'kümmend': 'kümnenda',
    // 'kümme': 'kümnenda',
    'teist': 'teistkümnenda',
    'sada': 'sajanda',
    'tuhat': 'tuhandenda',
    'miljon': 'miljoninda',
    'miljard': 'miljardinda',
    'triljon': 'triljoninda',
    'kvadriljon': 'kvadriljoninda',
    'kvintiljon': 'kvintiljoninda',
    //'sekstiljon': 'sekstiljoninda',
    //'septiljon': 'septiljoninda',
  };
  static final Map<int, String> CARDINAL_NUMBERS = {
    1: 'tuhat',
    2: 'miljon',
    3: 'miljard',
    4: 'triljon',
    5: 'kvadriljon',
    6: 'kvintiljon',
    //7: 'sekstiljon',
    //8: 'septiljon',
  };
  static final List<String> nums = [
    'null',
    'üks',
    'kaks',
    'kolm',
    'neli',
    'viis',
    'kuus',
    'seitse',
    'kaheksa',
    'üheksa',
    'kümme',
  ];

  static String toOrdinal(int n, String kaane) {
    String spelling = numToString(n, 'N');
    List<String> split = spelling.split(' ');
    String last = split.removeLast();
    if (kaane == 'N') {
      for (String key in ordinalMap.keys) {
        if (last.endsWith(key)) {
          last = last.replaceAll(key, ordinalMap[key]!);
        } else {
          last = last.replaceAll(key, genitiveMap[key]!);
        }
      }
      last = last.replaceAll('kümme', 'kümnes');
    } else if (kaane == 'O') {
      for (MapEntry<String, String> entry in ordinalGenitiveMap.entries) {
        last = last.replaceAll(entry.key, entry.value);
      }
      last = last.replaceAll('kümme', 'kümnenda');
    }
    if (split.isNotEmpty) {
      String text = _toGenitive(split);
      last = '$text $last';
    }
    return last;
  }

  static String _toGenitive(List<String> words) {
    for (String word in words) {
      if (word.endsWith('it')) {
        words[words.indexOf(word)] = word.substring(0, word.length - 2);
      }
    }
    String text = words.join(' ');
    for (MapEntry<String, String> entry in genitiveMap.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    return text.replaceAll('kümme', 'kümne');
  }

  static String numToString(int n, String kaane) {
    String helperOut = _numToStringHelper(n);
    if (kaane == 'O') {
      helperOut = _toGenitive(helperOut.split(' '));
    }
    if (helperOut.length > 4 && !helperOut.startsWith("üheksa")) {
      return helperOut.replaceFirst(RegExp(r'^ü((ks)|(he)) ?'), '');
    }
    return helperOut;
  }

  static String _numToStringHelper(int n) {
    if (n < 0) {
      return ' miinus ${_numToStringHelper(-n)}';
    }
    int index = n;
    if (n <= 10) {
      return nums[index];
    } else if (n <= 19) {
      return '${nums[index - 10]}teist';
    } else if (n <= 99) {
      return '${nums[(index / 10).floor()]}kümmend${n % 10 > 0 ? ' ${_numToStringHelper(n % 10)}' : ''}';
    } else if (n <= 999) {
      return '${(index / 100).floor() == 1 ? '' : nums[(index / 100).floor()]}sada${n % 100 > 0 ? ' ${_numToStringHelper(n % 100)}' : ''}';
    }
    int factor = 0;
    if (n <= 999999) {
      factor = 1;
    } else if (n <= 999999999) {
      factor = 2;
    } else if (n <= 999999999999) {
      factor = 3;
    } else if (n <= 999999999999999) {
      factor = 4;
    } else if (n <= 999999999999999999) {
      factor = 5;
    } else {
      factor = 6;
    }
    return '${_numToStringHelper((n / math.pow(1000, factor)).floor())} ${CARDINAL_NUMBERS[factor]!}${factor != 1 ? 'it' : ''}${n % math.pow(1000, factor) > 0 ? ' ${_numToStringHelper((n % math.pow(1000, factor)).floor())}' : ''}';
  }
}
