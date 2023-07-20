package com.tartunlp.neurokone;

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

class Processor {
    private static final String TAG = "processor";

    private static final Pattern sentencesSplit = Pattern.compile("[.!?]((((\" )| |( \"))(?![a-zäöüõšž]))|(\"?$))");
    private static final Pattern sentenceSplit = Pattern.compile("(?<!^)([,;!?]\"? )|( ((ja)|(ning)|(ega)|(ehk)|(või)) )");
    private static final String sentenceStrip = "^[,;!?]?\"? ?";

    //private static final Pattern CURLY_RE = Pattern.compile("(.*?)\\{(.+?)\\}(.*)");
    private static final Pattern DECIMALS_RE = Pattern.compile("([0-9]+[,.][0-9]+)");
    private static final String CURRENCY_RE = "([£$€]((\\d+[.,])?\\d+))|(((\\d+[.,])?\\d+)[£$€])";
    private static final Pattern ORDINAL_RE = Pattern.compile("[0-9]+\\.");
    private static final Pattern NUMBER_RE = Pattern.compile("[0-9]+");
    private static final Pattern DECIMALSCURRENCYNUMBER_RE = Pattern.compile("(([0-9]+[,.][0-9]+)|([£$€]((\\d+[.,])?\\d+))|(((\\d+[.,])?\\d+)[£$€])|[0-9]+\\.?)");
    private static final HashMap<String, String> CURRENCIES = new HashMap<>();
    static {
        CURRENCIES.put("£s", " nael ");
        CURRENCIES.put("£m", " naela ");
        CURRENCIES.put("£g", " naela ");
        CURRENCIES.put("£cs", " penn ");
        CURRENCIES.put("£cm", " penni ");
        CURRENCIES.put("£cg", " penni ");
        CURRENCIES.put("$s", " dollar ");
        CURRENCIES.put("$m", " dollarit ");
        CURRENCIES.put("$g", " dollari ");
        CURRENCIES.put("$cs", " sent ");
        CURRENCIES.put("$cm", " senti ");
        CURRENCIES.put("$cg", " sendi ");
        CURRENCIES.put("€s", " euro ");
        CURRENCIES.put("€m", " eurot ");
        CURRENCIES.put("€g", " euro ");
        CURRENCIES.put("€cs", " sent ");
        CURRENCIES.put("€cm", " senti ");
        CURRENCIES.put("€cg", " sendi ");
    }

    // sümbolid, mis häälduvad vaid siis, kui asuvad kahe arvu vahel
    private static final String[] AUDIBLE_CONNECTING_SYMBOLS = {"×", "x", "*", "/", "-"};

    // sümbolid ja lühendid, mis käänduvad vastavalt eelnevale arvule (nt 1 meeter vs 5 meetrit)
    // private static final String[] UNITS = {"%", "‰", "°", "a", "atm", "km", "km²", "m", "m²", "m³", "mbar", "cm",
    //        "ct", "d", "dB", "eks", "h", "ha", "hj", "hl", "mm", "tk", "p", "rbl", "rm", "lk",
    //        "pk", "s", "sl", "spl", "sek", "tk", "tl", "kr", "min", "t", "mln", "mld", "mg",
    //        "g", "kg", "ml", "l", "cl", "dl",
    //        "V", "Hz", "W", "kW", "kWh"};

    // kaassõnad, mille korral eelnev või järgnev arvsõna läheb omastavasse käändesse
    private static final String[] GENITIVE_PREPOSITIONS = {"üle", "alla"};
    private static final String[] GENITIVE_POSTPOSITIONS = {"võrra", "ümber", "pealt", "peale", "ringis", "paiku", "aegu", "eest"};

    // sõnad, mille korral järgnev arvsõna läheb nimetavasse käändesse (kui oma kääne määramata)
    //private static final String[] NOMINATIVE_PRECEEDING_WORDS = {"kell", "number", "aasta", "kl", "nr", "a"};

    private static final String[] PRONOUNCEABLE_ACRONYMS = {"ABBA", "AIDS", "ALDE", "API", "ARK", "ATKO",
            "BAFTA", "BENU", "CERN", "CRISPR", "COVID", "DARPA",
            "EFTA", "EKA", "EKI", "EKRE", "EKSA", "EMO", "EMOR", "ERM", "ERSO", "ESTO", "ETA", "EÜE",
            "FIDE", "FIFA", "FISA",
            "GAZ", "GITIS", "IBAN", "IPA", "ISIC", "ISIS", "ISO", "JOKK", "NASA", "NATO",
            "PERH", "PID", "PIN", "PRIA", "RAF", "RET",
            "SALT", "SARS", "SETI", "SIG", "SIM", "SMIT", "SORVVO", "TASS",
            "UNESCO", "VAZ", "VEB", "WADA", "WiFi"};

