//
//  EditPrayerViewController.swift
//  Prayer App
//
//  Created by Levi on 2/19/18.
//  Copyright © 2018 App Volks. All rights reserved.
//

import UIKit

class EditPrayerViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var topicTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var prayerTextView: UITextView!
    
    var topicText = String()
    var prayerText = String()
    var prayerID = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        topicTextField.delegate = self
        prayerTextView.delegate = self
        
        Utilities().setupTextFieldLook(textField: topicTextField)
        topicTextField.text = topicText
        prayerTextView.text = prayerText
    }
    @IBAction func saveButtonDidPress(_ sender: Any) {
        print("save pressed")
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
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
}

