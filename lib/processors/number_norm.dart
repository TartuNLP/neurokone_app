import 'dart:math';

class NumberNormEn {
  static final Map<String, String> ordinalMap = {
    'one': 'first',
    'two': 'second',
    'three': 'third',
    'five': 'fifth',
    'eight': 'eighth',
    'nine': 'ninth',
    'twelve': 'twelfth',
  };
  static final List<String> nums = [
    'zero',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine',
    'ten',
    'eleven',
    'twelve',
    'thirteen',
    'fourteen',
    'fifteen',
    'sixteen',
    'seventeen',
    'eighteen',
    'nineteen'
  ];
  static final List<String> tens = [
    'zero',
    'ten',
    'twenty',
    'thirty',
    'forty',
    'fifty',
    'sixty',
    'seventy',
    'eighty',
    'ninety'
  ];

  static String toOrdinal(int n) {
    String spelling = numToString(n);
    List<String> split = spelling.split(' ');
    String last = split[-1];
    String replace = '';
    if (last.contains('-')) {
      List<String> lastSplit = last.split('-');
      String lastWithDash = lastSplit[1];
      String lastReplace = '';
      if (ordinalMap.containsKey(lastWithDash)) {
        lastReplace = ordinalMap[lastWithDash]!;
      } else if (lastWithDash.endsWith('y')) {
        lastReplace =
            lastWithDash.substring(0, lastWithDash.length - 1) + 'ieth';
      } else {
        lastReplace = lastWithDash + "th";
      }
      replace = lastSplit[0] + '-' + lastReplace;
    } else {
      if (ordinalMap.containsKey(last)) {
        replace = ordinalMap[last]!;
      } else if (last.endsWith('y')) {
        replace = last.substring(0, last.length - 1) + 'ieth';
      } else {
        replace = last + 'th';
      }
    }
    split[-1] = replace;
    return split.join(' ');
  }

  static String numToString(int n) {
    return _numToStringHelper(n);
  }

  static String _numToStringHelper(int n) {
    if (n < 0) {
      return 'negative ' + _numToStringHelper(-n);
    }
    int index = n;
    if (n <= 19) {
      return nums[index];
    }
    if (n <= 99) {
      return tens[(index / 10).floor()] +
          (n % 10 > 0 ? '-' + _numToStringHelper(n % 10) : '');
    }
    String label = '';
    int factor = 0;
    if (n <= 999) {
      label = 'hundred';
      factor = 100;
    } else if (n <= 999999) {
      label = 'thousand';
      factor = 1000;
    } else if (n <= 999999999) {
      label = "million";
      factor = 1000000;
    } else if (n <= 999999999999) {
      label = "billion";
      factor = 1000000000;
    } else if (n <= 999999999999999) {
      label = "trillion";
      factor = 1000000000000;
    } else if (n <= 999999999999999999) {
      label = "quadrillion";
      factor = 1000000000000000;
    } else {
      label = "quintillion";
      factor = 1000000000000000000;
    }
    return _numToStringHelper((n / factor).floor()) +
        " " +
        label +
        (n % factor > 0 ? " " + _numToStringHelper(n % factor) : "");
  }
}

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
    return _numToStringHelper((n / pow(1000, factor)).floor()) +
        ' ' +
        CARDINAL_NUMBERS[factor]! +
        (factor != 1 ? 'it' : '') +
        (n % pow(1000, factor) > 0
            ? ' ' + _numToStringHelper((n % pow(1000, factor)).floor())
            : '');
  }
}
