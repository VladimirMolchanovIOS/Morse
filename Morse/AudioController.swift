//
//  AudioController.swift
//  Morse
//
//  Created by Владимир Молчанов on 19/08/16.
//  Copyright © 2016 Владимир Молчанов. All rights reserved.
//

import Foundation
import AVFoundation

class AudioController: NSObject {
    fileprivate var shortBeepAudioPlayer: AVAudioPlayer!
    fileprivate var longBeepAudioPlayer: AVAudioPlayer!
    fileprivate var _dotLengthInSeconds: TimeInterval
    fileprivate var _message: [Signal.AudioSignal]!
    fileprivate var _currentSignalIndex = 0
    fileprivate var _timer: Timer!
    var shortBeepSoundName = "censor-beep-01.mp3"
    var longBeepSoundName = "censor-beep-3.mp3"
    var audioProgressCallback: ((Float, Int) -> Void)!
    var fromAudioSignalToGenericCorrTable: [Int:Int] = [:]
    
    var time: Date!
    
    init(dotLengthInSeconds: TimeInterval) {
        _dotLengthInSeconds = dotLengthInSeconds
        super.init()
        createPlayers()
    }
    
    deinit {
        print("AudioController has been deinitialized")
    }
    
    func transmitMessage(_ message: [Signal], audioProgressCallback: @escaping (Float, Int) -> Void) {
        _message = transformMessage(message)
        self.audioProgressCallback = audioProgressCallback
        self.audioProgressCallback(0.0, 0)
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: transmissionWillBeginNotificationKey), object: self, userInfo: nil)
        DispatchQueue.main.async{
            self._timer = Timer.scheduledTimer(timeInterval: self._dotLengthInSeconds,
                                                                 target: self,
                                                                 selector: #selector(AudioController.manageAudio(_:)),
                                                                 userInfo: self,
                                                                 repeats: true)
        }
    }
    
    func createPlayers() {
        let shortSoundName: String = shortBeepSoundName.components(separatedBy: ".").first!
        let shortSoundType: String = shortBeepSoundName.components(separatedBy: ".").last!
        
        guard let shortSoundPath = Bundle.main.path(forResource: shortSoundName, ofType: shortSoundType) else { return }
        let shortSoundURL = URL(fileURLWithPath: shortSoundPath)
        shortBeepAudioPlayer = try! AVAudioPlayer(contentsOf: shortSoundURL)
        shortBeepAudioPlayer.enableRate = true
        shortBeepAudioPlayer.rate = Float(shortBeepAudioPlayer.duration/_dotLengthInSeconds)
        
        let longSoundName: String = longBeepSoundName.components(separatedBy: ".").first!
        let longSoundType: String = longBeepSoundName.components(separatedBy: ".").last!
        
        guard let longSoundPath = Bundle.main.path(forResource: longSoundName, ofType: longSoundType) else { return }
        let longSoundURL = URL(fileURLWithPath: longSoundPath)
        longBeepAudioPlayer = try! AVAudioPlayer(contentsOf: longSoundURL)
        longBeepAudioPlayer.enableRate = true
        longBeepAudioPlayer.rate = Float(longBeepAudioPlayer.duration/(_dotLengthInSeconds*Double(Signal.dash.duration)))
    }
    
    func transformMessage(_ message: [Signal]) -> [Signal.AudioSignal] {
        var output: [Signal.AudioSignal] = []
        currentSignalType = .audioSignal
        
        var key = 0
        var value = 0
        for signal in message {
            let signalArray = Array<Signal.AudioSignal>(repeating: signal.value as! Signal.AudioSignal, count: Int(round(signal.duration)))
            output.append(contentsOf: signalArray)
            
            for _ in signalArray {
                fromAudioSignalToGenericCorrTable.updateValue(value, forKey: key)
                key += 1
            }
            value += 1
        }

        return output
    }
    
    
    func manageAudio(_ timer: Timer) {
        if time != nil {
            print("real interval:\(DateInterval.init(start: time, end: Date(timeIntervalSinceNow: 0.0)).duration)")
        }
        time = Date(timeIntervalSinceNow: 0.0)
        if !shortBeepAudioPlayer.isPlaying && !longBeepAudioPlayer.isPlaying {
            
            switch _message[_currentSignalIndex] {
            case .shortBeep:
                shortBeepAudioPlayer.play()
            case .longBeep:
                longBeepAudioPlayer.play()
            case .silence:
                break
            }
        }
        
        let currentProgress = Float(_currentSignalIndex)/Float(_message.count)
        let userInfo = timer.userInfo as! AudioController
        userInfo.audioProgressCallback(currentProgress, fromAudioSignalToGenericCorrTable[_currentSignalIndex]!)
        if _currentSignalIndex == _message.indices.last! {
            _timer.invalidate()
            NotificationCenter.default.post(name: Notification.Name(rawValue: transmissionDidFinishNotificationKey), object: self, userInfo: nil)
            userInfo.audioProgressCallback(1.0, fromAudioSignalToGenericCorrTable[_currentSignalIndex]!)
        } else {
            _currentSignalIndex += 1
        }        
    }
    

}