    private static final Map<String, String> AUDIBLE_SYMBOLS = new HashMap<>();
    static {AUDIBLE_SYMBOLS.put("@", "ät");
        AUDIBLE_SYMBOLS.put("$", "dollar");
        AUDIBLE_SYMBOLS.put("%", "protsent");
        AUDIBLE_SYMBOLS.put("&", "ja");
        AUDIBLE_SYMBOLS.put("+", "pluss");
        AUDIBLE_SYMBOLS.put("=", "võrdub");
        AUDIBLE_SYMBOLS.put("€", "euro");
        AUDIBLE_SYMBOLS.put("£", "nael");
        AUDIBLE_SYMBOLS.put("§", "paragrahv");
        AUDIBLE_SYMBOLS.put("°", "kraad");
        AUDIBLE_SYMBOLS.put("±", "pluss miinus");
        AUDIBLE_SYMBOLS.put("‰", "promill");
        AUDIBLE_SYMBOLS.put("×", "korda");
        AUDIBLE_SYMBOLS.put("x", "korda");
        AUDIBLE_SYMBOLS.put("*", "korda");
        AUDIBLE_SYMBOLS.put("∙", "korda");
        AUDIBLE_SYMBOLS.put("/", "jagada");
        AUDIBLE_SYMBOLS.put("-", "miinus");}

