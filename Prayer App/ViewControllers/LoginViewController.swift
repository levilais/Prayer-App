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

class LoginViewController: UIViewController {
    
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
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var loginSignupButton: UIButton!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var loginSignupButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var loginSignupButtonTopContraint2: NSLayoutConstraint!
    
    var activeField: UITextField?
    var signupShowing = Bool()
    var firstLoadSignUp = Bool()
    var ref: DatabaseReference!
    
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
        }
    }
    
    func setupTextFields() {
        Utilities().setupTextFieldLook(textField: signupEmailTextField)
        signupEmailTextField.autocorrectionType = .no
        
        Utilities().setupTextFieldLook(textField: signupPasswordTextField)
        signupPasswordTextField.autocorrectionType = .no

        Utilities().setupTextFieldLook(textField: loginEmailTextField)
        loginEmailTextField.autocorrectionType = .no

        Utilities().setupTextFieldLook(textField: loginPasswordTextField)
        loginPasswordTextField.autocorrectionType = .no

        Utilities().setupTextFieldLook(textField: confirmPasswordTextField)
        confirmPasswordTextField.autocorrectionType = .no

        Utilities().setupTextFieldLook(textField: firstNameTextField)
        firstNameTextField.autocorrectionType = .no

        Utilities().setupTextFieldLook(textField: lastNameTextField)
        lastNameTextField.autocorrectionType = .no

    }
    
    @IBAction func switchDidPress(_ sender: Any) {
        toggleLoginSignup()
    }
    
    func showLoginSignup() {
        print("signupshowing: \(signupShowing)")
        if signupShowing == true {
            showSignUp()
        } else {
            showLogIn()
        }
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
        loginSignupButtonTopConstraint.constant -= 123
        loginSignupButtonTopContraint2.constant -= 123
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
                print("attempting pop")
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                print("attempting dismiss")
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func forgotPasswordDidPress(_ sender: Any) {
        print("forgot password pressed")
        if let email = loginEmailTextField.text {
            if email != "" {
                if !Utilities().hasEmailFormat(emailString: email) {
                    explanationLabel.text = "Please enter your account's email address so that we can send you password reset instructions"
                    explanationLabel.textColor = UIColor.StyleFile.WineColor
                } else {
                    Auth.auth().sendPasswordReset(withEmail: email, completion: { (error) in
                        // show alert
                        if let error = error {
                            self.explanationLabel.text = error.localizedDescription
                            self.explanationLabel.textColor = UIColor.StyleFile.WineColor
                            return
                        }
                        
                        let alert = UIAlertController(title: "Email Sent!", message: "Please check your inbox for password reset instructions.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        print("Sent email")
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
        let dateJoined = String(Date().timeIntervalSince1970)
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
                                Database.database().reference().child("users").child(user.uid).child("email").setValue(email)
                                Database.database().reference().child("users").child(user.uid).child("firstName").setValue(firstName)
                                Database.database().reference().child("users").child(user.uid).child("lastName").setValue(lastName)
                                Database.database().reference().child("users").child(user.uid).child("dateJoined").setValue(dateJoined)
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
                                                print(error)
                                            } else {
                                                if let downloadURL = metadata?.downloadURL()?.absoluteString {
                                                    self.ref.child("users").child(user.uid).child("profileImageURL").setValue(downloadURL)
                                                }
                                            }
                                        })
                                    }
                                }
                                
                                // if this works, it means the user doesn't exist.  If this is the case, we need to create another "Current User" and have all data app-wide be whatever Firebase has saved for that new user ID.  CircleUsers, Prayers, and CirclePrayers are all relative to who the logged in uid is.  We don't necessarily want to delete the current user.  Rather - update how we fetch data everywhere we call on the database.  THis exact process is also what needs to be done when loggin in.
                                
                                // there is now a property that is "isLoggedInAsCurrentUser".  Do a for loop and change all uid's that dont' match this uid to "false" - and this one to "true".  Then, when fetching info, make sure that there is a predicate that calls for only objects where "isCurrentUser" is true
                                
                                if CurrentUser().currentUserExists() {
                                    // remove all Core Data from the previous user and replace it with this new user on the device.  Likely need to remove Prayers from previous user, too.  Need to do this on login, too.  Core Data should be relevant to signed-in UID.
                                    CurrentUser().deleteCurrentUser()
                                    self.saveUserToCoreData(firstName: firstName, lastName: lastName, dateJoined: dateJoined, profileImageData: profileImageData, uid: user.uid)
                                } else {
                                    self.saveUserToCoreData(firstName: firstName, lastName: lastName, dateJoined: dateJoined, profileImageData: profileImageData, uid: user.uid)
                                }
                            }
                            
                            if ContactsHandler().contactsAuthStatus() != ".authorized"  {
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
    
    func saveUserToCoreData(firstName: String, lastName: String, dateJoined: String, profileImageData: Data, uid: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        if let entity = NSEntityDescription.entity(forEntityName: "CurrentUserMO", in: managedContext) {
            let currentUser = NSManagedObject(entity: entity, insertInto: managedContext)
            
            currentUser.setValue(firstName, forKey: "firstName")
            currentUser.setValue(lastName, forKey: "lastName")
            currentUser.setValue(dateJoined, forKey: "dateJoinedPrayer")
            currentUser.setValue(profileImageData, forKey: "profileImage")
            currentUser.setValue(uid, forKey: "uid")
            currentUser.setValue(true, forKey: "isLoggedInAsCurrentUser")
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
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
                    print("signed in")
                    // Check if UID matches saved UID in Core Data.
                    // If yes, proceed by adding any new data
                    // If no, remove all Core Data and replace with Firebase data
                    
                    if ContactsHandler().contactsAuthStatus() != ".authorized"  {
                        self.performSegue(withIdentifier: "connectToContactsSegue", sender: self)
                    } else  {
                        self.dismiss(animated: true, completion: nil)
                    }
                })
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
