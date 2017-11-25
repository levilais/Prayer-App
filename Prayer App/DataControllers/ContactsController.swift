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

class ContactsHandler: NSObject,CNContactPickerDelegate {
    static let sharedInstance = ContactsHandler()
    
    var contactStore = CNContactStore()
    var parentVC: UIViewController!
    
    func requestForAccess(completionHandler: @escaping (_ accessGranted: Bool) -> Void) {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        
        switch authorizationStatus {
        case .authorized:
            completionHandler(true)
            
        case .denied, .notDetermined:
            self.contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (access, accessError) -> Void in
                if access {
                    completionHandler(access)
                }
                else {
                    if authorizationStatus == CNAuthorizationStatus.denied {
                        let message = "\(accessError!.localizedDescription)\n\nPlease allow the app to access your contacts through the Settings."
                        print(message);
                    }
                }
            })
            
        default:
            completionHandler(false)
        }
    }
}
