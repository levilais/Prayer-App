//
//  LoginViewController.swift
//  Prayer App
//
//  Created by Levi on 11/17/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var switchToLoginButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var loginSignupButton: UIButton!
    @IBOutlet weak var confirmPasswordBackgroundButton: UIButton!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var confirmPasswordSubview: UIView!
    @IBOutlet weak var confirmPasswordView: UIView!
    
    var activeField: UITextField?
    var signupShowing = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAway()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        Utilities().setupTextFieldLook(textField: emailTextField)
        Utilities().setupTextFieldLook(textField: passwordTextField)
        Utilities().setupTextFieldLook(textField: confirmPasswordTextField)
        
        forgotPasswordButton.setTitleColor(UIColor.StyleFile.TealColor, for: .normal)
        switchToLoginButton.setTitleColor(UIColor.StyleFile.TealColor, for: .normal)
        
        emailTextField.autocorrectionType = .no
    }
    
    @IBAction func switchDidPress(_ sender: Any) {
        toggleLoginSignup()
    }
    
    func toggleLoginSignup() {
        emailTextField.text = ""
        passwordTextField.text = ""
        explanationLabel.textColor = UIColor.StyleFile.DarkGrayColor
        
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
            attemptSignup()
        } else {
            print("log in pressed")
            attemptLogin()
        }
    }
    
    func attemptSignup() {
        let email = Utilities().formattedEmailString(emailTextFieldString: emailTextField.text)
        if let passwordCheck = passwordTextField.text {
            if passwordCheck.count < 6 {
                self.explanationLabel.textColor = UIColor.StyleFile.WineColor
                self.explanationLabel.text = "Please enter a valid email and make sure that your password is more than 5 characters in length."
                self.passwordTextField.text = ""
            } else {
                Animations().animateCustomAlertPopup(view: confirmPasswordView, backgroundButton: confirmPasswordBackgroundButton, subView: confirmPasswordSubview, viewController: self, textField: confirmPasswordTextField, textView: UITextView())
                if let password = confirmPasswordTextField.text {
                    if password == passwordCheck {
                        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                            if let error = error {
                                self.explanationLabel.text = error.localizedDescription
                                self.explanationLabel.textColor = UIColor.StyleFile.WineColor
                                return
                            }
                            print("signed in")
                            // NOTICE: Right now we're dismissing the view controller.  In the future, we will navigate to Circle user flow (adding contacts, etc)
                            self.dismiss(animated: true, completion: nil)
                        })
                    }
                } else {
                    self.passwordTextField.text = ""
                    self.explanationLabel.text = "The passwords that you entered were not the same.  Please enter a password below and try again."
                    self.explanationLabel.textColor = UIColor.StyleFile.WineColor
                }
            }
        }
    }
    
    func attemptLogin() {
        let email = Utilities().formattedEmailString(emailTextFieldString: emailTextField.text)
        if let password = passwordTextField.text {
            Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                if let error = error {
                    self.explanationLabel.text = error.localizedDescription
                    self.explanationLabel.textColor = UIColor.StyleFile.WineColor
                    self.passwordTextField.text = ""
                    return
                }
                print("signed in")
                // NOTE: Right now we're just returning - but in the future, we'll check to see if the user has added access to Contacts yet.
                self.dismiss(animated: true, completion: nil)
            })
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
    
    @IBAction func confirmPasswordDidPress(_ sender: Any) {
    }
    @IBAction func cancelConfirmPasswordDidPress(_ sender: Any) {
        
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
