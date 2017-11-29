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

class SelectContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var contactsNotAllowedView: UIView!
    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var selectContactsView: UIView!
    @IBOutlet weak var connectToContactsButton: UIButton!
    @IBOutlet weak var maybeLaterButton: UIButton!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var spotsLeftLabel: UILabel!
    var cnContacts = [CNContact]()
    var cleanContactsAsCircleUsers = [CircleUser]()
    var segueFromSettings = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "contactAuthStatusDidChange"), object: nil)
        loadCorrectView()
    }
    
    func loadCorrectView() {
        if ContactsHandler().contactsAuthStatus() == ".authorized" {
            if segueFromSettings == true {
                dismiss(animated: true, completion: nil)
            } else {
                contactsNotAllowedView.isHidden = true
                doneButton.isHidden = false
                selectContactsView.isHidden = false
                getContactsData()
            }
        } else if ContactsHandler().contactsAuthStatus() == ".notDetermined" {
            contactsNotAllowedView.isHidden = false
            selectContactsView.isHidden = true
            doneButton.isHidden = true
            connectToContactsButton.isHidden = false
            maybeLaterButton.isHidden = false
        } else {
            contactsNotAllowedView.isHidden = false
            selectContactsView.isHidden = true
            doneButton.isHidden = false
            explanationLabel.text = "You have previously denied the Prayer app access to your Contacts.  To enable this feature, please allow access to your Contacts by going to Settings > Privacy > Contacts > Prayer."
            connectToContactsButton.isHidden = true
            maybeLaterButton.isHidden = true
        }
    }

    func getContactsData() {
        cnContacts = []
        cleanContactsAsCircleUsers = []
        let store = CNContactStore()
        store.requestAccess(for: .contacts, completionHandler: {
            granted, error in
            
            guard granted else {
                print("didn't have access to contacts")
                return
            }
            
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey,CNContactEmailAddressesKey,CNContactImageDataKey,CNContactImageDataAvailableKey,CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            
            request.sortOrder = CNContactSortOrder.familyName
            
            do {
                try store.enumerateContacts(with: request){
                    (contact, cursor) -> Void in
                    if (contact.isKeyAvailable(CNContactFamilyNameKey)) || (contact.isKeyAvailable(CNContactGivenNameKey)) {
                        self.cnContacts.append(contact)
                    }
                }
            } catch let error {
                NSLog("Fetch contact error: \(error)")
            }
            
            for contact in self.cnContacts {
                let user = CircleUser().setFromCnContact(cnContact: contact)
                
                var fullName = ""
                var firstName = String()
                var lastName = String()
                if let firstNameCheck = user.firstName {
                    firstName = firstNameCheck
                }
                if let lastNameCheck = user.lastName {
                    lastName = lastNameCheck
                }
                if firstName == "" && lastName != "" {
                    fullName = lastName
                } else if fullName == "" && lastName == "" {
                    // this should never be called
                    
                } else {
                    fullName = firstName + " " + lastName
                }
                if fullName != "" {
                    self.cleanContactsAsCircleUsers.append(user)
                }
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }
    
    @IBAction func doneButtonDidPress(_ sender: Any) {
        if self.navigationController != nil {
            self.navigationController?.popToRootViewController(animated: true)
        } else if segueFromSettings == true {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @IBAction func connectToContactsDidPress(_ sender: Any) {
        if ContactsHandler().contactsAuthStatus() == ".authorized" {
            // this should never fire
            print("access granted - this should never fire")
        } else {
            ContactsHandler().requestAccess()
        }
    }
    
    @IBAction func maybeLaterButtonDidPress(_ sender: Any) {
        if self.navigationController != nil {
            self.navigationController?.popToRootViewController(animated: true)
        } else if segueFromSettings == true {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if (view is UITableViewHeaderFooterView) {
            if let tableViewHeaderFooterView = view as? UITableViewHeaderFooterView {
                tableViewHeaderFooterView.contentView.backgroundColor = UIColor.StyleFile.GoldColor
                tableViewHeaderFooterView.textLabel?.font = UIFont.StyleFile.SectionHeaderFont
                tableViewHeaderFooterView.textLabel?.textColor = UIColor.StyleFile.BackgroundColor
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Your Contacts"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cleanContactsAsCircleUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addCircleMemberCell", for: indexPath) as! AddCircleMemberTableViewCell
        
//        cell.prepareForReuse()
        
        let user = cleanContactsAsCircleUsers[indexPath.row]
        
        var fullName = ""
        var firstName = String()
        var lastName = String()
        if let firstNameCheck = user.firstName {
            firstName = firstNameCheck
        }
        if let lastNameCheck = user.lastName {
            lastName = lastNameCheck
        }
        if firstName == "" && lastName != "" {
            fullName = lastName
        } else if fullName == "" && lastName == "" {
            // this should never be called
        } else {
            fullName = firstName + " " + lastName
        }
        
        print("fullName: \(fullName)")
        
        if let profileImageData = user.profileImage {
            if let profileImage = UIImage(data: profileImageData) {
                cell.profileImageView.image = profileImage
            }
        }
        
        if user.hasBeenInvited == true {
            cell.inviteButton.isHidden = true
            cell.inviteSentButton.isHidden = false
        } else {
            cell.inviteButton.isHidden = false
            cell.inviteSentButton.isHidden = true
        }
        
        cell.fullNameLabel.text = fullName
        cell.inviteButton.tag = indexPath.row
        cell.inviteButton.addTarget(self, action: #selector(sendInvite(sender:)), for: .touchUpInside)
        
        return cell
    }
    
    @objc func sendInvite(sender: UIButton){
        let buttonTag = sender.tag
        let indexPath = NSIndexPath(row: buttonTag, section: 0)
        let cell = tableView.cellForRow(at: indexPath as IndexPath) as! AddCircleMemberTableViewCell
        let user = cleanContactsAsCircleUsers[indexPath.row]
        user.hasBeenInvited = true
        CurrentUser.circleMembers.append(user)
        cell.inviteButton.isHidden = true
        cell.inviteSentButton.isHidden = false
    
        print("row number: \(buttonTag)")
        print("CurrentUser.circleMembers.count: \(CurrentUser.circleMembers.count)")
    }
    
    @objc func handleNotification(_ notification: NSNotification) {
        DispatchQueue.main.async {
            self.loadCorrectView()
        }
        print("notification fired")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "contactAuthStatusDidChange"), object: nil)
    }
}
