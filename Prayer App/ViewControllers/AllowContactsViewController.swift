//
//  AllowContactsViewController.swift
//  Prayer App
//
//  Created by Levi on 11/20/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

class AllowContactsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    @IBAction func connectToContactsDidPress(_ sender: Any) {
        requestContactsAccess()
    }
    
    @IBAction func maybeLaterButtonDidPress(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    func requestContactsAccess() {
        let contactStore = CNContactStore()
        contactStore.requestAccess(for: .contacts) { (granted, error) in
            if error != nil {
                print(error!.localizedDescription)
            } else {
                print("access granted")
                self.dismiss(animated: false, completion: nil)
            }
        }
    }
}
