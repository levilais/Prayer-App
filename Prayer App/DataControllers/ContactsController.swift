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
    static var contactAuthStatusChanged = false
    static var lastContactAuthStatus = ".notDetermined"
    static var currentAuthStatus = String() {
        didSet {
            if ContactsHandler.currentAuthStatus != ContactsHandler.lastContactAuthStatus {
                ContactsHandler.contactAuthStatusChanged = true
                lastContactAuthStatus = currentAuthStatus
                UserDefaultsHelper().saveContactAuthStatus()
                let contactAuthStatusChangedDict:[String: Bool] = ["contactAuthStatusDidChange": ContactsHandler.contactAuthStatusChanged]
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "contactAuthStatusDidChange"), object: nil, userInfo: contactAuthStatusChangedDict)
            }
        }
    }
    
    var contactStore = CNContactStore()
    var parentVC: UIViewController!
    
    func contactsAuthStatus() -> String {
        var authStatus = String()
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        switch authorizationStatus {
        case .authorized:
            authStatus = ".authorized"
            print("already has access")
        case .denied:
            print("status has already been denied")
            authStatus = ".denied"
        case .notDetermined:
            print("status has not been determined")
            authStatus = ".notDetermined"
        case .restricted:
            print("status has been restricted")
            authStatus = ".restricted"
        }
        return authStatus
    }
    
    func requestAccess() {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        switch authorizationStatus {
        case .authorized:
            // this is unlikely to ever be the result
            print("already has access - this shouldn't be called")
        case .notDetermined:
            self.contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (access, accessError) -> Void in
                if access {
                    print("access granted")
                    ContactsHandler.currentAuthStatus = ".authorized"
                } else {
                    if authorizationStatus == CNAuthorizationStatus.denied {
                        ContactsHandler.currentAuthStatus = ".denied"
                    }
                }
            })
        case .denied:
            ContactsHandler.currentAuthStatus = ".denied"
        default:
            print("default called - doesn't have access and didn't request.")
        }
    }
}
