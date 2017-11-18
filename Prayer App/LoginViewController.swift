//
//  LoginViewController.swift
//  Prayer App
//
//  Created by Levi on 11/17/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var switchToLoginButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var loginSignupButton: UIButton!
    
    var activeField: UITextField?
    var signupShowing = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        Utilities().setupTextFieldLook(textField: emailTextField)
        Utilities().setupTextFieldLook(textField: passwordTextField)
        
        forgotPasswordButton.setTitleColor(UIColor.StyleFile.TealColor, for: .normal)
        switchToLoginButton.setTitleColor(UIColor.StyleFile.TealColor, for: .normal)
    }
    
    @IBAction func switchDidPress(_ sender: Any) {
        toggleLoginSignup()
    }
    
    func toggleLoginSignup() {
        if signupShowing == true {
            signupShowing = false
            explanationLabel.text = "Please enter your login information below"
            titleLabel.text = "Login To Prayer"
            UIView.performWithoutAnimation {
                loginSignupButton.setBackgroundImage(UIImage(named: "logInButton.pdf"), for: .normal)
                switchToLoginButton.setTitle("Or Switch To Signup", for: .normal)
            }
            forgotPasswordButton.isHidden = false
        } else {
            signupShowing = true
            explanationLabel.text = "In order to connect with others, you’ll need to create an account.  At this time, Prayer is an iPhone only application and invitations are sent via iMessage.  To create your account, please enter your information below."
            titleLabel.text = "Create Account"
            UIView.performWithoutAnimation {
                loginSignupButton.setBackgroundImage(UIImage(named: "signUpButton.pdf"), for: .normal)
                switchToLoginButton.setTitle("Or Switch To Login", for: .normal)
            }
            forgotPasswordButton.isHidden = true
        }
    }
    
    @IBAction func maybeLaterDidPress(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func forgotPasswordDidPress(_ sender: Any) {
        print("forgot password pressed")
    }
    
    @IBAction func loginSignupDidPress(_ sender: Any) {
        if signupShowing == true {
            print("sing up pressed")
        } else {
            print("log in pressed")
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification){
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        var contentInset: UIEdgeInsets = self.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height + 90
        scrollView.contentInset = contentInset
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        scrollView.contentInset = UIEdgeInsets.zero
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField){
        activeField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField){
        activeField = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
}