    // any symbols still left unreplaced (neutral character namings which may be different from audible_symbols)
    // used on the final text right before output as str.maketrans dictionary, thus the spaces
    /*
    private static final Map<String, String> LAST_RESORT = new HashMap<>();
    static {
        LAST_RESORT.put("@", " ätt ");
        LAST_RESORT.put("=", " võrdub ");
        LAST_RESORT.put("/", " kaldkriips ");
        LAST_RESORT.put("(", " sulgudes ");
        LAST_RESORT.put("#", " trellid ");
        LAST_RESORT.put("*", " tärn ");
        LAST_RESORT.put("&", " ampersand ");
        LAST_RESORT.put("%", " protsent ");
        LAST_RESORT.put("_", " allkriips ");
    }*/
    private static final Map<String, String> ABBREVIATIONS = new HashMap<>();
    static {
        ABBREVIATIONS.put("apr", "aprill");
        ABBREVIATIONS.put("aug", "august");
        ABBREVIATIONS.put("aü", "ametiühing");
        ABBREVIATIONS.put("ca", "tsirka");
        ABBREVIATIONS.put("Ca", "CA");
        ABBREVIATIONS.put("CA", "CA");
        ABBREVIATIONS.put("cl", "sentiliiter");
        ABBREVIATIONS.put("cm", "sentimeeter");
        ABBREVIATIONS.put("dB", "detsibell");
        ABBREVIATIONS.put("dets", "detsember");
        ABBREVIATIONS.put("dl", "detsiliiter");
        ABBREVIATIONS.put("dr", "doktor");
        ABBREVIATIONS.put("e.m.a", "enne meie ajaarvamist");
        ABBREVIATIONS.put("eKr", "enne Kristuse sündi");
        ABBREVIATIONS.put("hj", "hobujõud");
        ABBREVIATIONS.put("hr", "härra");
        ABBREVIATIONS.put("hrl", "harilikult");
        ABBREVIATIONS.put("IK", "isikukood");
        ABBREVIATIONS.put("ingl", "inglise keeles");
        ABBREVIATIONS.put("j.a", "juures asuv");
        ABBREVIATIONS.put("jaan", "jaanuar");
        ABBREVIATIONS.put("jj", "ja järgmine");
        ABBREVIATIONS.put("jm", "ja muud");
        ABBREVIATIONS.put("jms", "ja muud sellised");
        ABBREVIATIONS.put("jmt", "ja mitmed teised");
        ABBREVIATIONS.put("jn", "joonis");
        ABBREVIATIONS.put("jne", "ja nii edasi");
        ABBREVIATIONS.put("jpt", "ja paljud teised");
        ABBREVIATIONS.put("jr", "juunior");
        ABBREVIATIONS.put("Jr", "juunior");
        ABBREVIATIONS.put("jsk", "jaoskond");
        ABBREVIATIONS.put("jt", "ja teised");
        ABBREVIATIONS.put("jun", "juunior");
        ABBREVIATIONS.put("jv", "järv");
        ABBREVIATIONS.put("k.a", "kaasa arvatud");
        ABBREVIATIONS.put("kcal", "kilokalor");
        ABBREVIATIONS.put("kd", "köide");
        ABBREVIATIONS.put("kg", "kilogramm");
        ABBREVIATIONS.put("kk", "keskkool");
        ABBREVIATIONS.put("kl", "kell");
        ABBREVIATIONS.put("klh", "kolhoos");
        ABBREVIATIONS.put("km", "kilomeeter");
        ABBREVIATIONS.put("KM", "KM");
        ABBREVIATIONS.put("km/h", "kilomeetrit tunnis");
        ABBREVIATIONS.put("km²", "ruutkilomeeter");
        ABBREVIATIONS.put("kod", "kodanik");
        ABBREVIATIONS.put("kpl", "kauplus");
        ABBREVIATIONS.put("kr", "kroon");
        ABBREVIATIONS.put("krt", "korter");
        ABBREVIATIONS.put("kt", "kohusetäitja");
        ABBREVIATIONS.put("kv", "kvartal");
        ABBREVIATIONS.put("lg", "lõige");
        ABBREVIATIONS.put("lk", "lehekülg");
        ABBREVIATIONS.put("LK", "looduskaitse");
        ABBREVIATIONS.put("lp", "lugupeetud");
        ABBREVIATIONS.put("LP", "LP");
        ABBREVIATIONS.put("lüh", "lühend");
        ABBREVIATIONS.put("m.a.j", "meie ajaarvamise järgi");
        ABBREVIATIONS.put("m/s", "meetrit sekundis");
        ABBREVIATIONS.put("mbar", "millibaar");
        ABBREVIATIONS.put("mg", "milligramm");
        ABBREVIATIONS.put("mh", "muu hulgas");
        ABBREVIATIONS.put("ml", "milliliiter");
        ABBREVIATIONS.put("mld", "miljard");
        ABBREVIATIONS.put("mln", "miljon");
        ABBREVIATIONS.put("mm", "millimeeter");
        ABBREVIATIONS.put("MM", "MM");
        ABBREVIATIONS.put("mnt", "maantee");
        ABBREVIATIONS.put("m²", "ruutmeeter");
        ABBREVIATIONS.put("m³", "kuupmeeter");
        ABBREVIATIONS.put("Mr", "mister");
        ABBREVIATIONS.put("Ms", "miss");
        ABBREVIATIONS.put("Mrs", "missis");
        ABBREVIATIONS.put("n-ö", "nii-öelda");
        ABBREVIATIONS.put("nim", "nimeline");
        ABBREVIATIONS.put("nn", "niinimetatud");
        ABBREVIATIONS.put("nov", "november");
        ABBREVIATIONS.put("nr", "number");
        ABBREVIATIONS.put("nt", "näiteks");
        ABBREVIATIONS.put("NT", "NT");
        ABBREVIATIONS.put("okt", "oktoober");
        ABBREVIATIONS.put("p.o", "peab olema");
        ABBREVIATIONS.put("pKr", "pärast Kristuse sündi");
        ABBREVIATIONS.put("pa", "poolaasta");
        ABBREVIATIONS.put("pk", "postkast");
        ABBREVIATIONS.put("pms", "peamiselt");
        ABBREVIATIONS.put("pr", "proua");
        ABBREVIATIONS.put("prl", "preili");
        ABBREVIATIONS.put("prof", "professor");
        ABBREVIATIONS.put("ps", "poolsaar");
        ABBREVIATIONS.put("PS", "PS");
        ABBREVIATIONS.put("pst", "puiestee");
        ABBREVIATIONS.put("ptk", "peatükk");
        ABBREVIATIONS.put("raj", "rajoon");
        ABBREVIATIONS.put("rbl", "rubla");
        ABBREVIATIONS.put("reg-nr", "registreerimisnumber");
        ABBREVIATIONS.put("rg-kood", "registrikood");
        ABBREVIATIONS.put("rmtk", "raamatukogu");
        ABBREVIATIONS.put("rmtp", "raamatupidamine");
        ABBREVIATIONS.put("rtj", "raudteejaam");
        ABBREVIATIONS.put("s.a", "sel aastal");
        ABBREVIATIONS.put("s.o", "see on");
        ABBREVIATIONS.put("s.t", "see tähendab");
        ABBREVIATIONS.put("saj", "sajand");
        ABBREVIATIONS.put("sealh", "sealhulgas");
        ABBREVIATIONS.put("seals", "sealsamas");
        ABBREVIATIONS.put("sen", "seenior");
        ABBREVIATIONS.put("sept", "september");
        ABBREVIATIONS.put("sh", "sealhulgas");
        ABBREVIATIONS.put("skp", "selle kuu päeval");
        ABBREVIATIONS.put("SKP", "SKP");
        ABBREVIATIONS.put("sl", "supilusikatäis");
        ABBREVIATIONS.put("sm", "seltsimees");
        ABBREVIATIONS.put("SM", "SM");
        ABBREVIATIONS.put("snd", "sündinud");
        ABBREVIATIONS.put("spl", "supilusikatäis");
        ABBREVIATIONS.put("srn", "surnud");
        ABBREVIATIONS.put("stj", "saatja");
        ABBREVIATIONS.put("surn", "surnud");
        ABBREVIATIONS.put("sü", "säilitusüksus");
        ABBREVIATIONS.put("sünd", "sündinud");
        ABBREVIATIONS.put("tehn", "tehniline");
        ABBREVIATIONS.put("tel", "telefon");
        ABBREVIATIONS.put("tk", "tükk");
        ABBREVIATIONS.put("tl", "teelusikatäis");
        ABBREVIATIONS.put("tlk", "tõlkija");
        ABBREVIATIONS.put("tn", "tänav");
        ABBREVIATIONS.put("tv", "televisioon");
        ABBREVIATIONS.put("u", "umbes");
        ABBREVIATIONS.put("ukj", "uue); Gregoriuse kalendri järgi");
        ABBREVIATIONS.put("v.a", "välja arvatud");
        ABBREVIATIONS.put("veebr", "veebruar");
        ABBREVIATIONS.put("vkj", "vana); Juliuse kalendri järgi");
        ABBREVIATIONS.put("vm", "või muud");
        ABBREVIATIONS.put("vms", "või muud sellist");
        ABBREVIATIONS.put("vrd", "võrdle");
        ABBREVIATIONS.put("vt", "vaata");
        ABBREVIATIONS.put("õa", "õppeaasta");
        ABBREVIATIONS.put("õp", "õpetaja");
        ABBREVIATIONS.put("õpil", "õpilane");
        ABBREVIATIONS.put("V", "volt");
        ABBREVIATIONS.put("Hz", "herts");
        ABBREVIATIONS.put("W", "vatt");
        ABBREVIATIONS.put("kW", "kilovatt");
        ABBREVIATIONS.put("kWh", "kilovatttund");
    }
    private static final Map<Character, Integer> ROMAN_NUMBERS = new HashMap<>();
    static {
        ROMAN_NUMBERS.put('I', 1);
        ROMAN_NUMBERS.put('V', 5);
        ROMAN_NUMBERS.put('X', 10);
        ROMAN_NUMBERS.put('L', 50);
        ROMAN_NUMBERS.put('C', 100);
        ROMAN_NUMBERS.put('D', 500);
        ROMAN_NUMBERS.put('M', 1000);
    }
    private static final Map<Character, String> ALPHABET = new HashMap<>();
    static {
        ALPHABET.put('A', "aa");
        ALPHABET.put('B', "bee");
        ALPHABET.put('C', "tsee");
        ALPHABET.put('D', "dee");
        ALPHABET.put('E', "ee");
        ALPHABET.put('F', "eff");
        ALPHABET.put('G', "gee");
        ALPHABET.put('H', "haa");
        ALPHABET.put('I', "ii");
        ALPHABET.put('J', "jott");
        ALPHABET.put('K', "kaa");
        ALPHABET.put('L', "ell");
        ALPHABET.put('M', "emm");
        ALPHABET.put('N', "enn");
        ALPHABET.put('O', "oo");
        ALPHABET.put('P', "pee");
        ALPHABET.put('Q', "kuu");
        ALPHABET.put('R', "err");
        ALPHABET.put('S', "ess");
        ALPHABET.put('Š', "šaa");
        ALPHABET.put('Z', "zett");
        ALPHABET.put('Ž', "žee");
        ALPHABET.put('T', "tee");
        ALPHABET.put('U', "uu");
        ALPHABET.put('V', "vee");
        ALPHABET.put('W', "kaksisvee");
        ALPHABET.put('Õ', "õõ");
        ALPHABET.put('Ä', "ää");
        ALPHABET.put('Ö', "öö");
        ALPHABET.put('Ü', "üü");
        ALPHABET.put('X', "iks");
        ALPHABET.put('Y', "igrek");
    }

