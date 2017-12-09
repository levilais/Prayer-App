//
//  UpdateProfileViewController.swift
//  Prayer App
//
//  Created by Levi on 12/8/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import Firebase
import Photos
import PhotosUI

class UpdateProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var profileImageButton: UIButton!
    @IBOutlet weak var editPhotoButton: UIButton!
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var lastNameTextField: UITextField!
    
    var imagePicker: UIImagePickerController?

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker = UIImagePickerController()
        imagePicker!.delegate = self
        imagePicker?.allowsEditing = true
        profileImageButton.setBackgroundImage(UIImage(named: "profilePlaceHolderImageL.pdf"), for:  .normal)
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        profileImageButton.setBackgroundImage(UIImage(named: "profilePlaceHolderImageL.pdf"), for:  .normal)
    }
    
    func setupView() {
        Utilities().setupTextFieldLook(textField: firstNameTextField)
        Utilities().setupTextFieldLook(textField: lastNameTextField)
        profileImageButton.layer.cornerRadius = profileImageButton.frame.size.height / 2
        profileImageButton.clipsToBounds = true
    }
    
    @IBAction func cancelButtonDidPress(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButtonDidPress(_ sender: Any) {
        print("save pressed")
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
        case .authorized: print("Access is granted by user")
            launchPicker()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (newStatus) in print("status is \(newStatus)")
                if newStatus == PHAuthorizationStatus.authorized {
                    /* do stuff here */ print("success")
                    self.launchPicker()
                }
            })
        case .restricted: /* print("User do not have access to photo album.")
        case .denied: */
            print("User has denied the permission.")
        default:
            print("default was called")
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
        print("attempted to set image")
        picker.dismiss(animated: true, completion: nil)
    }
}
