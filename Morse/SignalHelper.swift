//
//  SignalHelper.swift
//  Morse
//
//  Created by Владимир Молчанов on 18/08/16.
//  Copyright © 2016 Владимир Молчанов. All rights reserved.
//

import Foundation

enum Signal {
    case dot
    case dash
    case gap(GapType)
    
    static func fromDefaults(_ identifier: String) -> Signal? {
        switch identifier {
        case "Dot":
            return Signal.dot
        case "Dash":
            return Signal.dash
        case "GapBetweenMarks":
            return Signal.gap(.betweenMarks)
        case "GapBetweenLetters":
            return Signal.gap(.betweenLetters)
        case "GapBetweenWords":
            return Signal.gap(.betweenWords)
        default: return nil
        }
    }
    
    enum GapType: Float {
        case betweenMarks = 1.0
        case betweenLetters = 3.0
        case betweenWords = 7.0
    }
    
    enum TorchSignal {
        case torchOn, torchOff
    }
    
    enum AudioSignal {
        case shortBeep, longBeep, silence
    }
    
    var duration: Float {
        switch self {
        case .dot: return 1.0
        case .dash: return 3.0
        case let .gap(type):
            return type.rawValue
        }
    }
    
    var value: Any {
        switch self {
        case .dot:
            switch currentSignalType {
            case .stringSignal:
                return "∙"
            case .torchSignal:
                return TorchSignal.torchOn
            case .audioSignal:
                return AudioSignal.shortBeep
            }
        case .dash:
            switch currentSignalType {
            case .stringSignal:
                return "⎯"
            case .torchSignal:
                return TorchSignal.torchOn
            case .audioSignal:
                return AudioSignal.longBeep
            }
        case .gap:
            switch currentSignalType {
            case .stringSignal:
                return " "
            case .torchSignal:
                return TorchSignal.torchOff
            case .audioSignal:
                return AudioSignal.silence
            }
        }
    }
}


enum SignalType {
    case stringSignal
    case torchSignal
    case audioSignal
}

var currentSignalType: SignalType = .torchSignal



enum ITUProsign: String {
    case InvationToTransmit = "-.-"
    case Wait = ".-..."
    case StartingSignal = "-.-.-"
    case EndOfWork = "...-.-"
    case Understood = "...-."
    case Error = "........"
    case Newline = ".-.-"
    
    var genericSignal: [Signal] {
        var signal: [Signal] = self.rawValue.characters.map { mark in
            switch mark {
            case ".": return Signal.dot
            case "-": return Signal.dash
            default: return Signal.gap(.betweenMarks)
            }
        }
        signal.addNewElementBetweenElements(newElement: .gap(.betweenMarks))
        return signal
    }
}


func getOrCreateITUGenericDictionary() {
    if UserDefaults.standard.object(forKey: "ITUGenericDict") == nil {
        var archievableDict: [String : AnyObject] = [:]
        for (char,code) in ITUStringDictionary {
            var mappedCode: [String] = code.characters.map { mark in
                switch mark {
                case ".": return "Dot"
                case "-": return "Dash"
                default: return "GapBetweenMarks"
                }
            }
            mappedCode.addNewElementBetweenElements(newElement: "GapBetweenMarks")
            archievableDict.updateValue(mappedCode as AnyObject, forKey: String(char))
        }
        let archive = NSKeyedArchiver.archivedData(withRootObject: archievableDict)
        UserDefaults.standard.set(archive, forKey: "ITUGenericDict")
        UserDefaults.standard.synchronize()
        print("Generic dict has been saved in NSUserDefaults")
    }
    
    let data = UserDefaults.standard.object(forKey: "ITUGenericDict")!
    let archievedDict = NSKeyedUnarchiver.unarchiveObject(with: data as! Data) as! [String: [AnyObject]]
    let mappedDict = archievedDict.map({ (key, value) -> (Character, [Signal]) in
        let char = key.characters.first!
        let signals = (value as! [String]).map({ Signal.fromDefaults($0)!})
        return (char, signals)
    })
    ITUGenericDictionary = Dictionary(mappedDict)
    print("GenericDict: \(ITUGenericDictionary.sorted { $0.0 < $1.0 })")
}

var ITUGenericDictionary: [Character:[Signal]]!

let ITUStringDictionary: [Character: String] = [
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