    private String convertToUtf8(String text) {
        byte[] bytes = text.getBytes(StandardCharsets.UTF_8);
        return new String(bytes);
    }

    private String simplifyUnicode(String sentence) {
        sentence = sentence.replace("Ð", "D").replace("Þ", "Th");
        sentence = sentence.replace("ð", "d").replace("þ", "th");
        sentence = sentence.replace("ø", "ö").replace("Ø", "Ö");
        sentence = sentence.replace("ß", "ss").replace("ẞ", "Ss");
        sentence = sentence.replaceAll("S[cC][hH]", "Š");
        sentence = sentence.replaceAll("sch", "š");
        sentence = sentence.replaceAll("[ĆČ]", "Tš");
        sentence = sentence.replaceAll("[ćč]", "tš");
        sentence = sentence.replaceAll("—", ",");

        //sentence = Normalizer.normalize(sentence, Normalizer.Form.NFD);
        sentence = Normalizer.normalize(sentence, Normalizer.Form.NFC);
        //sentence = Normalizer.normalize(sentence, Normalizer.Form.NFKC);
        sentence = sentence.replaceAll("\\p{M}", "");

        return sentence;
    }

    private String collapseWhitespace(String text) {
        return text.replaceAll("\\s+", " ");
    }

    private static String subBetween(String text, String label, String target) {
        Matcher m = Pattern.compile(label).matcher(text);
        while (m.find()) {
            if (m.groupCount() == 2)
                text = text.replaceFirst(label, m.group(1) + target + m.group(2));
            else if (m.groupCount() == 3)
                text = text.replaceFirst(label, m.group(1) + target + m.group(3));
        }
        return text;
    }

