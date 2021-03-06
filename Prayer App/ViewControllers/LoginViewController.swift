//
//  LoginViewController.swift
//  Prayer App
//
//  Created by Levi on 11/17/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FirebaseDatabase
import FirebaseStorage
import Contacts
import ContactsUI
import UserNotifications

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var loginPasswordTextField: UITextField!
    @IBOutlet weak var loginEmailTextField: UITextField!
    @IBOutlet weak var signupEmailTextField: UITextField!
    @IBOutlet weak var signupPasswordTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var signupView: UIView!
    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var switchToLoginButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var scrollView: CustomLoginUIScrollView!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var loginSignupButton: UIButton!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var loginSignupButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginSignupButtonTopContraint2: NSLayoutConstraint!
    
    var activeField: UITextField?
    var signupShowing = Bool()
    var firstLoadSignUp = Bool()
    var ref: DatabaseReference!
    var showingPrivacyFromLogin = false
    
    var firstNameCapitalCheck = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        
        self.hideKeyboardWhenTappedAway()
        setupTextFields()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        forgotPasswordButton.setTitleColor(UIColor.StyleFile.TealColor, for: .normal)
        switchToLoginButton.setTitleColor(UIColor.StyleFile.TealColor, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if Auth.auth().currentUser != nil {
            self.dismiss(animated: false, completion: nil)
        } else {
            showLoginSignup()
            if showingPrivacyFromLogin {
                showingPrivacyFromLogin = false
            }
        }
    }
    
    func setupTextFields() {
        Utilities().setupTextFieldLook(textField: signupEmailTextField)
        signupEmailTextField.autocorrectionType = .no
        signupEmailTextField.delegate = self
        
        Utilities().setupTextFieldLook(textField: signupPasswordTextField)
        signupPasswordTextField.autocorrectionType = .no
        signupPasswordTextField.delegate = self

        Utilities().setupTextFieldLook(textField: loginEmailTextField)
        loginEmailTextField.autocorrectionType = .no
        loginEmailTextField.delegate = self

        Utilities().setupTextFieldLook(textField: loginPasswordTextField)
        loginPasswordTextField.autocorrectionType = .no
        loginPasswordTextField.delegate = self

        Utilities().setupTextFieldLook(textField: confirmPasswordTextField)
        confirmPasswordTextField.autocorrectionType = .no
        confirmPasswordTextField.delegate = self

        Utilities().setupTextFieldLook(textField: firstNameTextField)
        firstNameTextField.autocorrectionType = .no
        firstNameTextField.delegate = self

        Utilities().setupTextFieldLook(textField: lastNameTextField)
        lastNameTextField.autocorrectionType = .no
        lastNameTextField.delegate = self
    }
    
    @IBAction func switchDidPress(_ sender: Any) {
        toggleLoginSignup()
    }
    
    func showLoginSignup() {
        if signupShowing == true {
            showSignUp()
        } else {
            showLogIn()
        }
    }
    @IBAction func showPrivacyDidPress(_ sender: Any) {
        if !signupShowing {
            showingPrivacyFromLogin = true
        }
        performSegue(withIdentifier: "loginToPrivacySegue", sender: self)
    }
    
    func showSignUp() {
        signupView.isHidden = false
        loginView.isHidden = true
        explanationLabel.text = "In order to connect with others, you’ll need to create an account.  At this time, Prayer is an iPhone only application and invitations are sent via iMessage.  To create your account, please enter your information below."
        titleLabel.text = "Create Account"
        UIView.performWithoutAnimation {
            loginSignupButton.setBackgroundImage(UIImage(named: "signUpButton.pdf"), for: .normal)
            switchToLoginButton.setTitle("Switch To Login", for: .normal)
        }
    }
    
    func showLogIn() {
        signupView.isHidden = true
        loginView.isHidden = false
        explanationLabel.text = "Please enter your login information below"
        titleLabel.text = "Login To Prayer"
        
        if !showingPrivacyFromLogin {
            loginSignupButtonTopConstraint.constant -= 123
            loginSignupButtonTopContraint2.constant -= 123
        }

        UIView.performWithoutAnimation {
            loginSignupButton.setBackgroundImage(UIImage(named: "logInButton.pdf"), for: .normal)
            switchToLoginButton.setTitle("Switch To Sign Up", for: .normal)
        }
    }
    
    func toggleLoginSignup() {
        explanationLabel.textColor = UIColor.StyleFile.DarkGrayColor
        
        if signupShowing == true {
            signupPasswordTextField.text = ""
            confirmPasswordTextField.text = ""
            signupEmailTextField.text = ""
            firstNameTextField.text = ""
            lastNameTextField.text = ""
            signupShowing = false
            showLogIn()
        } else {
            loginPasswordTextField.text = ""
            loginEmailTextField.text = ""
            signupShowing = true
            loginSignupButtonTopConstraint.constant += 123
            loginSignupButtonTopContraint2.constant += 123
            showSignUp()
        }
    }
    
    @IBAction func maybeLaterDidPress(_ sender: Any) {
        if firstLoadSignUp == true {
            self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
        } else {
            if self.navigationController != nil {
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }    
    
    @IBAction func forgotPasswordDidPress(_ sender: Any) {
        if let email = loginEmailTextField.text {
            if email != "" {
                if !Utilities().hasEmailFormat(emailString: email) {
                    explanationLabel.text = "Please enter your account's email address so that we can send you password reset instructions"
                    explanationLabel.textColor = UIColor.StyleFile.WineColor
                } else {
                    Auth.auth().sendPasswordReset(withEmail: email, completion: { (error) in
                        if let error = error {
                            self.explanationLabel.text = error.localizedDescription
                            self.explanationLabel.textColor = UIColor.StyleFile.WineColor
                            return
                        }
                        
                        let alert = UIAlertController(title: "Email Sent!", message: "Please check your inbox for password reset instructions.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
                    })
                }
            } else {
                explanationLabel.text = "Please enter your account's email address so that we can send you password reset instructions"
                explanationLabel.textColor = UIColor.StyleFile.WineColor
            }
        }
    }
    
    @IBAction func loginSignupDidPress(_ sender: Any) {
        if signupShowing == true {
            if canAttemptSignup() {
                attemptSignup()
            }
        } else {
            attemptLogin()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        if signupShowing == true {
            if canAttemptSignup() {
                attemptSignup()
            }
        } else {
            attemptLogin()
        }
        return false
    }
    
    func canAttemptSignup() -> Bool {
        var canAttempt = true
        if let firstName = firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if let lastName = lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                if let email = signupEmailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    if let password = signupPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                        if let confirmPassword = confirmPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
                            let textFields = [firstName,lastName,email,password,confirmPassword]
                            var foundBlankTextField = false
                            for textField in textFields {
                                if textField == "" {
                                    foundBlankTextField = true
                                }
                            }
                            
                            var errorMessage = ""
                            var addHashMarkIfNecessary = ""
                            var errorCount = 0
                            var addedFirstItemHash = false
                            
                            if foundBlankTextField == true {
                                errorCount += 1
                                errorMessage += "Please make sure that all fields are complete"
                            }
                            
                            if password.count < 7 {
                                errorCount += 1
                                if errorMessage != "" {
                                    errorMessage += "\n"
                                    if errorCount > 0 {
                                        addHashMarkIfNecessary = "- "
                                        if addedFirstItemHash == false {
                                            errorMessage = "- " + errorMessage
                                            addedFirstItemHash = true
                                        }
                                    }
                                }
                                errorMessage += (addHashMarkIfNecessary + "Password must be at least 8 characters in length")
                                addHashMarkIfNecessary = ""
                            }
                            
                            if password != confirmPassword {
                                errorCount += 1
                                if errorMessage != "" {
                                    errorMessage += "\n"
                                    if errorCount > 0 {
                                        addHashMarkIfNecessary = "- "
                                        if addedFirstItemHash == false {
                                            errorMessage = "- " + errorMessage
                                            addedFirstItemHash = true
                                        }
                                    }
                                }
                                errorMessage += (addHashMarkIfNecessary + "Passwords don't match")
                                confirmPasswordTextField.text = ""
                                signupPasswordTextField.text = ""
                                addHashMarkIfNecessary = ""
                            }

                            if !Utilities().hasEmailFormat(emailString: email) {
                                errorCount += 1
                                if errorMessage != "" {
                                    errorMessage += "\n"
                                    if errorCount > 0 {
                                        addHashMarkIfNecessary = "- "
                                        if addedFirstItemHash == false {
                                            errorMessage = "- " + errorMessage
                                            addedFirstItemHash = true
                                        }
                                    }
                                }
                                errorMessage += (addHashMarkIfNecessary + "Please make sure that you enter a properly formatted email address")
                                addHashMarkIfNecessary = ""
                            }
                            
                            if errorCount > 0 {
                                canAttempt = false
                                explanationLabel.text = errorMessage
                                explanationLabel.textColor = UIColor.StyleFile.WineColor
                            }
                        }
                    }
                }
            }
        }
        return canAttempt
    }
    
    func attemptSignup() {
        var firstName = String()
        var lastName = String()
        let email = Utilities().formattedEmailString(emailTextFieldString: signupEmailTextField.text)
        if let password = signupPasswordTextField.text {
            if let firstNameCheck = firstNameTextField.text {
                if let lastNameCheck = lastNameTextField.text {
                    firstName = firstNameCheck.trimmingCharacters(in: .whitespacesAndNewlines).capitalizingFirstLetter()
                    lastName = lastNameCheck.trimmingCharacters(in: .whitespacesAndNewlines).capitalizingFirstLetter()
                    Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                        if let error = error {
                            self.explanationLabel.text = error.localizedDescription
                            self.explanationLabel.textColor = UIColor.StyleFile.WineColor
                            return
                        } else {
                            if let user = user {
                                Database.database().reference().child("users").child(user.uid).child("userEmail").setValue(email)
                                Database.database().reference().child("users").child(user.uid).child("firstName").setValue(firstName)
                                Database.database().reference().child("users").child(user.uid).child("lastName").setValue(lastName)
                                Database.database().reference().child("users").child(user.uid).child("dateJoinedPrayer").setValue(ServerValue.timestamp())
                                Database.database().reference().child("users").child(user.uid).child("userID").setValue(user.uid)
                                
                                let profileImageData = CurrentUser().profileImageFromNameAsData(firstName: firstName)
                                
                                if let imageToSave = UIImage(data: profileImageData) {
                                    let imagesFolder = Storage.storage().reference().child("images")
                                    if let imageData = UIImageJPEGRepresentation(imageToSave, 0.5) {
                                        imagesFolder.child("profileImage\(user.uid).jpg").putData(imageData, metadata: nil, completion: { (metadata, error) in
                                            if let error = error {
                                                let alert = UIAlertController(title: "Something Went Wrong", message: error.localizedDescription, preferredStyle: .alert)
                                                let action = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                                                    alert.dismiss(animated: true, completion: nil)
                                                })
                                                alert.addAction(action)
                                                self.present(alert, animated: true, completion: nil)
                                                alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
                                                print(error)
                                            } else {
                                                if let downloadURL = metadata?.downloadURL()?.absoluteString {
                                                    self.ref.child("users").child(user.uid).child("profileImageURL").setValue(downloadURL)
                                                }
                                            }
                                        })
                                    }
                                }
                                
                                FirebaseHelper().loadFirebaseData()
                            }
                            
                            if ContactsHandler().contactsAuthStatus() != ".authorized"  {
                                self.promptUserForNotificationAuth()
                                self.performSegue(withIdentifier: "connectToContactsSegue", sender: self)
                            } else {
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    })
                }
            }
        }
    }
    
    func attemptLogin() {
        if let email = loginEmailTextField.text {
            if let password = loginPasswordTextField.text {
                Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                    if let error = error {
                        self.explanationLabel.text = error.localizedDescription
                        self.explanationLabel.textColor = UIColor.StyleFile.WineColor
                        self.loginPasswordTextField.text = ""
                        return
                    }
                    
                    FirebaseHelper().loadFirebaseData()
                    
                    if ContactsHandler().contactsAuthStatus() != ".authorized"  {
                        self.promptUserForNotificationAuth()
                        self.performSegue(withIdentifier: "connectToContactsSegue", sender: self)
                    } else  {
                        self.dismiss(animated: true, completion: nil)
                    }
                })
            }
        }
    }
    
    func promptUserForNotificationAuth() {
        let application: UIApplication = UIApplication.shared
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        application.registerForRemoteNotifications()
        
        if let token = InstanceID.instanceID().token() {
            if let userID = Auth.auth().currentUser?.uid {
                Database.database().reference().child("users").child(userID).child("messagingTokens").child(token).setValue(token)
            }
        }
        
        if let fcmToken = Messaging.messaging().fcmToken {
            if let userID = Auth.auth().currentUser?.uid {
                Database.database().reference().child("users").child(userID).child("messagingTokens").child(fcmToken).setValue(fcmToken)
            }
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
    
    func resetExplanationLabelTextAndColor() {
        explanationLabel.text = "In order to connect with others, you’ll need to create an account.  At this time, Prayer is an iPhone only application and invitations are sent via iMessage.  To create your account, please enter your information below."
        explanationLabel.textColor = UIColor.StyleFile.DarkGrayColor
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
