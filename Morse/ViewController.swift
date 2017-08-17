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
    func textViewDidChange(_ textView: UITextView) {
        if textView.hasText {
            bTransmitWithTorch.isEnabled = true
            bTransmitWithSound.isEnabled = true
            inputTextView.attributedText = NSAttributedString(string: inputTextView.text, attributes: [NSFontAttributeName:UIFont.boldSystemFont(ofSize: 20.0)])
            if morseRepresentation != nil {
                morseStringRepresentationViewLabel.isHidden = true
                morseRepresentation.generateStringMessage(fromString: textView.text)
                morseStringRepresentationTextView.attributedText = NSAttributedString(string: morseRepresentation.stringRepresentation, attributes: [NSFontAttributeName:UIFont.boldSystemFont(ofSize: 20.0)])
            } else {
                morseStringRepresentationViewLabel.isHidden = true
                morseRepresentation = MorseRepresentation(string: textView.text)
                morseStringRepresentationTextView.attributedText = NSAttributedString(string: morseRepresentation.stringRepresentation, attributes: [NSFontAttributeName:UIFont.boldSystemFont(ofSize: 20.0)])
            }
        } else {
            morseStringRepresentationViewLabel.isHidden = false
            morseStringRepresentationTextView.attributedText = NSAttributedString(string: "")
            bTransmitWithTorch.isEnabled = false
            bTransmitWithSound.isEnabled = false
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        progressView.setProgress(0.0, animated: false)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.hasText {
            if morseRepresentation != nil {
                morseRepresentation.generateGenericMessage(fromString: textView.text)
            }
        } else {
            inputViewDescriptionLabel.isHidden = false
            morseRepresentation = nil
        }
        animateInputViewDecrease()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        return true
    }
}

class ViewController: UIViewController {

//MARK: - Constants
    fileprivate let _kGapBetweenKeyboardAndInputView: CGFloat = 10.0
    
//MARK: - UI Variables
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var morseStringRepresentationTextView: UITextView!
    @IBOutlet weak var bTransmitWithTorch: UIButton!
    @IBOutlet weak var bTransmitWithSound: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    fileprivate var inputViewDescriptionLabel: UILabel!
    fileprivate var morseStringRepresentationViewLabel: UILabel!
    
