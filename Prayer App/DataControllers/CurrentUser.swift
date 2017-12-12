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
    
    static var profileImage: UIImage?
    static var firstName: String?
    static var lastName: String?
    static var currentUserUID: String?
    
    func currentUserFirstName() -> String {
        var firstName = String()
        let context = CoreDataHelper().getContext()
        let fetchRequest: NSFetchRequest<CurrentUserMO> = CurrentUserMO.fetchRequest()
        do {
            // Peform Fetch Request
            let users = try context.fetch(fetchRequest)
            for user in users {
                if let firstNameCheck = user.firstName {
                    firstName = firstNameCheck
                }
            }
        } catch {
            print("Unable to Fetch users, (\(error))")
        }
        return firstName
    }
    
    func currentUserLastName() -> String {
        var lastName = String()
        let context = CoreDataHelper().getContext()
        let fetchRequest: NSFetchRequest<CurrentUserMO> = CurrentUserMO.fetchRequest()
        do {
            // Peform Fetch Request
            let users = try context.fetch(fetchRequest)
            for user in users {
                if let lastNameCheck = user.lastName {
                    lastName = lastNameCheck
                }
            }
        } catch {
            print("Unable to Fetch users, (\(error))")
        }
        return lastName
    }
    
    func currentUserProfileImage() -> UIImage {
        var image = UIImage()
        let context = CoreDataHelper().getContext()
        let fetchRequest: NSFetchRequest<CurrentUserMO> = CurrentUserMO.fetchRequest()
        do {
            let users = try context.fetch(fetchRequest)
            for user in users {
                if let imageData = user.profileImage as NSData? {
                    if let imageCheck = UIImage(data: imageData as Data) {
                        image = imageCheck
                    }
                }
            }
        } catch {
            print("Unable to Fetch users, (\(error))")
        }
        return image
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
