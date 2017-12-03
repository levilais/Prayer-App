//
//  SelectContactsViewController.swift
//  Prayer App
//
//  Created by Levi on 11/20/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import Contacts
import ContactsUI

class SelectContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // Authorize Contacts View
    @IBOutlet weak var contactsNotAllowedView: UIView!
    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var selectContactsView: UIView!
    @IBOutlet weak var connectToContactsButton: UIButton!
    @IBOutlet weak var maybeLaterButton: UIButton!
    
    // Connect To Contacts View
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var spotsLeftLabel: UILabel!
    var circleUserSpotsUsed = Int()
    var cnContacts = [CNContact]()
    var segueFromSettings = false
    var cleanContactsAsCircleUsers = [CircleUser]()

    var members = [CircleUser]()
    var nonMembers = [CircleUser]()
    var sectionHeaders = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FirebaseHelper().getUsers()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "contactAuthStatusDidChange"), object: nil)
        updateSpotsLeftLabel()
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
                FirebaseHelper().getUserEmails(completion: { (success) in
                    self.getContactsData()
                })
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
        sectionHeaders = []
        members = []
        nonMembers = []

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
                var append = true
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
                    append = false
                } else {
                    fullName = firstName + " " + lastName
                }
                if append == true {
                    let userWithStatus = CircleUser().getRelationshipStatus(userToCheck: user)
                    self.cleanContactsAsCircleUsers.append(userWithStatus)
                }
            }
            self.setUpContactSections()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            for user in self.cleanContactsAsCircleUsers {
                if let status = user.userRelationshipToCurrentUser?.rawValue {
                    print("user relationship status: \(status)")
                }
            }
        })
    }
    
    func setUpContactSections() {
        for user in cleanContactsAsCircleUsers {
            if let relationshipCheck = user.userRelationshipToCurrentUser {
                var sectionHeader = String()
                if relationshipCheck != CircleUser.userRelationshipToCurrentUser.nonMember {
                    sectionHeader = "Invite member to your Circle"
                    members.append(user)
                } else {
                    sectionHeader = "Invite to join Prayer"
                    nonMembers.append(user)
                }
                if !sectionHeaders.contains(sectionHeader) {
                    sectionHeaders.append(sectionHeader)
                }
            }
        }
    }

    @IBAction func doneButtonDidPress(_ sender: Any) {
        if self.navigationController != nil {
            self.navigationController?.popToRootViewController(animated: true)
        } else if segueFromSettings == true {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
//            self.dismiss(animated: false, completion: nil)
        }
    }
    
    @IBAction func connectToContactsDidPress(_ sender: Any) {
        if ContactsHandler().contactsAuthStatus() == ".authorized" {
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
            self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if (view is UITableViewHeaderFooterView) {
            if let tableViewHeaderFooterView = view as? UITableViewHeaderFooterView {
                tableViewHeaderFooterView.contentView.backgroundColor = UIColor.StyleFile.LightGrayColor
                tableViewHeaderFooterView.textLabel?.font = UIFont.StyleFile.SectionHeaderFont
                tableViewHeaderFooterView.textLabel?.textColor = UIColor.StyleFile.DarkGrayColor
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaders[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionHeaders.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowCount = Int()
        if section == 0 && sectionHeaders.count > 1 {
            rowCount = members.count
        } else {
            rowCount = nonMembers.count
        }
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addCircleMemberCell", for: indexPath) as! AddCircleMemberTableViewCell
 
        var user = CircleUser()
        switch indexPath.section {
        case 0:
            if sectionHeaders.count > 1 {
                user = members[indexPath.row]
            } else {
                print("called")
                user = nonMembers[indexPath.row]
            }
        case 1:
            user = nonMembers[indexPath.row]
        default:
            user = nonMembers[indexPath.row]
        }
        
        
        if let profileImageData = user.profileImage {
            if let profileImage = UIImage(data: profileImageData) {
                cell.profileImageView.image = profileImage
            }
        }
        updateRelationshipActions(cell: cell, user: user)
        
        let fullName = CircleUser().getFullName(user: user)
        cell.fullNameLabel.text = fullName
        cell.inviteButton.tag = indexPath.row
        cell.inviteButton.section = indexPath.section
        cell.inviteButton.addTarget(self, action: #selector(sendInvite(sender:)), for: .touchUpInside)
        cell.deleteButton.tag = indexPath.row
        cell.deleteButton.section = indexPath.section
        cell.deleteButton.addTarget(self, action: #selector(deleteCircleMember(sender:)), for: .touchUpInside)
        
        return cell
    }
    
    func updateRelationshipActions(cell: AddCircleMemberTableViewCell, user: CircleUser) {
        if let userRelationship = user.userRelationshipToCurrentUser {
            switch userRelationship {
            case CircleUser.userRelationshipToCurrentUser.invited:
                cell.inviteButton.isHidden = true
                cell.deleteButton.isHidden = false
                cell.relationshipStatusLabel.isHidden = false
            case CircleUser.userRelationshipToCurrentUser.nonMember:
                cell.inviteButton.isHidden = false
                cell.deleteButton.isHidden = true
                cell.relationshipStatusLabel.isHidden = true
            default:
                cell.inviteButton.isHidden = false
                cell.deleteButton.isHidden = true
                cell.relationshipStatusLabel.isHidden = true
            }
        }
    }
    
    @objc func sendInvite(sender: CellButton){
        print("send invite fired")
        if CurrentUser.circleMembers.count < 5 {
            let buttonTag = sender.tag
            let buttonSection = sender.section
            let indexPath = NSIndexPath(row: buttonTag, section: buttonSection)
            let cell = tableView.cellForRow(at: indexPath as IndexPath) as! AddCircleMemberTableViewCell
            
            var user = CircleUser()
            switch indexPath.section {
            case 0:
                if sectionHeaders.count > 1 {
                    user = members[indexPath.row]
                } else {
                    user = nonMembers[indexPath.row]
                }
            case 1:
                user = nonMembers[indexPath.row]
            default:
                user = nonMembers[indexPath.row]
            }
            if user.userRelationshipToCurrentUser == CircleUser.userRelationshipToCurrentUser.memberButNoRelation {
                user.userRelationshipToCurrentUser = CircleUser.userRelationshipToCurrentUser.invited
                CurrentUser.circleMembers.append(user)
                updateSpotsLeftLabel()
                cell.inviteButton.isHidden = true
                cell.deleteButton.isHidden = false
                cell.relationshipStatusLabel.isHidden = false
                print("row number: \(buttonTag)")
                print("CurrentUser.circleMembers.count: \(CurrentUser.circleMembers.count)")
            } else {
                print("not a member yet - need to do action sheet to invite")
            }
        }
    }
    
    @objc func deleteCircleMember(sender: CellButton) {
        let alert = UIAlertController(title: "Are you sure?", message: "Are you sure you want to remove this Circle Member?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Yes, I'm sure", style: .default) { (action) in
            let buttonTag = sender.tag
            let buttonSection = sender.section
            let indexPath = NSIndexPath(row: buttonTag, section: buttonSection)
            let cell = self.tableView.cellForRow(at: indexPath as IndexPath) as! AddCircleMemberTableViewCell
            let user = self.members[indexPath.row]
            
            print("attempted")
            if let idToDelete = user.circleUID {
                print("user UID: \(idToDelete)")
                var matchFound = false
                while matchFound == false {
                    var i = 0
                    for circleMember in CurrentUser.circleMembers {
                        if let circleMemberID = circleMember.circleUID {
                            print("circleMember UID: \(circleMemberID)")
                            if circleMemberID == idToDelete {
                                CurrentUser.circleMembers.remove(at: i)
                                cell.inviteButton.isHidden = false
                                cell.deleteButton.isHidden = true
                                cell.relationshipStatusLabel.isHidden = true
                                self.updateSpotsLeftLabel()
                                matchFound = true
                            }
                        }
                        i += 1
                    }
                    matchFound = true
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true) {
            print("completed alert")
        }
    }
    
    func updateSpotsLeftLabel() {
        circleUserSpotsUsed = CurrentUser.circleMembers.count
        if members.count == 0 {
            spotsLeftLabel.text = "None of your contacts are members of Prayer. Invite them to join!"
        } else {
            if circleUserSpotsUsed < 5 {
                spotsLeftLabel.text = "You still have \(5 - circleUserSpotsUsed) out of 5 Circle Member spots available."
            } else {
                spotsLeftLabel.text = "You have used all 5 of your Circle Member spots. Uninvite or remove someone from your circle if you would like to invite someone else."
            }
        }
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
