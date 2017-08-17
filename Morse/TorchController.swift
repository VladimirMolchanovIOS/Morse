//
//  TorchController.swift
//  Morse
//
//  Created by Владимир Молчанов on 11/08/16.
//  Copyright © 2016 Владимир Молчанов. All rights reserved.
//

import UIKit
import AVFoundation

class TorchController: NSObject {
    let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)!
    var torchIsAvailable: Bool {
        if device.hasTorch && device.isTorchAvailable && device.isTorchModeSupported(.on) && device.isTorchModeSupported(.off) {
            return true
        } else {
            return false
        }
    }
    fileprivate var _dotLengthInSeconds: TimeInterval!
    fileprivate var _message: [Signal.TorchSignal]!
    fileprivate var _currentSignalIndex = 0
    fileprivate var _timer: Timer!
    var torchProgressCallback: ((Float, Int) -> Void)!
    var fromTorchSignalToGenericCorrTable: [Int:Int] = [:]
    
    init(dotLengthInSeconds: TimeInterval) {
        _dotLengthInSeconds = dotLengthInSeconds
        super.init()
    }
    
    deinit {
        print("TorchController has been deinitialized")
    }
    
    func transmitMessage(_ message: [Signal], torchProgressCallback: @escaping (Float, Int) -> Void ) {
        _message = transformMessage(message)
        self.torchProgressCallback = torchProgressCallback
        self.torchProgressCallback(0.0, 0)
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: transmissionWillBeginNotificationKey), object: self, userInfo: nil)
        DispatchQueue.main.async{
            self._timer = Timer.scheduledTimer(timeInterval: self._dotLengthInSeconds,
                                                                 target: self,
                                                                 selector: #selector(TorchController.manageTorch(_:)),
                                                                 userInfo: self,
                                                                 repeats: true)
        }
    }
    
    func transformMessage(_ message: [Signal]) -> [Signal.TorchSignal] {
        var output: [Signal.TorchSignal] = []
        currentSignalType = .torchSignal
        
        var key = 0
        var value = 0
        for signal in message {
            let signalArray = Array<Signal.TorchSignal>(repeating: signal.value as! Signal.TorchSignal, count: Int(round(signal.duration)))
            output.append(contentsOf: signalArray)
            
            for _ in signalArray {
                fromTorchSignalToGenericCorrTable.updateValue(value, forKey: key)
                key += 1
            }
            value += 1
        }
        return output
    }
    
    func manageTorch(_ timer: Timer) {
        if _message[_currentSignalIndex] == Signal.TorchSignal.torchOn && device.torchMode == .off {
            if let _ = try? device.lockForConfiguration() {
                device.torchMode = .on
                device.unlockForConfiguration()
            }
        } else if _message[_currentSignalIndex] == Signal.TorchSignal.torchOff && device.torchMode == .on {
            if let _ = try? device.lockForConfiguration() {
                device.torchMode = .off
                device.unlockForConfiguration()
            }
        }
        
        let currentProgress = Float(_currentSignalIndex)/Float(_message.count)
        let userInfo = timer.userInfo as! TorchController
        userInfo.torchProgressCallback(currentProgress, fromTorchSignalToGenericCorrTable[_currentSignalIndex]!)
        if _currentSignalIndex == _message.indices.last! {
            _timer.invalidate()
            NotificationCenter.default.post(name: Notification.Name(rawValue: transmissionDidFinishNotificationKey), object: self, userInfo: nil)
            userInfo.torchProgressCallback(1.0, fromTorchSignalToGenericCorrTable[_currentSignalIndex]!)
        } else {
            _currentSignalIndex = (_currentSignalIndex + 1)
        }
    }
    
}
