//
//  ViewController.swift
//  Morse
//
//  Created by Владимир Молчанов on 10/08/16.
//  Copyright © 2016 Владимир Молчанов. All rights reserved.
//

import UIKit

//MARK: - TextView delegate
extension ViewController: UITextViewDelegate {
    func textViewDidChange(textView: UITextView) {
        if textView.hasText() {
            bTransmitWithTorch.enabled = true
            bTransmitWithSound.enabled = true
            inputTextView.attributedText = NSAttributedString(string: inputTextView.text, attributes: [NSFontAttributeName:UIFont.boldSystemFontOfSize(20.0)])
            if morseRepresentation != nil {
                morseStringRepresentationViewLabel.hidden = true
                morseRepresentation.generateStringMessage(fromString: textView.text)
                morseStringRepresentationTextView.attributedText = NSAttributedString(string: morseRepresentation.stringRepresentation, attributes: [NSFontAttributeName:UIFont.boldSystemFontOfSize(20.0)])
            } else {
                morseStringRepresentationViewLabel.hidden = true
                morseRepresentation = MorseRepresentation(string: textView.text)
                morseStringRepresentationTextView.attributedText = NSAttributedString(string: morseRepresentation.stringRepresentation, attributes: [NSFontAttributeName:UIFont.boldSystemFontOfSize(20.0)])
            }
        } else {
            morseStringRepresentationViewLabel.hidden = false
            morseStringRepresentationTextView.attributedText = NSAttributedString(string: "")
            bTransmitWithTorch.enabled = false
            bTransmitWithSound.enabled = false
        }
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        progressView.setProgress(0.0, animated: false)
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.hasText() {
            if morseRepresentation != nil {
                morseRepresentation.generateGenericMessage(fromString: textView.text)
            }
        } else {
            inputViewDescriptionLabel.hidden = false
            morseRepresentation = nil
        }
        animateInputViewDecrease()
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}

class ViewController: UIViewController {

//MARK: - Constants
    private let _kGapBetweenKeyboardAndInputView: CGFloat = 10.0
    
//MARK: - UI Variables
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var morseStringRepresentationTextView: UITextView!
    @IBOutlet weak var bTransmitWithTorch: UIButton!
    @IBOutlet weak var bTransmitWithSound: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    private var inputViewDescriptionLabel: UILabel!
    private var morseStringRepresentationViewLabel: UILabel!
    
    @IBOutlet weak var inputViewHeightConstraint: NSLayoutConstraint!
//    private var orientationDidChange: Bool = false
    
    
    var morseRepresentation: MorseRepresentation!

//MARK: - Initialization
    deinit {
        print("ViewController has been deinitialized")
    }

//MARK: - VC life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        inputTextView.layer.cornerRadius = 10.0
        morseStringRepresentationTextView.layer.cornerRadius = 10.0
        bTransmitWithSound.layer.cornerRadius = 5.0
        bTransmitWithSound.titleLabel?.adjustsFontSizeToFitWidth = true
        bTransmitWithTorch.layer.cornerRadius = 5.0
        bTransmitWithTorch.titleLabel?.adjustsFontSizeToFitWidth = true
        
