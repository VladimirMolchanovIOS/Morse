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
    let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    var torchIsAvailable: Bool {
        get {
            if device.hasTorch && device.torchAvailable && device.isTorchModeSupported(.On) && device.isTorchModeSupported(.Off) {
                return true
            } else {
                return false
            }
        }
    }
    private var _dotLengthInSeconds: NSTimeInterval!
    private var _message: [Signal.TorchSignal]!
    private var _currentSignalIndex = 0
    private var _timer: NSTimer!
    var torchProgressCallback: ((Float, Int) -> Void)!
    var fromTorchSignalToGenericCorrTable: [Int:Int] = [:]
    
    init(dotLengthInSeconds: NSTimeInterval) {
        _dotLengthInSeconds = dotLengthInSeconds
        super.init()
    }
    
    deinit {
        print("TorchController has been deinitialized")
    }
    
    func transmitMessage(message: [Signal], torchProgressCallback: (Float, Int) -> Void ) {
        print("transmitMessage is called")
        _message = transformMessage(message)
        print("_message: \(_message)")
        self.torchProgressCallback = torchProgressCallback
        self.torchProgressCallback(0.0, 0)
        
        dispatch_async(dispatch_get_main_queue()){
            self._timer = NSTimer.scheduledTimerWithTimeInterval(self._dotLengthInSeconds,
                                                                 target: self,
                                                                 selector: #selector(TorchController.manageTorch(_:)),
                                                                 userInfo: self,
                                                                 repeats: true)
        }
    }
    
    func transformMessage(message:[Signal]) -> [Signal.TorchSignal] {
        var output: [Signal.TorchSignal] = []
        currentSignalType = .TorchSignal
        
        var key = 0
        var value = 0
        for signal in message {
            let signalArray = Array<Signal.TorchSignal>(count: Int(round(signal.duration)), repeatedValue: signal.value as! Signal.TorchSignal)
            output.appendContentsOf(signalArray)
            
            for _ in signalArray {
                fromTorchSignalToGenericCorrTable.updateValue(value, forKey: key)
                key += 1
            }
            value += 1
        }
        print(fromTorchSignalToGenericCorrTable.sort { $0.0 < $1.0 })
        return output
    }
    
    func manageTorch(timer: NSTimer) {
        if _message[_currentSignalIndex] == Signal.TorchSignal.TorchOn && device.torchMode == .Off {
            if let _ = try? device.lockForConfiguration() {
                device.torchMode = .On
                device.unlockForConfiguration()
            }
        } else if _message[_currentSignalIndex] == Signal.TorchSignal.TorchOff && device.torchMode == .On {
            if let _ = try? device.lockForConfiguration() {
                device.torchMode = .Off
                device.unlockForConfiguration()
            }
        }
        
        let currentProgress = Float(_currentSignalIndex)/Float(_message.count)
        print("currentProgress: \(currentProgress)")
        print("currentSignalIndex:\(_currentSignalIndex)")
        let userInfo = timer.userInfo as! TorchController
        userInfo.torchProgressCallback(currentProgress, fromTorchSignalToGenericCorrTable[_currentSignalIndex]!)
        if _currentSignalIndex == _message.indices.last! {
            _timer.invalidate()
            userInfo.torchProgressCallback(1.0, fromTorchSignalToGenericCorrTable[_currentSignalIndex]!)
        } else {
            _currentSignalIndex = _currentSignalIndex.successor()
        }
        print("newCurrentSignalIndex:\(_currentSignalIndex)")
    }
    
}
