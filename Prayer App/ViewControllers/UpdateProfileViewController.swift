//
//  UpdateProfileViewController.swift
//  Prayer App
//
//  Created by Levi on 12/8/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import Firebase

class UpdateProfileViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var profileImageButton: UIButton!
    @IBOutlet weak var editPhotoButton: UIButton!
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var lastNameTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        profileImageButton.setBackgroundImage(UIImage(named: "profilePlaceHolderImageL.pdf"), for:  .normal)
    }
    
    func setupView() {
        Utilities().setupTextFieldLook(textField: firstNameTextField)
        Utilities().setupTextFieldLook(textField: lastNameTextField)
        editPhotoButton.layer.cornerRadius = editPhotoButton.frame.size.height / 2
        editPhotoButton.clipsToBounds = true
    }
    
    @IBAction func cancelButtonDidPress(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButtonDidPress(_ sender: Any) {
        print("save pressed")
    }
    
    @IBAction func editPhotoButtonDidPress(_ sender: Any) {
    }
    
    @IBAction func profileImageButtonDidPress(_ sender: Any) {
    }
    
}
