//
//  VibrationsController.swift
//  Morse
//
//  Created by Владимир Молчанов on 11/08/16.
//  Copyright © 2016 Владимир Молчанов. All rights reserved.
//

//import UIKit
//import AudioToolbox
//
//class VibrationsController: NSObject {
//
//    private var _dotLengthInSeconds: NSTimeInterval!
//    private var _message: String!
//    private var _currentSignalIndex: String.CharacterView.Index!
//    private var _timer: NSTimer!
//    
//    init(dotLengthInSeconds: NSTimeInterval) {
//        _dotLengthInSeconds = dotLengthInSeconds
//        super.init()
//    }
//    
//    deinit {
//        print("TorchController has been deinitialized")
//    }
//    
//    func transmitMessage(message: String) {
//        print("transmitMessage is called")
//        _message = message.stringByReplacingOccurrencesOfString("-", withString: "...")
//        print("_message: \(_message)")
//        _currentSignalIndex = _message.startIndex
//        
//        dispatch_async(dispatch_get_main_queue()){
//            self._timer = NSTimer.scheduledTimerWithTimeInterval(self._dotLengthInSeconds,
//                                                                 target: self,
//                                                                 selector: #selector(self.manageVibrations),
//                                                                 userInfo: nil,
//                                                                 repeats: true)
//        }
//    }
//    
//    func manageVibrations() {
//        print("manageVibrations is called")
//        if _currentSignalIndex == _message.startIndex {
//            print("manageVibrations: 1st condition")
//            if _message[_currentSignalIndex] == "." {
//                print("manageVibrations: 1st+ condition")
//                AudioServicesPlaySystemSound(1033)
//            }
//        } else {
//            print("manageVibrations: 2nd condition")
//            if _message[_currentSignalIndex] == "." && _message[_currentSignalIndex.predecessor()] != "." {
//                print("manageVibrations: 2nd+ condition")
//                AudioServicesPlaySystemSound(1033)
//            }
//        }
//
//        if _currentSignalIndex == _message.characters.indices.last! {
//            print("manageVibrations: 3rd condition")
//            _timer.invalidate()
//        } else {
//            print("manageVibrations: 4th condition")
//            _currentSignalIndex = _currentSignalIndex.successor()
//            print(String(format:"%.2f", NSDate.init(timeIntervalSinceNow: 0.0).timeIntervalSince1970 % floor(NSDate.init(timeIntervalSinceNow: 0.0).timeIntervalSince1970)))
//        }
//    }
//    
//
//
//}
