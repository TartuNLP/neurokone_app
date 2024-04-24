//
//  Encoder.swift
//  EestiTts4MacOS
//
//  Created by Rasmus Lellep on 06.03.2024.
//

import Foundation

class Encoder {
    private var SYMBOLS: [String] = ["pad", "-"/**/, " ", "!", "\"", "'"/**/, ",", ".", ":"/**/, ";"/**/, "?", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "š"/**/, "t", "u", "v", "w", "õ"/**/, "ä"/**/, "ö"/**/, "ü"/**/, "x", "y", "z", /*'ä', 'õ', 'ö', 'ü', 'š', */"ž", "eos"]
    
    func splitSents(sents: String) -> [String] {
        return [sents]
    }
    
    func textToIds(text: String) -> [Int] {
        var ids: [Int] = []
        text.forEach { char in
            ids.append(self.SYMBOLS.firstIndex(of: String(char))!)
        }
        return ids
    }
}