    private static String romanToArabic(String word) {
        String endingWord = "";
        Matcher m = Pattern.compile("-[a-z]+$").matcher(word);
        if (m.find())
            endingWord = " " + (m.group().startsWith("-") ? m.group().substring(1) : m.group());
        if (word.matches("[IXC]{4}"))
            return word;
        else if (word.matches("[VLD]{2}"))
            return word;
        String newword = word.replace("IV", "IIII").replace("IX", "VIIII");
        newword = newword.replace("XL", "XXXX").replace("XC", "LXXXX");
        newword = newword.replace("CD", "CCCC").replace("CM", "DCCCC");
        if (newword.matches("[IXC]{5}"))
            return word;
        int sum = 0;
        int max = 1000;
        for (char ch : newword.toCharArray()) {
            Integer i = ROMAN_NUMBERS.get(ch);
            assert i != null;
            if (i > max)
                return word;
            max = i;
            sum += i;
        }
        return sum + "." + endingWord;
    }

    private String expandAbbreviations(String text) {
        for (Map.Entry<String, String> entry : ABBREVIATIONS.entrySet()) {
            text = text.replaceAll("\\b" + entry.getKey() + "\\.", entry.getValue());
        }
        return text;
    }

    private String expandCurrency(String text, char kaane) {
        String s = text;
        if (text.contains(".") && text.contains(","))
            s = text.replaceAll(",", "");
        s = s.replaceAll("\\.", ",");
        boolean match = s.matches(CURRENCY_RE);
        char curr = 'N';
        if (text.contains("$"))
            curr = '$';
        else if (text.contains("€"))
            curr = '€';
        else if (text.contains("£"))
            curr = '£';
        if (match) {
            String moneys = "0";
            String cents = "0";
            String spelling = "";
            s = s.replaceAll("[£$€]", "");
            String[] parts = s.split(",");
            if (!s.startsWith(",")) {
                moneys = parts[0];
            }
            if (!s.endsWith(",") && parts.length > 1) {
                cents = parts[1];
            }
            if (!"0".equals(moneys)) {
                if (kaane == 'O')
                    spelling += parts[0] + CURRENCIES.get(curr + "g");
                else if ("1".equals(moneys) || "01".equals(moneys))
                    spelling += parts[0] + CURRENCIES.get(curr + "s");
                else
                    spelling += parts[0] + CURRENCIES.get(curr + "m");
            }
            if (!"0".equals(cents) && !"00".equals(cents)) {
                spelling += " ja ";
                if (kaane == 'O')
                    spelling += parts[0] + CURRENCIES.get(curr + "cg");
                if ("1".equals(cents) || "01".equals(cents))
                    spelling += parts[1] + CURRENCIES.get(curr + "cs");
                else
                    spelling += parts[1] + CURRENCIES.get(curr + "cm");
            }
            text = text.replaceFirst("\\" + text, spelling);
        }
        return text;
    }

    private String expandDecimals(String text) {
        Matcher m = DECIMALS_RE.matcher(text);
        while (m.find()) {
            String s = m.group().replaceAll("[.,]", " koma ");
            text = text.replaceFirst(m.group(), s);
        }
        return text;
    }

    private String expandOrdinals(String text, char kaane) {
        Matcher m = ORDINAL_RE.matcher(text);
        while (m.find()) {
            String s = m.group().substring(0, m.group().length() - 1);
            long l = Long.parseLong(s);
            String spelling = NumberNormEt.toOrdinal(l, kaane);
            text = text.replaceFirst(m.group(), spelling);
        }
        return text;
    }

    private String expandCardinals(String text, char kaane) {
        Matcher m = NUMBER_RE.matcher(text);
        while (m.find()) {
            long l = Long.parseLong(m.group());
            String spelling = NumberNormEt.numToString(l, kaane);
            text = text.replaceFirst(m.group(), spelling);
        }
        return text;
    }

    private String expandNumbers(String text, char kaane) {
        String[] parts = text.split(" ");
        for (int i = 0; i < parts.length; i++) {
            parts[i] = expandCurrency(parts[i], kaane);
            parts[i] = expandDecimals(parts[i]);
            if (kaane != 'N' || parts[i].endsWith("."))
                parts[i] = expandOrdinals(parts[i], kaane);
            parts[i] = expandCardinals(parts[i], kaane);
        }
        return String.join(" ", parts);
    }

