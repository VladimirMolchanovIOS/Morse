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
    private var shortBeepAudioPlayer: AVAudioPlayer!
    private var longBeepAudioPlayer: AVAudioPlayer!
    private var _dotLengthInSeconds: NSTimeInterval
    private var _message: [Signal.AudioSignal]!
    private var _currentSignalIndex = 0
    private var _timer: NSTimer!
    var shortBeepSoundName = "censor-beep-01.mp3"
    var longBeepSoundName = "censor-beep-3.mp3"
    var audioProgressCallback: ((Float, Int) -> Void)!
    var fromAudioSignalToGenericCorrTable: [Int:Int] = [:]
    
    init(dotLengthInSeconds: NSTimeInterval) {
        _dotLengthInSeconds = dotLengthInSeconds
        super.init()
        createPlayers()
    }
    
    deinit {
        print("AudioController has been deinitialized")
    }
    
    func transmitMessage(message: [Signal], audioProgressCallback: (Float, Int) -> Void) {
        print("transmitMessage is called")
        _message = transformMessage(message)
        print("_message: \(_message)")
        self.audioProgressCallback = audioProgressCallback
        self.audioProgressCallback(0.0, 0)
        
        NSNotificationCenter.defaultCenter().postNotificationName(transmissionWillBeginNotificationKey, object: self, userInfo: nil)
        dispatch_async(dispatch_get_main_queue()){
            self._timer = NSTimer.scheduledTimerWithTimeInterval(self._dotLengthInSeconds,
                                                                 target: self,
                                                                 selector: #selector(AudioController.manageAudio(_:)),
                                                                 userInfo: self,
                                                                 repeats: true)
        }
    }
    
    func createPlayers() {
        let shortSoundName: String = shortBeepSoundName.componentsSeparatedByString(".").first!
        let shortSoundType: String = shortBeepSoundName.componentsSeparatedByString(".").last!
        
        guard let shortSoundPath = NSBundle.mainBundle().pathForResource(shortSoundName, ofType: shortSoundType) else { return }
        let shortSoundURL = NSURL(fileURLWithPath: shortSoundPath)
        shortBeepAudioPlayer = try! AVAudioPlayer(contentsOfURL: shortSoundURL)
        shortBeepAudioPlayer.enableRate = true
        shortBeepAudioPlayer.rate = Float(shortBeepAudioPlayer.duration/_dotLengthInSeconds)
        
        let longSoundName: String = longBeepSoundName.componentsSeparatedByString(".").first!
        let longSoundType: String = longBeepSoundName.componentsSeparatedByString(".").last!
        
        guard let longSoundPath = NSBundle.mainBundle().pathForResource(longSoundName, ofType: longSoundType) else { return }
        let longSoundURL = NSURL(fileURLWithPath: longSoundPath)
        longBeepAudioPlayer = try! AVAudioPlayer(contentsOfURL: longSoundURL)
        longBeepAudioPlayer.enableRate = true
        longBeepAudioPlayer.rate = Float(longBeepAudioPlayer.duration/(_dotLengthInSeconds*Double(Signal.Dash.duration)))
        
        print("short duration and rate: \((shortBeepAudioPlayer.duration, shortBeepAudioPlayer.rate))\nlong duration and rate: \((longBeepAudioPlayer.duration, longBeepAudioPlayer.rate))")
        
    }
    
    func transformMessage(message: [Signal]) -> [Signal.AudioSignal] {
        var output: [Signal.AudioSignal] = []
        currentSignalType = .AudioSignal
        
        var key = 0
        var value = 0
        for signal in message {
            let signalArray = Array<Signal.AudioSignal>(count: Int(round(signal.duration)), repeatedValue: signal.value as! Signal.AudioSignal)
            output.appendContentsOf(signalArray)
            
            for _ in signalArray {
                fromAudioSignalToGenericCorrTable.updateValue(value, forKey: key)
                key += 1
            }
            value += 1
        }
        print(fromAudioSignalToGenericCorrTable.sort({ $0.0 < $1.0 }))
//        output.append(Signal.Gap(.BetweenMarks).value as! AudioSignal)

        return output
    }
    
    
    func manageAudio(timer: NSTimer) {
        if !shortBeepAudioPlayer.playing && !longBeepAudioPlayer.playing {
            print("---------------------------------------------------------")
            print(_message[_currentSignalIndex])
            switch _message[_currentSignalIndex] {
            case .ShortBeep:
                shortBeepAudioPlayer.play()
            case .LongBeep:
                longBeepAudioPlayer.play()
            case .Silence:
                break
            }
        }
        
        let currentProgress = Float(_currentSignalIndex)/Float(_message.count)
        print("currentProgress: \(currentProgress)")
        print("currentSignalIndex:\(_currentSignalIndex)")
        let userInfo = timer.userInfo as! AudioController
        userInfo.audioProgressCallback(currentProgress, fromAudioSignalToGenericCorrTable[_currentSignalIndex]!)
        if _currentSignalIndex == _message.indices.last! {
            _timer.invalidate()
            NSNotificationCenter.defaultCenter().postNotificationName(transmissionDidFinishNotificationKey, object: self, userInfo: nil)
            userInfo.audioProgressCallback(1.0, fromAudioSignalToGenericCorrTable[_currentSignalIndex]!)
        } else {
            _currentSignalIndex += 1
        }
        print("newCurrentSignalIndex:\(_currentSignalIndex)")
        
    }
    

}