    @IBOutlet weak var inputViewHeightConstraint: NSLayoutConstraint!
    
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(transmissionWillBegin(_:)), name: NSNotification.Name(rawValue: transmissionWillBeginNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(transmissionDidFinish(_:)), name: NSNotification.Name(rawValue: transmissionDidFinishNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustSubviewsForKeyboardNotification(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustSubviewsForKeyboardNotification(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setupDescriptionLabels()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        NotificationCenter.default.removeObserver(self)
    }
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
//MARK: - Setup view
    func setupDescriptionLabels() {
        inputViewDescriptionLabel = UILabel()
        inputViewDescriptionLabel.textColor = UIColor( red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0 )
        inputViewDescriptionLabel.font = UIFont.systemFont(ofSize: 16.0)
        inputViewDescriptionLabel.text = ~"inputview_descriptionLabel_text"
        inputViewDescriptionLabel.textAlignment = .center
        inputViewDescriptionLabel.sizeToFit()
        inputViewDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.addSubview(inputViewDescriptionLabel)
        
        inputViewDescriptionLabel.centerXAnchor.constraint(equalTo: inputTextView.centerXAnchor).isActive = true
        inputViewDescriptionLabel.centerYAnchor.constraint(equalTo: inputTextView.centerYAnchor).isActive = true
        
        
        morseStringRepresentationViewLabel = UILabel()
        morseStringRepresentationViewLabel.textColor = UIColor( red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0 )
        morseStringRepresentationViewLabel.font = UIFont.systemFont(ofSize: 16.0)
        morseStringRepresentationViewLabel.text = ~"morseStringRepresentationView_descriptionLabel_text"
        morseStringRepresentationViewLabel.textAlignment = .center
        morseStringRepresentationViewLabel.sizeToFit()
        morseStringRepresentationViewLabel.translatesAutoresizingMaskIntoConstraints = false
        morseStringRepresentationTextView.addSubview(morseStringRepresentationViewLabel)
        
        morseStringRepresentationViewLabel.centerXAnchor.constraint(equalTo: morseStringRepresentationTextView.centerXAnchor).isActive = true
        morseStringRepresentationViewLabel.centerYAnchor.constraint(equalTo: morseStringRepresentationTextView.centerYAnchor).isActive = true
        
    }

    

//MARK: - IBActions
    @IBAction func transmitWithTorch(_ sender: AnyObject) {
        morseRepresentation.transmit(with: .torchSignal, progressCallback: { (progress: Float, currentIndexInMorseString: Int, currentIndexInOriginText: Int) -> Void in
            self.setTransmitProgress(progress, currentIndexInMorseString: currentIndexInMorseString, currentIndexInOriginText: currentIndexInOriginText)
        })
    }
    
    
    @IBAction func transmitWithSound(_ sender: AnyObject) {
        morseRepresentation.transmit(with: .audioSignal, progressCallback: { (progress: Float, currentIndexInMorseString: Int, currentIndexInOriginText: Int) -> Void in
            self.setTransmitProgress(progress, currentIndexInMorseString: currentIndexInMorseString, currentIndexInOriginText: currentIndexInOriginText)
        })
    }
    
//MARK: - Transmittion progress
    
    func setTransmitProgress(_ progress: Float, currentIndexInMorseString: Int, currentIndexInOriginText: Int) {
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
        let str = NSMutableAttributedString(string: string, attributes: [NSFontAttributeName:UIFont.boldSystemFont(ofSize: 20.0)])
    
        if index < str.string.characters.count {
            str.addAttributes([NSForegroundColorAttributeName:UIColor ( red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0 )], range: NSMakeRange(index, 1))
            if let sRange = range {
                str.addAttribute(NSBackgroundColorAttributeName, value: UIColor.lightGray, range: sRange)
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
        self.inputViewHeightConstraint.constant = newHeight
        UIView.animate(withDuration: 0.5,
                                   delay: 0.0,
                                   usingSpringWithDamping: 0.7,
                                   initialSpringVelocity: 0.5,
                                   options: UIViewAnimationOptions.curveEaseOut,
                                   animations: {
                                    self.view.layoutIfNeeded()
                                    self.inputViewDescriptionLabel.alpha = 0
            },
                                   completion: { finished in
                                    self.inputViewDescriptionLabel.isHidden = true
            }
        )
    }
    
    func animateInputViewDecrease() {
        self.inputViewHeightConstraint.constant = 100.0
        UIView.animate(withDuration: 0.5,
                                   delay: 0.0,
                                   usingSpringWithDamping: 1.0,
                                   initialSpringVelocity: 1.0,
                                   options: UIViewAnimationOptions.curveEaseIn,
                                   animations: {
                                    self.view.layoutIfNeeded()
                                    self.inputViewDescriptionLabel.alpha = 1
            },
                                   completion: nil)
    }
    
    
//MARK: - Other
    func transmissionWillBegin(_ notification: Notification) {
        inputTextView.isEditable = false
        inputTextView.isSelectable = false
        bTransmitWithTorch.isEnabled = false
        bTransmitWithSound.isEnabled = false
    }
    
    func transmissionDidFinish(_ notification: Notification) {
        inputTextView.isEditable = true
        inputTextView.isSelectable = true
        bTransmitWithTorch.isEnabled = true
        bTransmitWithSound.isEnabled = true
    }
    
    func adjustSubviewsForKeyboardNotification(_ notification: Notification) {
        switch notification.name {
        case NSNotification.Name.UIKeyboardWillShow:
            let info = (notification as NSNotification).userInfo!
            let value: AnyObject = info[UIKeyboardFrameEndUserInfoKey]! as AnyObject
            let rawFrame = value.cgRectValue
            let keyboardFrame = view.convert(rawFrame!, from: nil) // Возможно, это лишнее
            let keyboardHeight = keyboardFrame.height
            let newInputViewHeight = view.bounds.height - keyboardHeight - _kGapBetweenKeyboardAndInputView - inputTextView.frame.minY
            if inputViewHeightConstraint.constant != newInputViewHeight {
                animateInputViewIncrease(forNewHeight: newInputViewHeight)
            }
        default:
            break
        }
    }
}