    private String processByWord(List<String> tokens) {
        ArrayList<String> newTextParts = new ArrayList<>();
        // process every word separately
        for (int i=0; i<tokens.size(); i++) {
            String word = tokens.get(i);
            // if current token is a symbol
            if (!word.matches("([A-ZÄÖÜÕŽŠa-zäöüõšž]+(\\.(?!( [A-ZÄÖÜÕŽŠ])))?)|([£$€]?[0-9.,]+[£$€]?)")) {
                if (AUDIBLE_SYMBOLS.containsKey(word)) {
                    if (Arrays.asList(AUDIBLE_CONNECTING_SYMBOLS).contains(word) &&
                            !(i > 0 && i < tokens.size()-1 &&
                                    tokens.get(i-1).matches(DECIMALSCURRENCYNUMBER_RE.pattern()) &&
                                    tokens.get(i+1).matches(DECIMALSCURRENCYNUMBER_RE.pattern()))) {
                        continue;
                    } else {
                        newTextParts.add(AUDIBLE_SYMBOLS.get(word));
                    }
                }
                else
                    newTextParts.add(word);
                continue;
            }
            // roman numbers to arabic
            if (word.matches("^[IVXLCDM]+(-\\w*)?$")) {
                word = romanToArabic(word);
                if (word.split(" ").length > 1) {
                    newTextParts.add(processByWord(Arrays.asList(word.split(" "))));
                    continue;
                }
            }
            // numbers & currency to words
            if (word.matches(DECIMALSCURRENCYNUMBER_RE.pattern())) {
                char kaane = 'N';
                if ((i > 0 && Arrays.asList(GENITIVE_PREPOSITIONS).contains(tokens.get(i-1))) || (i < tokens.size()-1 && Arrays.asList(GENITIVE_POSTPOSITIONS).contains(tokens.get(i+1))))
                    kaane = 'O';
                //else if (i > 0 && Arrays.asList(NOMINATIVE_PRECEEDING_WORDS).contains(tokens.get(i-1)))
                //    kaane = 'N';
                word = expandNumbers(word, kaane);
            }

            if (word.endsWith("."))
                word = word.substring(0,word.length()-1);
            if (ABBREVIATIONS.containsKey(word))
                word = ABBREVIATIONS.get(word);
            else if (word.matches("[A-ZÄÖÜÕŽŠ]+")) {
                if (!Arrays.asList(PRONOUNCEABLE_ACRONYMS).contains(word)) {
                    ArrayList<String> newword = new ArrayList<>();
                    for (char c : word.toCharArray()) newword.add(ALPHABET.get(c));
                    word = String.join("-", newword);
                }
            }
            newTextParts.add(word);
        }
        return String.join(" ", newTextParts);
    }

    private String cleanTextForEstonian(String text) {
        // ... between numbers to kuni
        Matcher m = Pattern.compile("(\\d)\\.\\.\\.(\\d)").matcher(text);
        if (m.find())
            text = m.group(1) + " kuni " + m.group(2);

        // reduce Unicode repertoire _before_ inserting any hyphens
        text = convertToUtf8(text);
        text = simplifyUnicode(text);

        // add a hyphen between any number-letter sequences  # TODO should not be done in URLs
        text = subBetween(text, "(\\d)([A-ZÄÖÜÕŽŠa-zäöüõšž])", "-");
        text = subBetween(text, "([A-ZÄÖÜÕŽŠa-zäöüõšž])(\\d)", "-");

        // remove grouping between numbers
        // keeping space in 2006-10-27 12:48:50, in general require group of 3
        text = subBetween(text, "([0-9]) ([0-9]{3})(?!\\d)", "");
        text = text.substring(0,1).toLowerCase() + text.substring(1);

        // split text into words ands symbols

        Matcher tokenizer = Pattern.compile("([A-ZÄÖÜÕŽŠa-zäöüõšž@#0-9.,£$€]+)|\\S").matcher(text);
        ArrayList<String> tokens = new ArrayList<>();
        while (tokenizer.find())
            tokens.add(text.substring(tokenizer.start(), tokenizer.end()));

        text = processByWord(tokens);
        text = text.toLowerCase();
        text += ".";
        text = collapseWhitespace(text);
        text = expandAbbreviations(text);

        Log.d(TAG, "text preprocessed: " + text);
        return text;
    }

    private String processSentence(String text) {
        List<String> sequence = new ArrayList<>();
        while (text!= null && text.length() > 0) {
            Matcher m = Pattern.compile("(.*?)\\{(.+?)\\}(.*)").matcher(text);
            if (!m.find()) {
                sequence.add(cleanTextForEstonian(text));
                break;
            }
            sequence.add(cleanTextForEstonian(m.group(1)));
            sequence.add(m.group(2));
            text = m.group(3);
        }
        return String.join(" ", sequence);
    }

