//
//  SelectContactsViewController.swift
//  Prayer App
//
//  Created by Levi on 11/20/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

class SelectContactsViewController: UIViewController {
    
    @IBOutlet weak var contactsNotAllowedView: UIView!
    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if ContactsHandler().hasContactsAccess() {
            contactsNotAllowedView.isHidden = true
            doneButton.isHidden = false
        } else {
            contactsNotAllowedView.isHidden = false
            doneButton.isHidden = true
        }
    }

    func getContactsData() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts, completionHandler: {
            granted, error in
            
            guard granted else {
                // NOTICE: Update the explanation label in this instance with an error telling them to go to Settings to authorize.
                print("didn't have access to contacts")
                return
                //                let alert = UIAlertController(title: "Can't access contacts", message: "Please go to Settings -> MyApp to enable contact permission", preferredStyle: .Alert)
                //                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                //                self.presentViewController(alert, animated: true, completion: nil)
                //                return
            }
            
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey,CNContactEmailAddressesKey,CNContactImageDataKey,CNContactImageDataAvailableKey,CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            var cnContacts = [CNContact]()
            
            do {
                try store.enumerateContacts(with: request){
                    (contact, cursor) -> Void in
                    cnContacts.append(contact)
                }
            } catch let error {
                NSLog("Fetch contact error: \(error)")
            }
            
            NSLog(">>>> Contact list:")
            for contact in cnContacts {
                print(contact)
            }
        })
    }
    
    @IBAction func doneButtonDidPress(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    
    
    @IBAction func connectToContactsDidPress(_ sender: Any) {
        if ContactsHandler().hasContactsAccess() {
            print("access granted")
        } else {
            ContactsHandler().requestAccess(vc: self)
        }
    }
    
    @IBAction func maybeLaterButtonDidPress(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
}
