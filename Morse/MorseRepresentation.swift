//
//  MorseRepresentation.swift
//  Morse
//
//  Created by Владимир Молчанов on 10/08/16.
//  Copyright © 2016 Владимир Молчанов. All rights reserved.
//

import UIKit

enum Signal {
    case Dot
    case Dash
    case Gap(GapType)
    
    var duration: Float {
        switch self {
        case .Dot: return 1.0
        case .Dash: return 3.0
        case .Gap(let type):
            return type.rawValue
        }
    }
    
    var value: Any {
        switch self {
        case .Dot:
            switch currentSignalType {
            case .StringSignal:
                return "."
            case .TorchSignal:
                return 1
            }
        case .Dash:
            switch currentSignalType {
            case .StringSignal:
                return "-"
            case .TorchSignal:
                return 1
            }
        case .Gap:
            switch currentSignalType {
            case .StringSignal:
                return "_"
            case .TorchSignal:
                return 0
            }
        }
    }
}


enum PredefinedSignalType {
    case StringSignal
    case TorchSignal
}

var currentSignalType: PredefinedSignalType = .TorchSignal

enum GapType: Float {
    case BetweenMarks = 1.0
    case BetweenLetters = 3.0
    case BetweenWords = 7.0
}


//enum ITUProsign: String {
//    case InvationToTransmit = "-.-"
//    case Wait = ".-..."
//    case StartingSignal = "-.-.-"
//    case EndOfWork = "...-.-"
//    case Understood = "...-."
//    case Error = "........"
//}

enum ITUProsign {
    case InvitationToTransmit
    case Wait
    case StartingSignal
    case EndOfWork
    case Understood
    case Error
    
    var value: Any {
        switch self {
        case .InvitationToTransmit:
            return addGapsBetweenMarksTo([Signal.Dash, Signal.Dot, Signal.Dash])
        case .Wait:
            return addGapsBetweenMarksTo([Signal.Dot, Signal.Dash, Signal.Dot, Signal.Dot, Signal.Dot])
        case .StartingSignal:
            return addGapsBetweenMarksTo([Signal.Dash, Signal.Dot, Signal.Dash, Signal.Dot, Signal.Dash])
        case .EndOfWork:
            return addGapsBetweenMarksTo([Signal.Dot, Signal.Dot, Signal.Dot, Signal.Dash, Signal.Dot, Signal.Dash])
        case .Understood:
            return addGapsBetweenMarksTo([Signal.Dot, Signal.Dot, Signal.Dot, Signal.Dash, Signal.Dot])
        case .Error:
            return addGapsBetweenMarksTo([Signal.Dot, Signal.Dot, Signal.Dot, Signal.Dot, Signal.Dot, Signal.Dot, Signal.Dot, Signal.Dot])
        }
    }
}

func addGapsBetweenMarksTo(seq: [Signal]) -> [Signal] {
    var output = seq
    var c = 1
    for _ in (seq.startIndex..<seq.endIndex.predecessor()) {
        output.insert(Signal.Gap(.BetweenMarks), atIndex: c)
        c = c + 2
    }
    return output
}

var genericDict = [Character:[Signal]]()

var ITUGenericDictionary: [Character:[Signal]]! {
    get {
        if !genericDict.isEmpty {
            return genericDict
        } else {
            var dict = [Character:[Signal]]()
            for (char,code) in ITUStringDictionary {
                let mappedCode: [Signal] = code.characters.map { mark in
                    switch mark {
                    case ".": return Signal.Dot
                    case "-": return Signal.Dash
                    default: return Signal.Gap(.BetweenMarks)
                    }
                }
                let mappedCodeWithGaps = addGapsBetweenMarksTo(mappedCode)
                dict.updateValue(mappedCodeWithGaps, forKey: char)
            }
            print("GenericDict: \(dict)")
            genericDict = dict
            return genericDict
        }
    }
}

let ITUStringDictionary: [Character:String] = [
    "A":".-",
    "B":"-...",
    "C":"-.-.",
    "D":"-..",
    "E":".",
    "F":"..-.",
    "G":"--.",
    "H":"....",
    "I":"..",
    "J":".---",
    "K":"-.-",
    "L":".-..",
    "M":"--",
    "N":"-.",
    "O":"---",
    "P":".--.",
    "Q":"--.-",
    "R":".-.",
    "S":"...",
    "T":"-",
    "U":"..-",
    "V":"...-",
    "W":".--",
    "X":"-..-",
    "Y":"-.--",
    "Z":"--..",
    "0":"-----",
    "1":".----",
    "2":"..---",
    "3":"...--",
    "4":"....-",
    "5":".....",
    "6":"-....",
    "7":"--...",
    "8":"---..",
    "9":"----.",
    ".":".-.-.-",
    ",":"--..--",
    ":":"---...",
    "?":"..--..",
    "'":".----.",
    "-":"-....-",
    "/":"-..-.",
    "(":"-.--.",
    ")":"-.--.-",
    "=":"-...-",
    "+":".-.-.",
    "@":".--.-."
]

class MorseRepresentation: NSObject {
    
    private var messageForTransmitting: [Signal]!
    private var stringRepresentation: String!
    
// MARK: Initialization
    init(string: String) {
        super.init()
        generateStringMessage(fromString: string)
        generateGenericMessage(fromString: string)
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
                    message.append(ITUProsign.Error)
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
        
        self.messageForTransmitting = flattenedMessage
        print("GenericMessage: \(flattenedMessage)")
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
                        morseRepWithMarkGaps.appendContentsOf(String(mark) + "_")
                    } else {
                        morseRepWithMarkGaps.append(mark)
                    }
                }
                message.appendContentsOf(morseRepWithMarkGaps)
            } else {
                if char == " " {
                    message.appendContentsOf("_______")
                } else {
                    print("Invalid character: \(char)")
                    message.appendContentsOf("?")
                }
            }
            if characterIndex == string.characters.indices.last! {
                message.appendContentsOf("_")
            } else if string[characterIndex.successor()] != " " && char != " " {
                message.appendContentsOf("___")
            }
        }
        print("text: \(string)\nmessage: \(message)")
        self.stringRepresentation = message
    }

    
    func transmitWithTorch() {
        let torchCtrl = TorchController(dotLengthInSeconds: 0.1)
        if torchCtrl.torchIsAvailable {
            torchCtrl.transmitMessage(messageForTransmitting)
        }
    }
    
    func transmitWithVibrations() {
        let vibrCtrl = VibrationsController(dotLengthInSeconds: 0.1)
        vibrCtrl.transmitMessage(stringRepresentation)
    }
}
