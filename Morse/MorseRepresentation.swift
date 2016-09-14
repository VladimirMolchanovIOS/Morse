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
            let char = string.uppercaseString.characters[characterIndex]
            if let morseChar = ITUGenericDictionary[char] {
                message.append(morseChar)
            } else {
                if char == " " {
                    message.append(Signal.Gap(.BetweenWords))
                } else {
                    print("Invalid character: \(char)")
                    message.append(ITUProsign.Error.genericSignal)
                }
            }
            if characterIndex == string.characters.indices.last! {
                message.append(Signal.Gap(.BetweenMarks))
            } else if string[characterIndex.successor()] != " " && char != " " {
                message.append(Signal.Gap(.BetweenLetters))
            }
        }
        
        
        let flattenedMessage = message.reduce([Signal](), combine: { (current, element) -> [Signal] in
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
        print("GenericMessage: \(flattenedMessage)")
        
        fromGenericToStringCorrTable = [:]
        fromGenericToOriginTextCorrTable = [:]
        letterRangesInMorseString = nil
        generateFromGenericToStringCorrTable()
        generateLetterRangesInMorseString()
        generateFromGenericToOriginTextCorrTable()

    }
    
    func generateFromGenericToStringCorrTable() {
        print("generateFromGenericToStringCorrTable()")
        var key = 0
        var value = 0
        for signal in genericMessage {
            switch signal {
            case .Dot, .Dash:
                fromGenericToStringCorrTable.updateValue(value, forKey: key)
                key += 1
                value += 1
            case .Gap(_):
                let array = [String](count: Int(round(signal.duration)), repeatedValue: " ")
                for _ in array {
                    fromGenericToStringCorrTable.updateValue(value, forKey: key)
                    value += 1
                }
                key += 1
            }
        }
        print(fromGenericToStringCorrTable.sort { $0.0 < $1.0 } )
    }
    
    func generateFromGenericToOriginTextCorrTable() {
        print("generateFromGenericToOriginTextCorrTable()")
        var key = 0
        var value = 0
        for signal in genericMessage {
            fromGenericToOriginTextCorrTable.updateValue(value, forKey: key)
            switch signal {
            case .Gap(let type):
                switch type {
                case .BetweenLetters:
                    key += 1
                    value += 1
                case .BetweenWords:
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
        print(fromGenericToOriginTextCorrTable.sort { $0.0 < $1.0 } )
    }
    
    func generateLetterRangesInMorseString() {
        let stringIndexes = fromGenericToStringCorrTable.values.sort { $0 < $1 }
        var ranges: [NSRange] = []
        var loc = 0
        var length = 0
        var prev = 0
        for stringIndex in stringIndexes {
            if (stringIndex - prev) == Int(Signal.Gap(.BetweenLetters).duration) || (stringIndex - prev) == Int(Signal.Gap(.BetweenWords).duration) || stringIndex == stringIndexes.maxElement() {
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
        print("ranges: \(ranges)")
        letterRangesInMorseString = ranges
        
    }
    
    
    func generateStringMessage(fromString string:String) {
        var message = ""
        for characterIndex in string.characters.indices {
            let char = string.uppercaseString.characters[characterIndex]
            if let morseRep = ITUStringDictionary[char] {
                var morseRepWithMarkGaps = ""
                for markIndex in morseRep.characters.indices {
                    let mark = morseRep[markIndex]
                    if (morseRep.startIndex..<morseRep.endIndex.predecessor()).contains(markIndex) {
                        morseRepWithMarkGaps.appendContentsOf(String(mark) + " ")
                    } else {
                        morseRepWithMarkGaps.append(mark)
                    }
                }
                message.appendContentsOf(morseRepWithMarkGaps)
            } else {
                if char == " " {
                    message.appendContentsOf("       ")
                } else {
                    print("Invalid character: \(char)")
                    message.appendContentsOf("?")
                }
            }
            if characterIndex == string.characters.indices.last! {
                message.appendContentsOf(" ")
            } else if string[characterIndex.successor()] != " " && char != " " {
                message.appendContentsOf("   ")
            }
        }
        
        message = message.stringByReplacingOccurrencesOfString(".", withString: dotCharacter)
        message = message.stringByReplacingOccurrencesOfString("-", withString: dashCharacter)
    
        print("text: \(string)\nmessage: \(message)")
        self.stringRepresentation = message
    }

    func transmit(with signalType: SignalType, progressCallback: (Float, Int, Int) -> Void) {
        switch signalType {
        case .TorchSignal:
            let torchCtrl = TorchController(dotLengthInSeconds: 0.1)
            if torchCtrl.torchIsAvailable {
                torchCtrl.transmitMessage(genericMessage, torchProgressCallback: { progress, currentIndexInGeneric in
                    progressCallback(progress, self.fromGenericToStringCorrTable[currentIndexInGeneric]!, self.fromGenericToOriginTextCorrTable[currentIndexInGeneric]!)
                })
            }
        case .AudioSignal:
            let audioCtrl = AudioController(dotLengthInSeconds: 0.125)
            audioCtrl.transmitMessage(genericMessage, audioProgressCallback: { progress, currentIndexInGeneric in
                progressCallback(progress, self.fromGenericToStringCorrTable[currentIndexInGeneric]!, self.fromGenericToOriginTextCorrTable[currentIndexInGeneric]!)
            })
        default:
            break
        }
    }
    
}
