//
//  EditPrayerViewController.swift
//  Prayer App
//
//  Created by Levi on 2/19/18.
//  Copyright © 2018 App Volks. All rights reserved.
//

import UIKit
import Firebase

class EditPrayerViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var topicTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var prayerTextView: UITextView!
    
    @IBOutlet weak var countLabel: UILabel!
    var prayerTopic = String()
    var prayerText = String()
    var prayerID = String()
    var categoryTextfieldCharacterLimit = 24
    var startingCharacterCount = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        topicTextField.delegate = self
        prayerTextView.delegate = self
        
        startingCharacterCount = prayerTopic.count
        self.countLabel.text = String(categoryTextfieldCharacterLimit)
        self.topicTextField.delegate = self
        setInitialCountLabel()
        
        Utilities().setupTextFieldLook(textField: topicTextField)
        topicTextField.text = prayerTopic
        prayerTextView.text = prayerText
    }
    
    @IBAction func saveButtonDidPress(_ sender: Any) {
        print("save pressed")
        if let isConnected = ConnectionTracker.isConnected {
            if isConnected {
                if let textCheck = prayerTextView.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    if textCheck == "" {
                        // present alert
                        Utilities().showAlert(title: "Oops!", message: "No prayer found. Please enter some text and try again.", vc: self)
                    } else {
                        prayerText = textCheck
                        if let topicCheck = topicTextField.text?.trimmingCharacters(in: .whitespaces) {
                            if topicCheck == "" {
                                prayerTopic = "General Prayers"
                            } else {
                                let capitalizedText = topicCheck.capitalized
                                let trimmedText = capitalizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                                prayerTopic = trimmedText
                            }
                            CurrentUserPrayer().savePrayerEdit(prayerText: prayerText, prayerCategory: prayerTopic, prayerID: prayerID)
                            dismiss(animated: true, completion: nil)
                        }
                    }
                }
            } else {
                Utilities().showAlert(title: "No Internet Connection Found", message: "Saving an edit to a Prayer requires an internet connection. Please connect to the internet and try again.", vc: self)
            }
        }
    }
    
    @IBAction func cancelButtonDidPress(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    @objc func keyboardWillShow(notification:NSNotification){
        print("keyboard will show")
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset: UIEdgeInsets = self.scrollView.contentInset
        var textViewInset: UIEdgeInsets = self.prayerTextView.contentInset
        
        contentInset.bottom = keyboardFrame.size.height + 10
        textViewInset.bottom = keyboardFrame.size.height + 10
        
        prayerTextView.contentInset = textViewInset
        scrollView.contentInset = contentInset
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        print("keyboard will hide")
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
    }
    
    func setInitialCountLabel() {
        let initialRemainingCharacters = categoryTextfieldCharacterLimit - startingCharacterCount
        countLabel.text = String(initialRemainingCharacters)
        if initialRemainingCharacters <= 5 {
            self.countLabel.textColor = UIColor.StyleFile.WineColor
            
        } else {
            self.countLabel.textColor = UIColor.gray
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let characterLimit = categoryTextfieldCharacterLimit
        let newLength = (textField.text?.count)! + string.count - range.length
        let charactersLeft = characterLimit - newLength
        
        if newLength <= characterLimit {
            self.countLabel.text = "\(charactersLeft)"
            if charactersLeft <= 5 {
                self.countLabel.textColor = UIColor.StyleFile.WineColor
                
            } else {
                self.countLabel.textColor = UIColor.gray
            }
            return true
        } else {
            return false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
}

