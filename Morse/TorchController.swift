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
    private var _message: [Int]!
    private var _currentMarkIndex = 0
    private var _timer: NSTimer!
    
    init(dotLengthInSeconds: NSTimeInterval) {
        _dotLengthInSeconds = dotLengthInSeconds
        super.init()
    }
    
    deinit {
        print("TorchController has been deinitialized")
    }
    
    func transmitMessage(message: [Signal]) {
        print("transmitMessage is called")
        _message = transformMessage(message)
        print("_message: \(_message)")
        
        dispatch_async(dispatch_get_main_queue()){
            self._timer = NSTimer.scheduledTimerWithTimeInterval(self._dotLengthInSeconds,
                                                                 target: self,
                                                                 selector: #selector(self.manageTorch),
                                                                 userInfo: nil,
                                                                 repeats: true)
        }
    }
    
    func transformMessage(message:[Signal]) -> [Int] {
        var output = [Int]()
        currentSignalType = .TorchSignal
        for signal in message {
            let signalArray = [Int](count: Int(round(signal.duration)), repeatedValue: signal.value as! Int)
            output.appendContentsOf(signalArray)
        }
        let flattenedOutput = output.flatMap{$0}
        return flattenedOutput
    }
    
    func manageTorch() {
        print("manageTorch is called")
        if _message[_currentMarkIndex] == 1 && device.torchMode == .Off {
//            print("manageTorch: 1st condition")
            if let _ = try? device.lockForConfiguration() {
                device.torchMode = .On
                device.unlockForConfiguration()
            }
        } else if _message[_currentMarkIndex] == 0 && device.torchMode == .On {
//            print("manageTorch: 2nd condition")
            if let _ = try? device.lockForConfiguration() {
                device.torchMode = .Off
                device.unlockForConfiguration()
            }
        }
        if _currentMarkIndex == _message.indices.last! {
//            print("manageTorch: 3rd condition")
            _timer.invalidate()
        } else {
//            print("manageTorch: 4th condition")
            _currentMarkIndex = _currentMarkIndex.successor()
//            print(String(format:"%.2f", NSDate.init(timeIntervalSinceNow: 0.0).timeIntervalSince1970 % floor(NSDate.init(timeIntervalSinceNow: 0.0).timeIntervalSince1970)))
        }
    }
    
}
