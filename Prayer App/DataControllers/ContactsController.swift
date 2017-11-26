//
//  ContactsController.swift
//  Prayer App
//
//  Created by Levi on 11/21/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation
import Contacts
import ContactsUI

import Contacts
import ContactsUI


class ContactsHandler: NSObject,CNContactPickerDelegate {
    static let sharedInstance = ContactsHandler()
    
    var contactStore = CNContactStore()
    var parentVC: UIViewController!
    

    
    func hasContactsAccess() -> Bool {
        var accessGranted = false
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        switch authorizationStatus {
        case .authorized:
            accessGranted = true
            print("already has access")
        case .denied, .notDetermined:
            print("has already denied access or is undetermined")
            accessGranted = false
        default:
            print("doesn't have access - hasn't requested access before")
            accessGranted = false
        }
        return accessGranted
    }
    
    func requestAccess(vc: UIViewController) {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        switch authorizationStatus {
        case .authorized:
            print("already has access")
        case .denied, .notDetermined:
            self.contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (access, accessError) -> Void in
                if access {
                    print("access granted")
                    vc.dismiss(animated: false, completion: nil)
                }
                else {
                    if authorizationStatus == CNAuthorizationStatus.denied {
                        let message = "\(accessError!.localizedDescription)\n\nPlease allow the app to access your contacts through the Settings."
                        print(message);
                    }
                }
            })
        default:
            print("default called - doesn't have access and didn't request.")
        }
    }
    
    func launchPickerView(vc: UIViewController) {
        self.parentVC = vc;
        let controller = CNContactPickerViewController()
        controller.delegate = self
        vc.present(controller,animated: true, completion: nil)
    }
    
    func contactPicker(picker: CNContactPickerViewController,
                       didSelectContact contact: CNContact) {
        
        if contact.isKeyAvailable(CNContactPhoneNumbersKey){
            // handle the selected contact
            print("picked a contact")
        }
    }
    
    func contactPickerDidCancel(picker: CNContactPickerViewController) {
        print("Cancelled picking a contact")
    }
    
    func contactPicker(picker: CNContactPickerViewController, didSelectContacts contacts: [CNContact]){
        for contact in contacts {
            if contact.isKeyAvailable(CNContactPhoneNumbersKey){
                // handle contacts here
            }
        }
    }
}
