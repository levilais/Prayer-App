//
//  UpdateProfileViewController.swift
//  Prayer App
//
//  Created by Levi on 12/8/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import CoreData
import Photos
import PhotosUI

class UpdateProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var profileImageButton: UIButton!
    @IBOutlet weak var editPhotoButton: UIButton!
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var phoneNumberTextfield: UITextField!
    
    var imagePicker: UIImagePickerController?
    var newImageToSave = UIImage()
    var ref: DatabaseReference!
    var userRef: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker = UIImagePickerController()
        imagePicker!.delegate = self
        imagePicker?.allowsEditing = true
        
        phoneNumberTextfield.delegate = self
        profileImageButton = CurrentUser().setProfileImageButton(button: profileImageButton)

        if let firstName = CurrentUser.currentUser.firstName {
            firstNameTextField.text = firstName
        }
        if let lastName = CurrentUser.currentUser.lastName {
            lastNameTextField.text = lastName
        }
        if let phoneNumber = CurrentUser.currentUser.userPhone {
            phoneNumberTextfield.text = phoneNumber
        }

        ref = Database.database().reference()
        if let userID = Auth.auth().currentUser?.uid {
            userRef = Database.database().reference().child("users").child(userID)
        }
        
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func setupView() {
        Utilities().setupTextFieldLook(textField: firstNameTextField)
        Utilities().setupTextFieldLook(textField: lastNameTextField)
        Utilities().setupTextFieldLook(textField: phoneNumberTextfield)
        profileImageButton.layer.cornerRadius = profileImageButton.frame.size.height / 2
        profileImageButton.clipsToBounds = true
    }
    
    @IBAction func cancelButtonDidPress(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButtonDidPress(_ sender: Any) {
        if let isConnected = ConnectionTracker.isConnected {
            if isConnected {
                saveUpdates()
            } else {
                ConnectionTracker().presentNotConnectedAlert(messageDirections: "Cannot save without an internet connection.  Please re-establish your internet connection and try again.", viewController: self)
            }
        }
    }
    
    @IBAction func editPhotoButtonDidPress(_ sender: Any) {
        checkPermissionsAndLaunchImagePicker()
    }
    
    @IBAction func profileImageButtonDidPress(_ sender: Any) {
        checkPermissionsAndLaunchImagePicker()
    }
    
    func checkPermissionsAndLaunchImagePicker() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized:
            launchPicker()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                if newStatus == PHAuthorizationStatus.authorized {
                    self.launchPicker()
                }
            })
        case .restricted:
            print("User has denied the permission.")
        default:
            print("default was called")
        }
    }
    
    func saveUpdates() {
        if phoneNumberTextfield.text?.count == 0 || phoneNumberTextfield.text?.count == 12 {
            var firstName = String()
            var lastName = String()
            var errorMessage: String?
            
            if let firstNameCheck = firstNameTextField.text {
                if let lastNameCheck = lastNameTextField.text {
                    firstName = firstNameCheck.trimmingCharacters(in: .whitespacesAndNewlines).capitalizingFirstLetter()
                    lastName = lastNameCheck.trimmingCharacters(in: .whitespacesAndNewlines).capitalizingFirstLetter()
                }
            }
            
            if let userID = Auth.auth().currentUser?.uid {
                self.ref.child("users").child(userID).child("firstName").setValue(firstName)
                self.ref.child("users").child(userID).child("lastName").setValue(lastName)
                CurrentUser.currentUser.firstName = firstName
                CurrentUser.currentUser.lastName = lastName
                for member in CurrentUser.firebaseMembershipUsers {
                    if let memberID = member.key {
                        print("member found")
                        self.ref.child("users").child(memberID).child("circleUsers").child(userID).child("firstName").setValue(firstName)
                        self.ref.child("users").child(memberID).child("circleUsers").child(userID).child("lastName").setValue(lastName)
                    }
                }
                
                for circleUser in CurrentUser.firebaseCircleMembers {
                    if let circleUserID = circleUser.key {
                        print("circleUser found")
                        self.ref.child("users").child(circleUserID).child("memberships").child(userID).child("firstName").setValue(firstName)
                        self.ref.child("users").child(circleUserID).child("memberships").child(userID).child("lastName").setValue(lastName)
                    }
                }
                
                
                let imagesFolder = Storage.storage().reference().child("images")
                
                if let imageData = UIImageJPEGRepresentation(newImageToSave, 0.5) {
                    // SAVE TO FIREBASE
                    imagesFolder.child("profileImage\(userID).jpg").putData(imageData, metadata: nil, completion: { (metadata, error) in
                        if let error = error {
                            errorMessage = error.localizedDescription
                        } else {
                            if let downloadURL = metadata?.downloadURL()?.absoluteString {
                                
                                self.ref.child("users").child(userID).child("profileImageURL").setValue(downloadURL)
                                
                                for member in CurrentUser.firebaseMembershipUsers {
                                    if let memberID = member.key {
                                        print("member found")
                                        self.ref.child("users").child(memberID).child("circleUsers").child(userID).child("profileImageURL").setValue(downloadURL)
                                    }
                                }
                                for circleUser in CurrentUser.firebaseCircleMembers {
                                    if let circleUserID = circleUser.key {
                                        print("circleUser found")
                                        self.ref.child("users").child(circleUserID).child("memberships").child(userID).child("profileImageURL").setValue(downloadURL)
                                    }
                                }
                            }
                        }
                    })
                }
            }
            if errorMessage != nil {
                let alert = UIAlertController(title: "Error", message: errorMessage!, preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    alert.dismiss(animated: true, completion: nil)
                })
                alert.addAction(action)
                self.present(alert, animated: true, completion: nil)
                alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
            } else {
                firstNameTextField.resignFirstResponder()
                lastNameTextField.resignFirstResponder()
                self.dismiss(animated: true, completion: nil)
            }
            if phoneNumberTextfield.text?.count == 12 {
                if let number = phoneNumberTextfield.text {
                    self.userRef.child("userPhone").setValue(number)
                    print("saved #")
                }
            } else {
                self.userRef.child("userPhone").removeValue()
            }
        } else {
            presentBadPhoneFormatAlert()
        }
    }
    
    func presentBadPhoneFormatAlert() {
        let alert = UIAlertController(title: "Oops!", message: "If you would like to add a phone number, please make sure that you enter your whole 10-digit number", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == phoneNumberTextfield {
            let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            let components = newString.components(separatedBy: NSCharacterSet.decimalDigits.inverted)
            
            let decimalString = components.joined(separator: "") as NSString
            let length = decimalString.length
            let hasLeadingOne = length > 0 && decimalString.character(at: 0) == (1 as unichar)
            
            if length == 0 || (length > 10 && !hasLeadingOne) || length > 11 {
                let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int
                return (newLength > 10) ? false : true
            }
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if hasLeadingOne {
                formattedString.append("1 ")
                index += 1
            }
            if (length - index) > 3 {
                let areaCode = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", areaCode)
                index += 3
            }
            if length - index > 3 {
                let prefix = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            
            let remainder = decimalString.substring(from: index)
            formattedString.append(remainder)
            textField.text = formattedString as String
            return false
        } else {
            return true
        }
    }
    
    func launchPicker() {
        self.imagePicker?.sourceType = .photoLibrary
        if let picker = self.imagePicker {
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var sourceImage = UIImage()
        if imagePicker!.allowsEditing {
            if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
                sourceImage = image
            }
        } else {
            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                sourceImage = image
            }
        }
        
        profileImageButton.setBackgroundImage(sourceImage, for: .normal)
        newImageToSave = sourceImage
        picker.dismiss(animated: true, completion: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification){
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        var contentInset: UIEdgeInsets = self.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height + 60
        scrollView.contentInset = contentInset
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        scrollView.contentInset = UIEdgeInsets.zero
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
}
