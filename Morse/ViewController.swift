//
//  ViewController.swift
//  Morse
//
//  Created by Владимир Молчанов on 10/08/16.
//  Copyright © 2016 Владимир Молчанов. All rights reserved.
//

import UIKit

extension ViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(textField: UITextField) {
        bTransmitWithTorch.enabled = false
        bTransmitWithVibration.enabled = false
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if let editedText = textField.text {
            bTransmitWithTorch.enabled = true
            bTransmitWithVibration.enabled = true
            morseRepresentation = MorseRepresentation(string: editedText)
        }
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var bTransmitWithTorch: UIButton!
    @IBOutlet weak var bTransmitWithVibration: UIButton!
    
    var morseRepresentation: MorseRepresentation!
    
    deinit {
        print("ViewController has been deinitialized")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        textField.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func transmitWithTorch(sender: AnyObject) {
        morseRepresentation.transmitWithTorch()
    }
    
    
    @IBAction func transmitWithVibrations(sender: AnyObject) {
        morseRepresentation.transmitWithVibrations()
    }
    
    
    


}

