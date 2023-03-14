package com.tartunlp.eesti_tts;

import android.util.Log;

import androidx.annotation.Nullable;

import java.nio.charset.StandardCharsets;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

class Encoder {
    private static final String TAG = "encoder";

    private static final List<String> SYMBOLS = new ArrayList<>();
    static {
        SYMBOLS.add("pad");
        SYMBOLS.add("-"); //
        SYMBOLS.add(" ");
        SYMBOLS.add("!");
        SYMBOLS.add("\"");
        SYMBOLS.add("'"); //
        SYMBOLS.add(",");
        SYMBOLS.add(".");
        SYMBOLS.add(":"); //
        SYMBOLS.add(";"); //
        SYMBOLS.add("?");
        SYMBOLS.add("a");
        SYMBOLS.add("b");
        SYMBOLS.add("c");
        SYMBOLS.add("d");
        SYMBOLS.add("e");
        SYMBOLS.add("f");
        SYMBOLS.add("g");
        SYMBOLS.add("h");
        SYMBOLS.add("i");
        SYMBOLS.add("j");
        SYMBOLS.add("k");
        SYMBOLS.add("l");
        SYMBOLS.add("m");
        SYMBOLS.add("n");
        SYMBOLS.add("o");
        SYMBOLS.add("p");
        SYMBOLS.add("q");
        SYMBOLS.add("r");
        SYMBOLS.add("s");
        SYMBOLS.add("š"); //
        SYMBOLS.add("t");
        SYMBOLS.add("u");
        SYMBOLS.add("v");
        SYMBOLS.add("w");
        SYMBOLS.add("õ"); //
        SYMBOLS.add("ä"); //
        SYMBOLS.add("ö"); //
        SYMBOLS.add("ü"); //
        SYMBOLS.add("x");
        SYMBOLS.add("y");
        SYMBOLS.add("z");
        //  'ä',
        //  'õ',
        //  'ö',
        //  'ü',
        //  'š',
        SYMBOLS.add("ž");
        SYMBOLS.add("eos");
    }
    private static final Map<String, Integer> SYMBOL_TO_ID = new HashMap<>();

    public Encoder() {
        for (int i = 0; i < SYMBOLS.size(); ++i) {
            SYMBOL_TO_ID.put(SYMBOLS.get(i), i);
        }
    }

    public List<Integer> textToIds(String symbols) {
        List<Integer> sequence = new ArrayList<>();
        for (int i = 0; i < symbols.length(); ++i) {
            Integer id = SYMBOL_TO_ID.get(String.valueOf(symbols.charAt(i)));
            if (id == null) {
                Log.e(TAG, "symbolsToSequence: id is not found for " + symbols.charAt(i));
            } else {
                sequence.add(id);
            }
        }
        return sequence;
    }
}