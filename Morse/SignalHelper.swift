//
//  SignalHelper.swift
//  Morse
//
//  Created by Владимир Молчанов on 18/08/16.
//  Copyright © 2016 Владимир Молчанов. All rights reserved.
//

import Foundation

enum Signal {
    case Dot
    case Dash
    case Gap(GapType)
    
    static func fromDefaults(identifier: String) -> Signal? {
        switch identifier {
        case "Dot":
            return Signal.Dot
        case "Dash":
            return Signal.Dash
        case "GapBetweenMarks":
            return Signal.Gap(.BetweenMarks)
        case "GapBetweenLetters":
            return Signal.Gap(.BetweenLetters)
        case "GapBetweenWords":
            return Signal.Gap(.BetweenWords)
        default: return nil
        }
    }
    
    enum GapType: Float {
        case BetweenMarks = 1.0
        case BetweenLetters = 3.0
        case BetweenWords = 7.0
    }
    
    enum TorchSignal {
        case TorchOn, TorchOff
    }
    
    enum AudioSignal {
        case ShortBeep, LongBeep, Silence
    }
    
    var duration: Float {
        switch self {
        case .Dot: return 1.0
        case .Dash: return 3.0
        case let .Gap(type):
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
                return TorchSignal.TorchOn
            case .AudioSignal:
                return AudioSignal.ShortBeep
            }
        case .Dash:
            switch currentSignalType {
            case .StringSignal:
                return "-"
            case .TorchSignal:
                return TorchSignal.TorchOn
            case .AudioSignal:
                return AudioSignal.LongBeep
            }
        case .Gap:
            switch currentSignalType {
            case .StringSignal:
                return "_"
            case .TorchSignal:
                return TorchSignal.TorchOff
            case .AudioSignal:
                return AudioSignal.Silence
            }
        }
    }
}


enum SignalType {
    case StringSignal
    case TorchSignal
    case AudioSignal
}

var currentSignalType: SignalType = .TorchSignal



enum ITUProsign: String {
    case InvationToTransmit = "-.-"
    case Wait = ".-..."
    case StartingSignal = "-.-.-"
    case EndOfWork = "...-.-"
    case Understood = "...-."
    case Error = "........"
    case Newline = ".-.-"
    
    var genericSignal: [Signal] {
        get {
            var signal: [Signal] = self.rawValue.characters.map { mark in
                switch mark {
                case ".": return Signal.Dot
                case "-": return Signal.Dash
                default: return Signal.Gap(.BetweenMarks)
                }
            }
            signal.addNewElementBetweenElements(newElement: .Gap(.BetweenMarks))
            return signal
        }
    }
}


func getOrCreateITUGenericDictionary() {
    if NSUserDefaults.standardUserDefaults().objectForKey("ITUGenericDict") == nil {
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
            archievableDict.updateValue(mappedCode, forKey: String(char))
        }
        let archive = NSKeyedArchiver.archivedDataWithRootObject(archievableDict)
        NSUserDefaults.standardUserDefaults().setObject(archive, forKey: "ITUGenericDict")
        NSUserDefaults.standardUserDefaults().synchronize()
        print("Generic dict has been saved in NSUserDefaults")
    }
    
    let data = NSUserDefaults.standardUserDefaults().objectForKey("ITUGenericDict")!
    let archievedDict = NSKeyedUnarchiver.unarchiveObjectWithData(data as! NSData) as! [String: [AnyObject]]
    let mappedDict = archievedDict.map({ (key, value) -> (Character, [Signal]) in
        let char = key.characters.first!
        let signals = (value as! [String]).map({ Signal.fromDefaults($0)!})
        return (char, signals)
    })
    ITUGenericDictionary = Dictionary(mappedDict)
    print("GenericDict: \(ITUGenericDictionary.sort { $0.0 < $1.0 })")
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
