//
//  Processor.swift
//  EestiTtsiOS
//
//  Created by Rasmus Lellep on 03.05.2023.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//

import Foundation

class SentProcessor {
    private final let sentencesSplit = /[.!?]((((\" )| |( \"))(?![a-zäöüõšž]))|(\"?$))/
    //private final let sentencesSplit = /[.!?]((((\" )| |( \")))|(\"?$))/
    private final let sentenceSplit = /*(?<!^)*//([,;!?]\"? )|( ((ja)|(ning)|(ega)|(ehk)|(või)|–) )/ //lookahead functionality (?<!^) needs to be replaced until it is supported in Swift
    private final let sentenceStrip: String = "(^[,;!?–]?\"? ?)|([,;!?–]?\"? ?$)"
    
    private func splitSentence(sent: String)  -> [String] {
        //For splitting sentences if they're too long for the synthesizer
        var sentence = sent
        var sentenceParts: [String] = []
        var startId = sentence.startIndex
        while let splitMatch = sentence[startId...].firstMatch(of: sentenceSplit) {
            if sentence.distance(from: sentence.startIndex, to: splitMatch.range.lowerBound) > 30 && sentence.distance(from: splitMatch.range.upperBound, to: sentence.endIndex) > 30 {
                
                // if lookahead doesn't work
                sentenceParts.append(String(sentence[..<splitMatch.range.upperBound]).replacingOccurrences(of: sentenceStrip, with: "", options: .regularExpression))
                sentence = String(sentence[splitMatch.range.upperBound...])
                startId = sentence.startIndex
                
                // if lookahead works
                //sentenceParts.append(String(sentence[..<splitMatch.range.lowerBound]).replacingOccurrences(of: sentenceStrip, with: "", options: .regularExpression))
                //sentence = String(sentence[splitMatch.range.lowerBound])
                
            } else {
                startId = splitMatch.range.upperBound
            }
        }
        sentenceParts.append(sentence.replacingOccurrences(of: sentenceStrip, with: "", options: .regularExpression))
        return sentenceParts
    }
    
    // input format: <speak><voice name="extension-identifier.voice-identifier">text</voice></speak>
    func splitSentences(text: String) -> [String] {
        var sentences: [String] = []
        let allText: String = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let paragraphs = allText.replacingOccurrences(of: "\n+", with: "\n", options: .regularExpression).split(separator: "\n")
        for currentParagraph in paragraphs {
            var remainingSents = currentParagraph
            if remainingSents.wholeMatch(of: /.+[.!?]\"?$/) == nil {
                remainingSents += "."
            }
            while let sentMatch = remainingSents.firstMatch(of: sentencesSplit) {
                let sentence: String = String(remainingSents[..<sentMatch.range.lowerBound + 1])
                remainingSents = remainingSents[sentMatch.range.upperBound...]
                
                //sentences.append(contentsOf: splitSentence(sent: sentence))
                sentences.append(sentence)
            }
            sentences[sentences.count - 1] += "\n"
        }
        return sentences
    }
}

class Preprocessor {
    private final let CURLY_RE = /(.*?)\{(.+?)\}(.*)/
    private final let DECIMALS_RE = /([0-9]+[,.][0-9]+)/
    private final let CURRENCY_RE = /([£$€]((\d+[.,])?\d+))|(((\d+[.,])?\d+)[£$€])/
    private final let ORDINAL_RE = /[0-9]+\./
    private final let NUMBER_RE = /[0-9]+/
    private final let TRINUMBER_RE = /[0-9][0-9]?[0-9]?( [0-9]{3})+/
    private final let DECIMALSCURRENCYNUMBER_RE = /([0-9]+[,.][0-9]+)|([£$€]((\d+[.,])?\d+))|(((\d+[.,])?\d+)[£$€])|([0-9]+\.?)/
    private final let CURRENCIES = [
        "£s": " nael ",
        "£m": " naela ",
        "£g": " naela ",
        "£cs": " penn ",
        "£cm": " penni ",
        "£cg": " penni ",
        "$s": " dollar ",
        "$m": " dollarit ",
        "$g": " dollari ",
        "$cs": " sent ",
        "$cm": " senti ",
        "$cg": " sendi ",
        "€s": " euro ",
        "€m": " eurot ",
        "€g": " euro ",
        "€cs": " sent ",
        "€cm": " senti ",
        "€cg": " sendi ",
    ]
    
    // sümbolid, mis häälduvad vaid siis, kui asuvad kahe arvu vahel
    private final let AUDIBLE_CONNECTING_SYMBOLS = ["×", "x", "*", "/", "-"]
    
    // sümbolid ja lühendid, mis käänduvad vastavalt eelnevale arvule (nt 1 meeter vs 5 meetrit)
    // private static let UNITS = ["%", "‰", "°", "a", "atm", "km", "km²", "m", "m²", "m³", "mbar", "cm", "ct", "d", "dB", "eks", "h", "ha", "hj", "hl", "mm", "tk", "p", "rbl", "rm", "lk", "pk", "s", "sl", "spl", "sek", "tk", "tl", "kr", "min", "t", "mln", "mld", "mg", "g", "kg", "ml", "l", "cl", "dl", "V", "Hz", "W", "kW", "kWh"]
    
    // kaassõnad, mille korral eelnev või järgnev arvsõna läheb omastavasse käändesse
    private final let GENITIVE_PREPOSITIONS = ["üle", "alla"]
    private final let GENITIVE_POSTPOSITIONS = ["võrra", "ümber", "pealt", "peale", "ringis", "paiku", "aegu", "eest"]
    
    // sõnad, mille korral järgnev arvsõna läheb nimetavasse käändesse (kui oma kääne määramata)
    //private static let NOMINATIVE_PRECEEDING_WORDS = ["kell", "number", "aasta", "kl", "nr", "a"]
    
    private final let ONLY_UPPER_RE = /[A-ZÄÖÜÕŽŠ]+/
    private final let PRONOUNCEABLE_ACRONYMS = ["ABBA", "AIDS", "ALDE", "API", "ARK", "ATKO", "BAFTA", "BENU", "CERN", "CRISPR", "COVID", "DARPA", "EFTA", "EKA", "EKI", "EKRE", "EKSA", "EMO", "EMOR", "ERM", "ERSO", "ESTO", "ETA", "EÜE", "FIDE", "FIFA", "FISA", "GAZ", "GITIS", "IBAN", "IPA", "ISIC", "ISIS", "ISO", "JOKK", "NASA", "NATO", "PERH", "PID", "PIN", "PRIA", "RAF", "RET", "SALT", "SARS", "SETI", "SIG", "SIM", "SMIT", "SORVVO", "TASS", "UNESCO", "VAZ", "VEB", "WADA", "WiFi"]
    
    private final let NO_SPECIAL_SYMBOLS_RE = /([A-ZÄÖÜÕŽŠa-zäöüõšž]+(\.(?!( [A-ZÄÖÜÕŽŠ])))?)|([£$€]?[0-9.,]+[£$€]?)/
    private final let AUDIBLE_SYMBOLS = [
        "@": "ät",
        "$": "dollar",
        "%": "protsent",
        "&": "ja",
        "+": "pluss",
        "=": "võrdub",
        "€": "euro",
        "£": "nael",
        "§": "paragrahv",
        "°": "kraad",
        "±": "pluss miinus",
        "‰": "promill",
        "×": "korda",
        "x": "korda",
        "*": "korda",
        "∙": "korda",
        "/": "jagada",
        "−": "miinus",
        "-": "kuni",
        "–": "kuni"
    ]

    // any symbols still left unreplaced (neutral character namings which may be different from audible_symbols)
    // used on the final text right before output as str.maketrans dictionary, thus the spaces
    /*
    private final let LAST_RESORT = [
         "@": " ätt ",
         "=": " võrdub ",
         "/": " kaldkriips ",
         "(": " sulgudes ",
         "#": " trellid ",
         "*": " tärn ",
         "&": " ampersand ",
         "%": " protsent ",
         "_": " allkriips ",
    ]*/
    
    private final let ABBREVIATIONS = [
        "apr": "aprill",
        "aug": "august",
        "aü": "ametiühing",
        "ca": "tsirka",
        "Ca": "CA",
        "CA": "CA",
        "cl": "sentiliiter",
        "cm": "sentimeeter",
        "dB": "detsibell",
        "dets": "detsember",
        "dl": "detsiliiter",
        "dr": "doktor",
        "e.m.a": "enne meie ajaarvamist",
        "eKr": "enne Kristuse sündi",
        "hj": "hobujõud",
        "hr": "härra",
        "hrl": "harilikult",
        "IK": "isikukood",
        "ingl": "inglise keeles",
        "j.a": "juures asuv",
        "jaan": "jaanuar",
        "jj": "ja järgmine",
        "jm": "ja muud",
        "jms": "ja muud sellised",
        "jmt": "ja mitmed teised",
        "jn": "joonis",
        "jne": "ja nii edasi",
        "jpt": "ja paljud teised",
        "jr": "juunior",
        "Jr": "juunior",
        "jsk": "jaoskond",
        "jt": "ja teised",
        "jun": "juunior",
        "jv": "järv",
        "k.a": "kaasa arvatud",
        "kcal": "kilokalor",
        "kd": "köide",
        "kg": "kilogramm",
        "kk": "keskkool",
        "kl": "kell",
        "klh": "kolhoos",
        "km": "kilomeeter",
        "KM": "KM",
        "km/h": "kilomeetrit tunnis",
        "km²": "ruutkilomeeter",
        "kod": "kodanik",
        "kpl": "kauplus",
        "kr": "kroon",
        "krt": "korter",
        "kt": "kohusetäitja",
        "kv": "kvartal",
        "lg": "lõige",
        "lk": "lehekülg",
        "LK": "looduskaitse",
        "lp": "lugupeetud",
        "LP": "LP",
        "lüh": "lühend",
        "m.a.j": "meie ajaarvamise järgi",
        "m/s": "meetrit sekundis",
        "mbar": "millibaar",
        "mg": "milligramm",
        "mh": "muu hulgas",
        "ml": "milliliiter",
        "mld": "miljard",
        "mln": "miljon",
        "mm": "millimeeter",
        "MM": "MM",
        "mnt": "maantee",
        "m²": "ruutmeeter",
        "m³": "kuupmeeter",
        "Mr": "mister",
        "Ms": "miss",
        "Mrs": "missis",
        "n-ö": "nii-öelda",
        "nim": "nimeline",
        "nn": "niinimetatud",
        "nov": "november",
        "nr": "number",
        "nt": "näiteks",
        "NT": "NT",
        "okt": "oktoober",
        "p.o": "peab olema",
        "pKr": "pärast Kristuse sündi",
        "pa": "poolaasta",
        "pk": "postkast",
        "pms": "peamiselt",
        "pr": "proua",
        "prl": "preili",
        "prof": "professor",
        "ps": "poolsaar",
        "PS": "PS",
        "pst": "puiestee",
        "ptk": "peatükk",
        "raj": "rajoon",
        "rbl": "rubla",
        "reg-nr": "registreerimisnumber",
        "rg-kood": "registrikood",
        "rmtk": "raamatukogu",
        "rmtp": "raamatupidamine",
        "rtj": "raudteejaam",
        "s.a": "sel aastal",
        "s.o": "see on",
        "s.t": "see tähendab",
        "saj": "sajand",
        "sealh": "sealhulgas",
        "seals": "sealsamas",
        "sen": "seenior",
        "sept": "september",
        "sh": "sealhulgas",
        "skp": "selle kuu päeval",
        "SKP": "SKP",
        "sl": "supilusikatäis",
        "sm": "seltsimees",
        "SM": "SM",
        "snd": "sündinud",
        "spl": "supilusikatäis",
        "srn": "surnud",
        "stj": "saatja",
        "surn": "surnud",
        "sü": "säilitusüksus",
        "sünd": "sündinud",
        "tehn": "tehniline",
        "tel": "telefon",
        "tk": "tükk",
        "tl": "teelusikatäis",
        "tlk": "tõlkija",
        "tn": "tänav",
        "tv": "televisioon",
        "u": "umbes",
        "ukj": "uue, Gregoriuse kalendri järgi",
        "v.a": "välja arvatud",
        "veebr": "veebruar",
        "vkj": "vana, Juliuse kalendri järgi",
        "vm": "või muud",
        "vms": "või muud sellist",
        "vrd": "võrdle",
        "vt": "vaata",
        "õa": "õppeaasta",
        "õp": "õpetaja",
        "õpil": "õpilane",
        "V": "volt",
        "Hz": "herts",
        "W": "vatt",
        "kW": "kilovatt",
        "kWh": "kilovatttund",
    ]
    private final let CONTAINS_ROMAN_RE = /^[IVXLCDM]+(-\w+)?$/
    private final let ROMAN_NUMBERS = [
        "I": 1,
        "V": 5,
        "X": 10,
        "L": 50,
        "C": 100,
        "D": 500,
        "M": 1000,
    ]
    private final let ALPHABET: [Character: String] = [
        "A": "aa",
        "B": "bee",
        "C": "tsee",
        "D": "dee",
        "E": "ee",
        "F": "eff",
        "G": "gee",
        "H": "haa",
        "I": "ii",
        "J": "jott",
        "K": "kaa",
        "L": "ell",
        "M": "emm",
        "N": "enn",
        "O": "oo",
        "P": "pee",
        "Q": "kuu",
        "R": "err",
        "S": "ess",
        "Š": "šaa",
        "Z": "zett",
        "Ž": "žee",
        "T": "tee",
        "U": "uu",
        "V": "vee",
        "W": "kaksisvee",
        "Õ": "õõ",
        "Ä": "ää",
        "Ö": "öö",
        "Ü": "üü",
        "X": "iks",
        "Y": "igrek",
    ]
    
    private func convertToUtf8(text: String) -> String {
        return text.cString(using: String.Encoding.utf8)!.description
    }
    
    private func simplifyUnicode(sentence: String) -> String {
        var newSent = sentence
        newSent = newSent.replacingOccurrences(of: "Ð", with: "D")
        newSent = newSent.replacingOccurrences(of: "Þ", with: "Th")
        newSent = newSent.replacingOccurrences(of: "ð", with: "d")
        newSent = newSent.replacingOccurrences(of: "þ", with: "th")
        newSent = newSent.replacingOccurrences(of: "ø", with: "ö")
        newSent = newSent.replacingOccurrences(of: "Ø", with: "Ö")
        newSent = newSent.replacingOccurrences(of: "ß", with: "ss")
        newSent = newSent.replacingOccurrences(of: "ẞ", with: "Ss")
        newSent = newSent.replacingOccurrences(of: "sch", with: "š")
        
        newSent = newSent.replacingOccurrences(of: "S[cC][hH]", with: "Š", options: .regularExpression)
        newSent = newSent.replacingOccurrences(of: "[ĆČ]", with: "Tš", options: .regularExpression)
        newSent = newSent.replacingOccurrences(of: "[ćč]", with: "tš", options: .regularExpression)
        
        //newSent = newSent.decomposedStringWithCanonicalMapping      //NFD
        newSent = newSent.precomposedStringWithCanonicalMapping     //NFC
        //newSent = newSent.decomposedStringWithCompatibilityMapping  //NFKD
        //newSent = newSent.precomposedStringWithCompatibilityMapping
        
        newSent = newSent.replacingOccurrences(of: "\\p{M}", with: "", options: .regularExpression)

        return sentence
    }
    
    private func collapseWhitespace(text: String) -> String {
        return text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
    
    private func subBetween(text: String, label: Regex<(Substring, Substring, Substring)>, target: String) -> String {
        var remainingText = text
        var newText = ""
        while let match = remainingText.firstMatch(of: label) {
            remainingText.replaceSubrange(match.range, with: "\(match.output.0)\(target)\(match.2)")
            //remainingText = remainingText.replacingCharacters(in: match.range, with: "\(match.output.0)\(target)\(match.2)")
            newText += remainingText[..<match.range.upperBound]
            remainingText = String(remainingText[match.range.upperBound...])
        }
        newText += remainingText
        return newText
    }
    
    private func subBetween(text: String, label: Regex<(Substring, Substring)>, target: String) -> String {
        var remainingText = text
        var newText = ""
        while let match = remainingText.firstMatch(of: label) {
            remainingText.replaceSubrange(match.range, with: "\(match.output.0)\(target)\(match.output.1)")
            //remainingText = remainingText.replacingCharacters(in: match.range, with: "\(match.output.0)\(target)\(match.output.1)")
            newText += remainingText[..<match.range.upperBound]
            remainingText = String(remainingText[match.range.upperBound...])
        }
        newText += remainingText
        return newText
    }
    
    private func romanToArabic(word: String) -> String {
        var endingWord: String = ""
        let pattern = /-?[a-z]+$/
        if let match = word.firstMatch(of: pattern) {
            endingWord = " " + (word[match.startIndex] == "-" ? word[match.range].dropFirst(1) : word[match.range])
        }
        if word.wholeMatch(of: /[IXC]{4}/) != nil || word.wholeMatch(of: /[VLD]{2}/) != nil {
            return word
        }
        var newWord = word.replacingOccurrences(of: "IV", with: "IIII")
        newWord = newWord.replacingOccurrences(of: "IX", with: "VIIII")
        newWord = newWord.replacingOccurrences(of: "XL", with: "XXXX")
        newWord = newWord.replacingOccurrences(of: "XC", with: "LXXXX")
        newWord = newWord.replacingOccurrences(of: "CD", with: "CCCC")
        newWord = newWord.replacingOccurrences(of: "CM", with: "DCCC")
        if let _ = newWord.wholeMatch(of: /[IXC]{5}/) {
            return word
        }
        var sum = 0
        var max = 1000
        for char in newWord {
            let i = ROMAN_NUMBERS[String(char)]!
            if i > max {
                return word
            }
            max = i
            sum += i
        }
        return String(sum) + "." + endingWord
    }
    
    private func expandAbbreviations(text: String) -> String {
        var newText = text
        for entry in ABBREVIATIONS {
            newText = newText.replacingOccurrences(of: "\\b\(entry.key)\\.", with: entry.value, options: .regularExpression)
        }
        return newText
    }
    
    private func unifyNumberPunctuation(text: String) -> String {
        if text.contains("\\.") && text.contains(",") || text.filter({ $0 == "," }).count > 1 {
            return text.replacingOccurrences(of: ",", with: "")
        }
        return text
    }
    
    private func expandCurrency(text: String, kaane: Character) -> String {
        var s = text
        s = s.replacingOccurrences(of: ".", with: ",")
        if s.wholeMatch(of: CURRENCY_RE) != nil {
            var curr = "N"
            if text.contains("$") {
                curr = "$"
            } else if text.contains("€") {
                curr = "€"
            } else if text.contains("£") {
                curr = "£"
            }
            var moneys = "0"
            var cents = "0"
            var spelling = ""
            s = s.replacingOccurrences(of: "[£$€]", with: "", options: .regularExpression)
            let parts = s.split(separator: ",")
            if !s.hasPrefix(",") {
                moneys = String(parts[0])
            }
            if !s.hasSuffix(",") && parts.count > 1 {
                cents = String(parts[1])
            }
            if moneys != "0" {
                if kaane == "O" {
                    spelling += String(parts[0]) + CURRENCIES[curr + "g"]!
                } else if moneys == "1" || moneys == "01" {
                    spelling += String(parts[0]) + CURRENCIES[curr + "s"]!
                } else {
                    spelling += String(parts[0]) + CURRENCIES[curr + "m"]!
                }
            }
            if cents != "0" && cents != "00" {
                spelling += " ja "
                if kaane == "O" {
                    spelling += String(parts[0]) + CURRENCIES[curr + "cg"]!
                } else if cents == "1" || cents  == "01" {
                    spelling += String(parts[1]) + CURRENCIES[curr + "cs"]!
                } else {
                    spelling += String(parts[1]) + CURRENCIES[curr + "cm"]!
                }
            }
            if let range = s.range(of: "\\" + s) {
                s = s.replacingCharacters(in: range, with: spelling)
            }
            return s
        }
        return text
    }
    
    private func expandDecimals(text: String) -> String {
        var remainingText = text
        var outText = ""
        while let match = remainingText.firstMatch(of: DECIMALS_RE) {
            outText += remainingText[..<match.range.lowerBound]
            outText += String(remainingText[match.range]).replacingOccurrences(of: "[.,]", with: " koma ", options: .regularExpression)
            remainingText = String(remainingText[match.range.upperBound...])
        }
        outText += remainingText
        return outText
    }
    
    private func expandOrdinals(text: String, kaane: Character) -> String {
        var remainingText = text
        var outText = ""
        while let match = remainingText.firstMatch(of: ORDINAL_RE) {
            outText += remainingText[..<match.range.lowerBound]
            outText += NumberNorm.toOrdinal(n: Int64(match.output.dropLast())!, kaane: kaane)
            remainingText = String(remainingText[match.range.upperBound...])
        }
        outText += remainingText
        return outText
    }
    
    private func expandCardinals(text: String, kaane: Character) -> String {
        var remainingText = text
        var outText = ""
        while let match = remainingText.firstMatch(of: NUMBER_RE) {
            outText += remainingText[..<match.range.lowerBound]
            outText += NumberNorm.numToString(n: Int64(match.output)!, kaane: kaane)
            remainingText = String(remainingText[match.range.upperBound...])
        }
        outText += remainingText
        return outText
    }
    
    private func expandNumbers(text: String, kaane: Character) -> String {
        var parts: [String] = []
        for part in text.split(separator: " ") {
            parts.append(String(part))
        }
        for i in 0..<parts.count {
            parts[i] = unifyNumberPunctuation(text: parts[i])
            parts[i] = expandCurrency(text: parts[i], kaane: kaane)
            parts[i] = expandDecimals(text: parts[i])
            if parts[i].hasSuffix(".") {
                parts[i] = expandOrdinals(text: parts[i], kaane: kaane)
            } else {
                parts[i] = expandCardinals(text: parts[i], kaane: kaane)
            }
        }
        return parts.joined(separator: " ")
    }
    
    private func processByWord(tokens: [String]) -> String {
        var newTextParts: [String] = []
        // process every word separately
        for i in 0..<tokens.count {
            var word = tokens[i]
            var ending = ""
            if String(word.last!) == "," {
                word = String(word.dropLast())
                ending = ","
            }
            // if current token is a symbol
            if word.wholeMatch(of: NO_SPECIAL_SYMBOLS_RE) == nil {
                if AUDIBLE_SYMBOLS.keys.contains(word) {
                    if AUDIBLE_CONNECTING_SYMBOLS.contains(word) && !(i>0 && i<tokens.count-1 && tokens[i-1].wholeMatch(of: DECIMALSCURRENCYNUMBER_RE) != nil && tokens[i+1].wholeMatch(of: DECIMALSCURRENCYNUMBER_RE) != nil) {
                        continue
                    } else {
                        newTextParts.append(AUDIBLE_SYMBOLS[word]! + ending)
                    }
                } else {
                    newTextParts.append(word + ending)
                }
                continue
            }
            // roman numbers to arabic
            if word.wholeMatch(of: CONTAINS_ROMAN_RE) != nil {
                word = romanToArabic(word: word)
                if word.split(separator: " ").count > 1 {
                    newTextParts.append(processByWord(tokens: word.split(separator: " ").map { String($0) }) + ending)
                    continue
                }
            }
            // numbers & currency to words
            if word.wholeMatch(of: DECIMALSCURRENCYNUMBER_RE) != nil {
                var kaane: Character = "N"
                if (i>0 && GENITIVE_PREPOSITIONS.contains(tokens[i-1])) || 
                    (i<tokens.count-1 && GENITIVE_POSTPOSITIONS.contains(tokens[i+1]) ||
                    i<tokens.count-2 && [CURRENCIES["$g"]!, CURRENCIES["€g"]!].contains(" " + tokens[i + 1] + " ") && GENITIVE_POSTPOSITIONS.contains(tokens[i+2])) {
                    kaane = "O"
                } //else if i > 0 && NOMINATIVE_PRECEEDING_WORDS.contains(tokens[i-1]) {
                //    kaane = "N"
                //}
                word = expandNumbers(text: word, kaane: kaane)
            }
            if ABBREVIATIONS.keys.contains(word) {
                word = ABBREVIATIONS[word]!
            } else if word.wholeMatch(of: ONLY_UPPER_RE) != nil {
                if !PRONOUNCEABLE_ACRONYMS.contains(word) {
                    var newWord: [String] = []
                    for char in word {
                        newWord.append(ALPHABET[char]!)
                    }
                    word = newWord.joined(separator: "-")
                }
            }
            newTextParts.append(word + ending)
        }
        return newTextParts.joined(separator: " ")
    }
    
    private func cleanTextForEstonian(text: String) -> String {
        var newText = text

        //Temporarily remove sentence end symbol
        var sentEnd = "."
        var lastChar = newText.last!
        if ".!?".contains(lastChar) {
            sentEnd = String(lastChar)
            newText = String(newText.dropLast())
        }

        // ... between numbers to kuni
        if let match = newText.firstMatch(of: /(\d)\.\.\.(\d)/) {
            newText = String(text[..<match.range.lowerBound])
            newText += match.output.0 + " kuni " + match.output.2
            newText += text[match.range.upperBound...]
        }
        
        // reduce Unicode repertoire _before_ inserting any hyphens
        //newText = convertToUtf8(text: newText)
        newText = simplifyUnicode(sentence: newText)
        
        // add a hyphen between any number-letter sequences  # TODO should not be done in URLs
        newText = subBetween(text: newText, label: /(\d)[A-ZÄÖÜÕŽŠa-zäöüõšž]/, target: "-")
        newText = subBetween(text: newText, label: /[A-ZÄÖÜÕŽŠa-zäöüõšž](\d)/, target: "-")
        
        // remove grouping between numbers
        // keeping space in 2006-10-27 12:48:50, in general require group of 3
        while let match = newText.firstMatch(of: TRINUMBER_RE) {
            newText = newText.replacingOccurrences(of: " ", with: "", range: match.range)
        }
        //newText  = subBetween(text: newText, label: /([0-9]) ([0-9]{3})(?!\d)/, target: "")
        newText = newText.prefix(1).lowercased() + newText.dropFirst()
        
        //Replace dash with comma
        newText = newText.replacingOccurrences(of: " – ", with: ", ")
        //Remove end of quote before comma
        newText = newText.replacingOccurrences(of: ",\"", with: ",")
        
        // split text into words and symbols
        var tokens: [String] = []
        while let match = newText.firstMatch(of: /([A-ZÄÖÜÕŽŠa-zäöüõšž@#0-9.,£$€]+)|\S/) {
            tokens.append(String(newText[match.range]))
            newText = String(newText[match.range.upperBound...])
        }
        newText = processByWord(tokens: tokens)
        newText = newText.lowercased()
        newText += sentEnd
        newText = collapseWhitespace(text: newText)
        newText = expandAbbreviations(text: newText)
        
        NSLog("QQQ text preprocessed: \(newText)")
        return newText
    }

    func processSentence(_ text: String) -> String {
        var remainingText = text
        var sequence: [String] = []
        while remainingText.count > 0 {
            if let match = remainingText.firstMatch(of: CURLY_RE) {
                sequence.append(cleanTextForEstonian(text: String(match.output.0)))
                sequence.append(String(match.output.1))
                remainingText = String(match.output.3)
            } else {
                sequence.append(cleanTextForEstonian(text: remainingText))
                break
            }
        }
        return sequence.joined(separator: " ")
    }
}

class NumberNorm {

    private static let ordinalMap = [
        "null": "nullis",
        "üks": "esimene",
        "kaks": "teine",
        "kolm": "kolmas",
        "neli": "neljas",
        "viis": "viies",
        "kuus": "kuues",
        "seitse": "seitsmes",
        "kaheksa": "kaheksas",
        "üheksa": "üheksas",
        "kümmend": "kümnes",
        //"kümme": "kümnes",
        "teist": "teistkümnes",
        "sada": "sajas",
        "tuhat": "tuhandes",
        "miljon": "miljones",
        "miljard": "miljardes",
        "triljon": "triljones",
        "kvadriljon": "kvadriljones",
        "kvintiljon": "kvintiljones",
        //"sekstiljon": "sekstiljones",
        //"septiljon": "septiljones",
    ]
    private static let genitiveMap = [
        "null": "nulli",
        "üks": "ühe",
        "kaks": "kahe",
        "kolm": "kolme",
        "neli": "nelja",
        "viis": "viie",
        "kuus": "kuue",
        "seitse": "seitsme",
        "kaheksa": "kaheksa",
        "üheksa": "üheksa",
        "kümmend": "kümne",
        //"kümme": "kümne",
        "teist": "teistkümne",
        "sada": "saja",
        "tuhat": "tuhande",
        "miljon": "miljoni",
        "miljard": "miljardi",
        "triljon": "triljoni",
        "kvadriljon": "kvadriljoni",
        "kvintiljon": "kvintiljoni",
        //"sekstiljon": "sekstiljoni",
        //"septiljon": "septiljoni",
    ]
    private static let ordinalGenitiveMap = [
        "null": "nullinda",
        "üks": "esimese",
        "kaks": "teise",
        "kolm": "kolmanda",
        "neli": "neljanda",
        "viis": "viienda",
        "kuus": "kuuenda",
        "seitse": "seitsmenda",
        "kaheksa": "kaheksanda",
        "üheksa": "üheksanda",
        "kümmend": "kümnenda",
        // "kümme": "kümnenda",
        "teist": "teistkümnenda",
        "sada": "sajanda",
        "tuhat": "tuhandenda",
        "miljon": "miljoninda",
        "miljard": "miljardinda",
        "triljon": "triljoninda",
        "kvadriljon": "kvadriljoninda",
        "kvintiljon": "kvintiljoninda",
        //"sekstiljon": "sekstiljoninda",
        //"septiljon": "septiljoninda",
    ]
    private static let CARDINAL_NUMBERS = [
        1: "tuhat",
        2: "miljon",
        3: "miljard",
        4: "triljon",
        5: "kvadriljon",
        6: "kvintiljon",
        //7: "sekstiljon",
        //8: "septiljon",
    ]
    private static let nums = ["null", "üks", "kaks", "kolm", "neli", "viis", "kuus", "seitse", "kaheksa", "üheksa", "kümme"]


    static func toOrdinal(n: Int64, kaane: Character) -> String {
        let spelling: String = numToString(n: n, kaane: "N")
        let split = spelling.split(separator: " ")
        var last: String = String(split.last!)
        if (kaane == "N") {
            for key in ordinalMap.keys {
                if last.hasSuffix(key) {
                    last = last.replacingOccurrences(of: key, with: ordinalMap[key]!)   //näiteks kuus<kümmend> => kuus<kümnes>
                } else {
                    last = last.replacingOccurrences(of: key, with: genitiveMap[key]!) //näiteks <kuus>kümmend => <kuue>kümmend
                }
            }
            last = last.replacingOccurrences(of: "kümme", with: "kümnes")
        } else if (kaane == "O") {
            for key in ordinalGenitiveMap.keys {
                last = last.replacingOccurrences(of: key, with: ordinalGenitiveMap[key]!)
            }
            last = last.replacingOccurrences(of: "kümme", with: "kümnenda")
        }
        if split.count >= 2 {
            var parts: [String] = []
            for i in 0..<split.count-1 {
                parts.append(String(split[i]))
            }
            let text: String = toGenitive(words: parts)
            last = text + " " + last
        }
        return last
    }
    
    static func toGenitive(words: [String]) -> String {
        var newWords: [String] = []
        for word in words {
            if (word.hasSuffix("it")) {
                newWords.append(String(word.dropLast(2)))
            } else {
                newWords.append(word)
            }
        }
        var text: String = newWords.joined(separator: " ")
        for key in genitiveMap.keys {
            text = text.replacingOccurrences(of: key, with: genitiveMap[key]!)
        }
        return text.replacingOccurrences(of: "kümme", with: "kümne")
    }

    static func numToString(n: Int64, kaane: Character) -> String {
        var helperOut: String = numToStringHelper(n: n)
        if (kaane == "O") {
            helperOut = toGenitive(words: helperOut.components(separatedBy: " "))
        }
        if helperOut.count > 4 && !helperOut.starts(with: "üheksa")  {
            return helperOut.replacingOccurrences(of: "^ü((ks)|(he)) ?", with: "", options: .regularExpression)
        }
        return helperOut
    }
    
    private static func numToStringHelper(n: Int64) -> String {
        if ( n < 0 ) {
            return " miinus " + numToStringHelper(n: -n)
        }
        let index: Int = Int(n)
        if n <= 10 {
            return nums[index]
        } else if ( n <= 19 ) {
            return nums[index-10] + "teist"
        } else if ( n <= 99 ) {
            return nums[index/10] + "kümmend" + (n % 10 > 0 ? " " + numToStringHelper(n: n % 10) : "")
        } else if ( n <= 999 ) {
            return nums[index/100] + "sada" + (n % 100 > 0 ? " " + numToStringHelper(n: n % 100) : "")
        }
        var factor: Int = 0
        if ( n <= 999999) {
            factor = 1
        } else if ( n <= 999999999) {
            factor = 2
        } else if ( n <= 999999999999) {
                    factor = 3
        } else if ( n <= 999999999999999) {
            factor = 4
        } else if ( n <= 999999999999999999) {
            factor = 5
        } else {
            factor = 6
        }
        let higherTier = numToStringHelper(n: n / Int64(pow(1000, Double(factor))))
        var lowerTier = ""
        if n % Int64(pow(1000, Double(factor))) > 0 {
            lowerTier = " " + numToStringHelper(n: n % Int64(pow(1000, Double(factor))))
        }
        return higherTier + " " + CARDINAL_NUMBERS[factor]! + (factor != 1 ? "it" : "") + lowerTier
    }
}

