import 'package:logger/logger.dart';
import 'dart:math' as Math;
import 'package:unorm_dart/unorm_dart.dart' as unorm;

class EstProcessor {
  Logger logger = Logger();
  //For splitting the whole text into sentences.
  RegExp sentencesSplit =
      RegExp(r'[.!?]((((" )| |( "))(?=[a-zõäöüšžA-ZÕÄÖÜŠŽ0-9]))|("?$))');
  //For splitting long sentences into parts
  RegExp sentenceSplit =
      RegExp(r'(?<!^)([,;!?]"? )|( ((ja)|(ning)|(ega)|(ehk)|(või)) )');
  //For stripping unnecessary symbols from the beginning
  RegExp strip = RegExp(r'^[,;!?]?"? ?');

  List<String> _splitSentence(
      String text, int currentSentId, RegExpMatch? match) {
    List<String> sentenceParts = [];
    String sentence;
    if (match != null) {
      sentence = text.substring(currentSentId, match.start);
    } else {
      sentence = text.substring(currentSentId);
    }
    int currentCharId = 0;
    for (RegExpMatch split in this.sentenceSplit.allMatches(sentence)) {
      if (split.start > 20 + currentCharId &&
          split.end < sentence.length - 20) {
        sentenceParts.add(sentence
                .substring(currentCharId, split.start)
                .replaceAll(this.strip, '') +
            '.');
        currentCharId = split.start;
      }
    }
    sentenceParts
        .add(sentence.substring(currentCharId).replaceAll(this.strip, '') + '.');
    return sentenceParts;
  }

  //Splits the input text into sentences, if the sentence is too long then tries to split where there are pauses
  List<String> _splitSentences(String text) {
    List<String> sentences = [];
    int currentSentId = 0;
    for (RegExpMatch match in this.sentencesSplit.allMatches(text)) {
      sentences.addAll(_splitSentence(text, currentSentId, match));
      currentSentId = match.end;
    }
    if (currentSentId < text.length) {
      //if last sentence doesn't end with .!?
      sentences.addAll(_splitSentence(text, currentSentId, null));
    }
    this.logger
        .d('Text split into sentences/sentence parts:' + sentences.toString());
    return sentences;
  }

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
    String newword = word;
    if (m != null) {
      endingWord = " " +
          (word.substring(m.start).startsWith("-")
              ? word.substring(m.start + 1)
              : word.substring(m.start));
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
      if (RegExp(r'^[IVXLCDM]+(-\w*)?$').hasMatch(word)) {
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
    text = text.toLowerCase();

    this.logger.d('Text preprocessed:' + text);
    return text;
  }

  Future<List<String>> preprocess(String text) async {
    List<String> splitText = _splitSentences(text);
    List<String> newSentences = [];
    for (String sentence in splitText) {
      //String sequence = '';
      List<String> sequence = [];
      while (sentence.isNotEmpty) {
        RegExpMatch? m = CURLY_RE.firstMatch(sentence);
        if (m == null) {
          //sequence += _cleanTextForEstonian(text)
          sequence.addAll(_cleanTextForEstonian(sentence).split(''));
          break;
        }
        //sequence += _cleanTextForEstonian(m.group(1)!);
        sequence.addAll(_cleanTextForEstonian(m.group(1)!).split(''));

        //sequence.addAll(_arpabetToSequence(m.group(2)!));
        sentence = m.group(3)!;
      }
      //sentences.add(sequence)
      newSentences.add(sequence.join(''));
    }
    return newSentences;
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
    'kümme'
  ];

  static String toOrdinal(int n, String kaane) {
    String spelling = numToString(n, 'N');
    List<String> split = spelling.split(' ');
    String last = split[-1];
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
    if (split.length >= 2) {
      String text = _toGenitive(split);
      last = text + ' ' + last;
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
      return _toGenitive(helperOut.split(' '));
    }
    return helperOut.replaceAll(r'^üks ', '');
  }

  static String _numToStringHelper(int n) {
    if (n < 0) {
      return ' miinus ' + _numToStringHelper(-n);
    }
    int index = n;
    if (n <= 10) {
      return nums[index];
    } else if (n <= 19) {
      return nums[index - 10] + 'teist';
    } else if (n <= 99) {
      return nums[(index / 10).floor()] +
          'kümmend' +
          (n % 10 > 0 ? ' ' + _numToStringHelper(n % 10) : '');
    } else if (n <= 999) {
      return ((index / 100).floor() == 1 ? '' : nums[(index / 100).floor()]) +
          'sada' +
          (n % 100 > 0 ? ' ' + _numToStringHelper(n % 100) : '');
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
    return _numToStringHelper((n / Math.pow(1000, factor)).floor()) +
        ' ' +
        CARDINAL_NUMBERS[factor]! +
        (factor != 1 ? 'it' : '') +
        (n % Math.pow(1000, factor) > 0
            ? ' ' + _numToStringHelper((n % Math.pow(1000, factor)).floor())
            : '');
  }
}