        inputTextView.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(transmissionWillBegin(_:)), name: transmissionWillBeginNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(transmissionDidFinish(_:)), name: transmissionDidFinishNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(adjustSubviewsForKeyboardNotification(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(adjustSubviewsForKeyboardNotification(_:)), name: UIKeyboardWillHideNotification, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(orientationChanged(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        setupDescriptionLabels()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
//MARK: - Setup view
    func setupDescriptionLabels() {
        inputViewDescriptionLabel = UILabel()
        inputViewDescriptionLabel.textColor = UIColor( red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0 )
        inputViewDescriptionLabel.font = UIFont.systemFontOfSize(16.0)
        inputViewDescriptionLabel.text = ~"inputview_descriptionLabel_text"
        inputViewDescriptionLabel.textAlignment = .Center
        inputViewDescriptionLabel.sizeToFit()
        inputViewDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.addSubview(inputViewDescriptionLabel)
        
        inputViewDescriptionLabel.centerXAnchor.constraintEqualToAnchor(inputTextView.centerXAnchor).active = true
        inputViewDescriptionLabel.centerYAnchor.constraintEqualToAnchor(inputTextView.centerYAnchor).active = true
        
        
        morseStringRepresentationViewLabel = UILabel()
        morseStringRepresentationViewLabel.textColor = UIColor( red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0 )
        morseStringRepresentationViewLabel.font = UIFont.systemFontOfSize(16.0)
        morseStringRepresentationViewLabel.text = ~"morseStringRepresentationView_descriptionLabel_text"
        morseStringRepresentationViewLabel.textAlignment = .Center
        morseStringRepresentationViewLabel.sizeToFit()
        morseStringRepresentationViewLabel.translatesAutoresizingMaskIntoConstraints = false
        morseStringRepresentationTextView.addSubview(morseStringRepresentationViewLabel)
        
        morseStringRepresentationViewLabel.centerXAnchor.constraintEqualToAnchor(morseStringRepresentationTextView.centerXAnchor).active = true
        morseStringRepresentationViewLabel.centerYAnchor.constraintEqualToAnchor(morseStringRepresentationTextView.centerYAnchor).active = true
        
    }

    

//MARK: - IBActions
    @IBAction func transmitWithTorch(sender: AnyObject) {
        morseRepresentation.transmit(with: .TorchSignal, progressCallback: { (progress: Float, currentIndexInMorseString: Int, currentIndexInOriginText: Int) -> Void in
            self.setTransmitProgress(progress, currentIndexInMorseString: currentIndexInMorseString, currentIndexInOriginText: currentIndexInOriginText)
        })
    }
    
    
    @IBAction func transmitWithSound(sender: AnyObject) {
        morseRepresentation.transmit(with: .AudioSignal, progressCallback: { (progress: Float, currentIndexInMorseString: Int, currentIndexInOriginText: Int) -> Void in
            self.setTransmitProgress(progress, currentIndexInMorseString: currentIndexInMorseString, currentIndexInOriginText: currentIndexInOriginText)
        })
    }
    
    
    
//    @IBAction func transmitWithVibrations(sender: AnyObject) {
//        morseRepresentation.transmitWithVibrations()
//    }
    
//MARK: - Transmittion progress
    
    func setTransmitProgress(progress: Float, currentIndexInMorseString: Int, currentIndexInOriginText: Int) {
        if progress == 0.0 {
            progressView.setProgress(0.0, animated: false)
        } else {
            progressView.setProgress(progress, animated: true)            
        }
        
        let range = getLetterRange(forCurrentIndexInMorseString: currentIndexInMorseString)
        morseStringRepresentationTextView.attributedText = getStringWithAttributes(atIndex: currentIndexInMorseString, atRange: range, fromString: morseStringRepresentationTextView.text)
        
        inputTextView.attributedText = getStringWithAttributes(atIndex: currentIndexInOriginText, atRange: nil, fromString: inputTextView.text)
    }
    
    func getStringWithAttributes(atIndex index: Int, atRange range: NSRange?, fromString string: String) -> NSMutableAttributedString {
        print("index to color:\(index)")
        print("string length: \(string.characters.count)")
        let str = NSMutableAttributedString(string: string, attributes: [NSFontAttributeName:UIFont.boldSystemFontOfSize(20.0)])
    
        if index < str.string.characters.count {
            str.addAttributes([NSForegroundColorAttributeName:UIColor ( red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0 )], range: NSMakeRange(index, 1))
            if let sRange = range {
                str.addAttribute(NSBackgroundColorAttributeName, value: UIColor.lightGrayColor(), range: sRange)
            }
        }
        
        return str
    }
    
    func getLetterRange(forCurrentIndexInMorseString index: Int) -> NSRange? {
        for range in morseRepresentation.letterRangesInMorseString {
            if NSLocationInRange(index, range) {
                return range
            }
        }
        return nil
    }
    
//MARK: - Animation
    func animateInputViewIncrease(forNewHeight newHeight: CGFloat) {
        print("animateInputViewIncrease(forNewHeight: \(newHeight))")
        self.inputViewHeightConstraint.constant = newHeight
        UIView.animateWithDuration(0.5,
                                   delay: 0.0,
                                   usingSpringWithDamping: 0.7,
                                   initialSpringVelocity: 0.5,
                                   options: UIViewAnimationOptions.CurveEaseOut,
                                   animations: {
                                    self.view.layoutIfNeeded()
                                    self.inputViewDescriptionLabel.alpha = 0
            },
                                   completion: { finished in
                                    self.inputViewDescriptionLabel.hidden = true
            }
        )
    }
    
    func animateInputViewDecrease() {
        print("animateInputViewDecrease()")
        self.inputViewHeightConstraint.constant = 100.0
        UIView.animateWithDuration(0.5,
                                   delay: 0.0,
                                   usingSpringWithDamping: 1.0,
                                   initialSpringVelocity: 1.0,
                                   options: UIViewAnimationOptions.CurveEaseIn,
                                   animations: {
                                    self.view.layoutIfNeeded()
                                    self.inputViewDescriptionLabel.alpha = 1
            },
                                   completion: nil)
    }
    
    
//MARK: - Other
    func injected() {
        print("I've been injected: \(self)")
    }
        
    func transmissionWillBegin(notification: NSNotification) {
        inputTextView.editable = false
        inputTextView.selectable = false
        bTransmitWithTorch.enabled = false
        bTransmitWithSound.enabled = false
    }
    
    func transmissionDidFinish(notification: NSNotification) {
        inputTextView.editable = true
        inputTextView.selectable = true
        bTransmitWithTorch.enabled = true
        bTransmitWithSound.enabled = true
    }
    
    func adjustSubviewsForKeyboardNotification(notification: NSNotification) {
        switch notification.name {
        case UIKeyboardWillShowNotification:
//            print("UIKeyboardWillShowNotification: \n\(notification.userInfo)")
            let info = notification.userInfo!
            let value: AnyObject = info[UIKeyboardFrameEndUserInfoKey]!
            let rawFrame = value.CGRectValue()
            let keyboardFrame = view.convertRect(rawFrame, fromView: nil) // Возможно, это лишнее
            let keyboardHeight = keyboardFrame.height
            let newInputViewHeight = view.bounds.height - keyboardHeight - _kGapBetweenKeyboardAndInputView - inputTextView.frame.minY
            if inputViewHeightConstraint.constant != newInputViewHeight {
                animateInputViewIncrease(forNewHeight: newInputViewHeight)
            }
//        case UIKeyboardWillHideNotification:
////            print("UIKeyboardWillHideNotification: \n\(notification.userInfo)")
//            animateInputViewDecrease()
        default:
            break
        }
    }
    
//    func orientationChanged(notification: NSNotification) {
//        orientationDidChange = true
//    }

}

