//
//  MorseRepresentation.swift
//  Morse
//
//  Created by Владимир Молчанов on 10/08/16.
//  Copyright © 2016 Владимир Молчанов. All rights reserved.
//

import UIKit

class MorseRepresentation: NSObject {
    
    var originText: String!
    var genericMessage: [Signal]!
    var stringRepresentation: String!
    let dotCharacter = "∙"
    let dashCharacter = "⎯"
    
    var fromGenericToOriginTextCorrTable: [Int:Int] = [:]
    var fromGenericToStringCorrTable: [Int:Int] = [:]
    var letterRangesInMorseString: [NSRange]!
    
// MARK: Initialization
    init(string: String) {
        super.init()
        self.originText = string
        generateStringMessage(fromString: originText)
    }
    
    deinit {
        print("MorseRepresentation has been deinitialized")
    }
    
    func generateGenericMessage(fromString string: String) {
        var message = [Any]()
        //        message.appendContentsOf(ITUProsign.StartingSignal)
        //        message.appendContentsOf(Gap.BetweenWords)
        for characterIndex in string.characters.indices {
            let char = string.uppercased().characters[characterIndex]
            if let morseChar = ITUGenericDictionary[char] {
                message.append(morseChar)
            } else {
                if char == " " {
                    message.append(Signal.gap(.betweenWords))
                } else {
                    print("Invalid character: \(char)")
                    message.append(ITUProsign.Error.genericSignal)
                }
            }
            if characterIndex == string.characters.indices.last! {
                message.append(Signal.gap(.betweenMarks))
            } else if string[string.index(after: characterIndex)] != " " && char != " " {
                message.append(Signal.gap(.betweenLetters))
            }
        }
        
        
        let flattenedMessage = message.reduce([Signal](), { (current, element) -> [Signal] in
            var bufArray: [Signal] = current
            if let arrayElement = element as? [Signal] {
                for el in arrayElement {
                    bufArray.append(el)
                }
            } else {
                let nonArrayElement = element as! Signal
                bufArray.append(nonArrayElement)
            }
            return bufArray
            })
        
        
        self.genericMessage = flattenedMessage
        
        fromGenericToStringCorrTable = [:]
        fromGenericToOriginTextCorrTable = [:]
        letterRangesInMorseString = nil
        generateFromGenericToStringCorrTable()
        generateLetterRangesInMorseString()
        generateFromGenericToOriginTextCorrTable()

    }
    
    func generateFromGenericToStringCorrTable() {
        var key = 0
        var value = 0
        for signal in genericMessage {
            switch signal {
            case .dot, .dash:
                fromGenericToStringCorrTable.updateValue(value, forKey: key)
                key += 1
                value += 1
            case .gap(_):
                let array = [String](repeating: " ", count: Int(round(signal.duration)))
                for _ in array {
                    fromGenericToStringCorrTable.updateValue(value, forKey: key)
                    value += 1
                }
                key += 1
            }
        }
    }
    
    func generateFromGenericToOriginTextCorrTable() {
        var key = 0
        var value = 0
        for signal in genericMessage {
            fromGenericToOriginTextCorrTable.updateValue(value, forKey: key)
            switch signal {
            case .gap(let type):
                switch type {
                case .betweenLetters:
                    key += 1
                    value += 1
                case .betweenWords:
                    key += 1
                    value += 2
                default:
                    key += 1
                }
            default:
                key += 1
            }
        }
        fromGenericToOriginTextCorrTable.updateValue(value + 1, forKey: key - 1)
    }
    
    func generateLetterRangesInMorseString() {
        let stringIndexes = fromGenericToStringCorrTable.values.sorted { $0 < $1 }
        var ranges: [NSRange] = []
        var loc = 0
        var length = 0
        var prev = 0
        for stringIndex in stringIndexes {
            if (stringIndex - prev) == Int(Signal.gap(.betweenLetters).duration) || (stringIndex - prev) == Int(Signal.gap(.betweenWords).duration) || stringIndex == stringIndexes.max() {
                var range: NSRange!
                if loc == 0 {
                    range = NSMakeRange(loc, length)
                } else {
                    range = NSMakeRange(loc+1, length)
                }
                ranges.append(range)
                loc = stringIndex
                length = 0
            } else {
                length += 1
            }
            prev = stringIndex
        }
        letterRangesInMorseString = ranges
        
    }
        
    // If user pastes text
    func generateStringMessage(fromString string: String) {
        var message = ""
        for characterIndex in string.characters.indices {
            let char = string.uppercased().characters[characterIndex]
            if let morseRep = ITUStringDictionary[char] {
                var morseRepWithMarkGaps = ""
                for markIndex in morseRep.characters.indices {
                    let mark = morseRep[markIndex]
                    if (morseRep.startIndex..<morseRep.characters.index(before: morseRep.endIndex)).contains(markIndex) {
                        morseRepWithMarkGaps.append(String(mark) + " ")
                    } else {
                        morseRepWithMarkGaps.append(mark)
                    }
                }
                message.append(morseRepWithMarkGaps)
            } else {
                if char == " " {
                    message.append("       ")
                } else {
                    print("Invalid character: \(char)")
                    message.append("?")
                }
            }
            if characterIndex == string.characters.indices.last! {
                message.append(" ")
            } else if string[string.index(after: characterIndex)] != " " && char != " " {
                message.append("   ")
            }
        }
        
        message = message.replacingOccurrences(of: ".", with: dotCharacter)
        message = message.replacingOccurrences(of: "-", with: dashCharacter)
    
        self.stringRepresentation = message
    }

    func transmit(with signalType: SignalType, progressCallback: @escaping (Float, Int, Int) -> Void) {
        switch signalType {
        case .torchSignal:
            let torchCtrl = TorchController(dotLengthInSeconds: 0.1)
            if torchCtrl.torchIsAvailable {
                torchCtrl.transmitMessage(genericMessage, torchProgressCallback: { progress, currentIndexInGeneric in
                    progressCallback(progress, self.fromGenericToStringCorrTable[currentIndexInGeneric]!, self.fromGenericToOriginTextCorrTable[currentIndexInGeneric]!)
                })
            }
        case .audioSignal:
            let audioCtrl = AudioController(dotLengthInSeconds: 0.125)
            audioCtrl.transmitMessage(genericMessage, audioProgressCallback: { progress, currentIndexInGeneric in
                progressCallback(progress, self.fromGenericToStringCorrTable[currentIndexInGeneric]!, self.fromGenericToOriginTextCorrTable[currentIndexInGeneric]!)
            })
        default:
            break
        }
    }
    
}