    public List<String> splitSentences(String remainingText) {
        List<String> sentences = new ArrayList<>();
        int currentSentId = 0;
        Matcher matcher;
        if (!remainingText.matches(".+[.!?]\"?$")) {
            remainingText += ".";
        }
        while ((matcher = sentencesSplit.matcher(remainingText)).find(currentSentId)) {
            String sentence = remainingText.substring(currentSentId, matcher.start());
            currentSentId = matcher.end();
            int currentCharId = 0;
            int lastSplitId = 0;
            Matcher splitmatcher;
            while ((splitmatcher = sentenceSplit.matcher(sentence)).find(currentCharId)) {
                int start = splitmatcher.start();
                int end = splitmatcher.end();
                if (start > 20 + lastSplitId &&
                        end < sentence.length() - 20) {
                    String sentToAdd = processSentence(sentence
                            .substring(lastSplitId, start)
                            .replaceAll(sentenceStrip, "") +
                            '.');
                    if (sentToAdd.matches(".*[a-z].*")) sentences.add(sentToAdd);
                    lastSplitId = start;
                    currentCharId = start;
                } else {
                    currentCharId = end;
                }
            }
            String sentToAdd = processSentence(sentence.substring(lastSplitId).replaceAll(sentenceStrip, "") + '.');
            if (sentToAdd.matches(".*[a-z].*")) sentences.add(sentToAdd);
        }
        return sentences;
    }
}

class NumberNormEt {

    private static final Map<String,String> ordinalMap = new HashMap<>();
    static {
        ordinalMap.put("null", "nullis");
        ordinalMap.put("üks", "esimene");
        ordinalMap.put("kaks", "teine");
        ordinalMap.put("kolm", "kolmas");
        ordinalMap.put("neli", "neljas");
        ordinalMap.put("viis", "viies");
        ordinalMap.put("kuus", "kuues");
        ordinalMap.put("seitse", "seitsmes");
        ordinalMap.put("kaheksa", "kaheksas");
        ordinalMap.put("üheksa", "üheksas");
        ordinalMap.put("kümmend", "kümnes");
        //ordinalMap.put("kümme", "kümnes");
        ordinalMap.put("teist", "teistkümnes");
        ordinalMap.put("sada", "sajas");
        ordinalMap.put("tuhat", "tuhandes");
        ordinalMap.put("miljon", "miljones");
        ordinalMap.put("miljard", "miljardes");
        ordinalMap.put("triljon", "triljones");
        ordinalMap.put("kvadriljon", "kvadriljones");
        ordinalMap.put("kvintiljon", "kvintiljones");
        //ordinalMap.put("sekstiljon", "sekstiljones");
        //ordinalMap.put("septiljon", "septiljones");
    }
    private static final Map<String,String> genitiveMap = new HashMap<>();
    static {
        genitiveMap.put("null", "nulli");
        genitiveMap.put("üks", "ühe");
        genitiveMap.put("kaks", "kahe");
        genitiveMap.put("kolm", "kolme");
        genitiveMap.put("neli", "nelja");
        genitiveMap.put("viis", "viie");
        genitiveMap.put("kuus", "kuue");
        genitiveMap.put("seitse", "seitsme");
        genitiveMap.put("kaheksa", "kaheksa");
        genitiveMap.put("üheksa", "üheksa");
        genitiveMap.put("kümmend", "kümne");
        //genitiveMap.put("kümme", "kümne");
        genitiveMap.put("teist", "teistkümne");
        genitiveMap.put("sada", "saja");
        genitiveMap.put("tuhat", "tuhande");
        genitiveMap.put("miljon", "miljoni");
        genitiveMap.put("miljard", "miljardi");
        genitiveMap.put("triljon", "triljoni");
        genitiveMap.put("kvadriljon", "kvadriljoni");
        genitiveMap.put("kvintiljon", "kvintiljoni");
        //genitiveMap.put("sekstiljon", "sekstiljoni");
        //genitiveMap.put("septiljon", "septiljoni");
    }
    private static final Map<String,String> ordinalGenitiveMap = new HashMap<>();
    static {
        ordinalGenitiveMap.put("null", "nullinda");
        ordinalGenitiveMap.put("üks", "esimese");
        ordinalGenitiveMap.put("kaks", "teise");
        ordinalGenitiveMap.put("kolm", "kolmanda");
        ordinalGenitiveMap.put("neli", "neljanda");
        ordinalGenitiveMap.put("viis", "viienda");
        ordinalGenitiveMap.put("kuus", "kuuenda");
        ordinalGenitiveMap.put("seitse", "seitsmenda");
        ordinalGenitiveMap.put("kaheksa", "kaheksanda");
        ordinalGenitiveMap.put("üheksa", "üheksanda");
        ordinalGenitiveMap.put("kümmend", "kümnenda");
        // ordinalGenitiveMap.put("kümme", "kümnenda");
        ordinalGenitiveMap.put("teist", "teistkümnenda");
        ordinalGenitiveMap.put("sada", "sajanda");
        ordinalGenitiveMap.put("tuhat", "tuhandenda");
        ordinalGenitiveMap.put("miljon", "miljoninda");
        ordinalGenitiveMap.put("miljard", "miljardinda");
        ordinalGenitiveMap.put("triljon", "triljoninda");
        ordinalGenitiveMap.put("kvadriljon", "kvadriljoninda");
        ordinalGenitiveMap.put("kvintiljon", "kvintiljoninda");
        //ordinalGenitiveMap.put("sekstiljon", "sekstiljoninda");
        //ordinalGenitiveMap.put("septiljon", "septiljoninda");
    }
    private static final Map<Integer,String> CARDINAL_NUMBERS = new HashMap<>();
    static {
        CARDINAL_NUMBERS.put(1, "tuhat");
        CARDINAL_NUMBERS.put(2, "miljon");
        CARDINAL_NUMBERS.put(3, "miljard");
        CARDINAL_NUMBERS.put(4, "triljon");
        CARDINAL_NUMBERS.put(5, "kvadriljon");
        CARDINAL_NUMBERS.put(6, "kvintiljon");
        //CARDINAL_NUMBERS.put(7, "sekstiljon");
        //CARDINAL_NUMBERS.put(8, "septiljon");
    }
    private static final String[] nums = new String[] {"null", "üks", "kaks", "kolm", "neli", "viis", "kuus", "seitse", "kaheksa", "üheksa", "kümme"};


