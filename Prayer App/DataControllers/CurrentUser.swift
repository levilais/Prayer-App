//
//  CurrentUser.swift
//  Prayer App
//
//  Created by Levi on 11/25/17.
//  Copyright © 2017 App Volks. All rights reserved.
//


import Foundation
import Firebase
import FirebaseStorage
import UIKit
import CoreData

class CurrentUser {
    static var isLoggedIn: Bool?
    static var hasAllowedContactAccess = false
    static var circleMembers = [CircleUser]()
    static var firebaseCircleMembers = [CircleUser]()
    static var profileImage: UIImage?
    static var firstName: String?
    static var lastName: String?
    static var currentUserUID: String?
    
    
    func setupCurrentUserFirstNameTextfield(textField: UITextField) -> UITextField {
        if Auth.auth().currentUser != nil {
            if let userID = Auth.auth().currentUser?.uid {
                Database.database().reference().child("users").child(userID).observe(.value) { (snapshot) in
                    if let userDictionary = snapshot.value as? NSDictionary {
                        if let firstName = userDictionary["firstName"] as? String {
                            textField.text = firstName
                        }
                    }
                }
            }
        }
        return textField
    }
    
    func setupCurrentUserFirstNameWelcomeLabel(label: UILabel) -> UILabel {
        if Auth.auth().currentUser != nil {
            if let userID = Auth.auth().currentUser?.uid {
                Database.database().reference().child("users").child(userID).observe(.value) { (snapshot) in
                    if let userDictionary = snapshot.value as? NSDictionary {
                        if let firstName = userDictionary["firstName"] as? String {
                            label.text =  "Good afternoon, \(firstName)"
                        }
                    }
                }
            }
        }
        return label
    }
    
    func setupCurrentUserLastNameTextfield(textField: UITextField) -> UITextField {
        if Auth.auth().currentUser != nil {
            if let userID = Auth.auth().currentUser?.uid {
                Database.database().reference().child("users").child(userID).observe(.value) { (snapshot) in
                    if let userDictionary = snapshot.value as? NSDictionary {
                        if let lastName = userDictionary["lastName"] as? String {
                            textField.text = lastName
                        }
                    }
                }
            }
        }
        return textField
    }
    
    func setProfileImageButton(button: UIButton) -> UIButton {
        if Auth.auth().currentUser != nil {
            if let userID = Auth.auth().currentUser?.uid {
                Database.database().reference().child("users").child(userID).observe(.value) { (snapshot) in
                    if let userDictionary = snapshot.value as? NSDictionary {
                        if let imageURLString = userDictionary["profileImageURL"] as? String {
                            if let url = URL(string: imageURLString) {
                                button.sd_setBackgroundImage(with: url, for: .normal, completed: { (image, error, cacheType, imageURL) in
                                })
                            }
                        }
                    }
                }
            }
        }
        return button
    }
    
    func currentUserExists() -> Bool {
        var userExists = Bool()
        let context = CoreDataHelper().getContext()
        let fetchRequest: NSFetchRequest<CurrentUserMO> = CurrentUserMO.fetchRequest()
        do {
            // Peform Fetch Request
            let users = try context.fetch(fetchRequest)
            for user in users {
                userExists = user.isLoggedInAsCurrentUser
            }
        } catch {
            print("Unable to Fetch users, (\(error))")
        }
        return userExists
    }
    
    func deleteCurrentUser() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "CurrentUserMO")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print ("There was an error")
        }
    }
    
    // HELPER METHOD FOR SETTING INITIAL PROFILE IMAGE
    func profileImageFromNameAsData(firstName: String) -> Data {
        var imageDataToSave = Data()
        let firstLetter = String(describing: firstName.first!)
        print(firstLetter)
        let uppercasedFirstLetter = firstLetter.uppercased()
        let imageNameString = "profilePlaceHolderImage" + uppercasedFirstLetter + ".pdf"
        print(imageNameString)
        if let image = UIImage(named: imageNameString) {
            if let imageData = UIImagePNGRepresentation(image) {
                imageDataToSave = imageData
            }
        }
        return imageDataToSave
    }
}
