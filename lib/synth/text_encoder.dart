import 'dart:developer';
import 'package:flutter/material.dart';

class Encoder {
  static List<String> SYMBOLS = [
    'pad',
    '-', //
    ' ',
    '!',
    '\"',
    "'", //
    ',',
    '.',
    ':', //
    ';', //
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
    'š', //
    't',
    'u',
    'v',
    'w',
    'õ', //
    'ä', //
    'ö', //
    'ü', //
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
  static Map<String, int> SYMBOL_TO_ID = {};

  Encoder() {
    for (int i = 0; i < SYMBOLS.length; i++) {
      SYMBOL_TO_ID[SYMBOLS[i]] = i;
    }
  }

  List<int> textToIds(String symbols) {
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
}