    public static String toOrdinal(long n, char kaane) {
        String spelling = numToString(n, 'N');
        String[] split = spelling.split(" ");
        String last = split[split.length-1];
        if (kaane == 'N') {
            for (String key : ordinalMap.keySet()) {
                if (last.endsWith(key))
                    last = last.replaceAll(key, ordinalMap.get(key));   //näiteks kuus<kümmend> => kuus<kümnes>
                else last = last.replaceAll(key, genitiveMap.get(key)); //näiteks <kuus>kümmend => <kuue>kümmend
            }
            last = last.replaceAll("kümme", "kümnes");
        }
        else if (kaane == 'O') {
            for (String key : ordinalGenitiveMap.keySet())
                last = last.replaceAll(key, ordinalGenitiveMap.get(key));
            last = last.replaceAll("kümme", "kümnenda");
        }
        if (split.length >= 2) {
            ArrayList<String> parts = new ArrayList<>();
            for (int i=0; i< split.length-1; i++)
                parts.add(split[i]);
            String text = toGenitive(parts);
            last = text + " " + last;
        }
        return last;
    }

    public static String toGenitive(ArrayList<String> words) {
        for (String word : words)
            if (word.endsWith("it"))
                words.set(words.indexOf(word), word.substring(0, word.length()-2));
        String text = String.join(" ", words);
        for (String key : genitiveMap.keySet())
            text = text.replaceAll(key, genitiveMap.get(key));
        return text.replaceAll("kümme", "kümne");
    }

    public static final String numToString(long n, char kaane) {
        String helperOut = numToStringHelper(n);
        if (kaane == 'O')
            return toGenitive(new ArrayList<>(Arrays.asList(helperOut.split(" "))));
        return helperOut.replaceAll("^üks ", "");
    }

    private static final String numToStringHelper(long n) {
        if ( n < 0 ) {
            return " miinus " + numToStringHelper(-n);
        }
        int index = (int) n;
        if ( n <= 10 ) {
            return nums[index];
        }
        else if ( n <= 19 )
            return nums[index-10] + "teist";
        else if ( n <= 99 ) {
            return nums[index/10] + "kümmend" + (n % 10 > 0 ? " " + numToStringHelper(n % 10) : "");
        }
        else if ( n <= 999 ) {
            return (index/100 == 1 ? "" : nums[index/100]) + "sada" + (n % 100 > 0 ? " " + numToStringHelper(n % 100) : "");
        }
        int factor = 0;
        if ( n <= 999999)
            factor = 1;
        else if ( n <= 999999999)
            factor = 2;
        else if ( n <= 999999999999L)
            factor = 3;
        else if ( n <= 999999999999999L)
            factor = 4;
        else if ( n <= 999999999999999999L)
            factor = 5;
        else
            factor = 6;
        return numToStringHelper(n / (long) Math.pow(1000,factor)) + " " +
                CARDINAL_NUMBERS.get(factor) + (factor != 1 ? "it" : "") +
                (n % Math.pow(1000,factor) > 0 ? " " + numToStringHelper(n % (long) Math.pow(1000,factor)) : "");
    }
}