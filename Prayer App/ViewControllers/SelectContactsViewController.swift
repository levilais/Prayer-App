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
import MessageUI

class SelectContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UISearchResultsUpdating {
    
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
    var cleanContactsAsCircleUsers = [CircleUser]()
    var contactsToDisplay = [CircleUser]()
    var filteredContacts = [CircleUser]()
    
    var segueFromSettings = false
    var members = [CircleUser]()
    var nonMembers = [CircleUser]()
    var sectionHeaders = [String]()
    
    // FIREBASE
    var ref: DatabaseReference!
    
    // SEARCH
    var searchActive = false
    var resultSearchController = UISearchController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        FirebaseHelper().getUsers()
        setupSearchResultsController()

        let backView = UIView(frame: self.tableView.bounds)
        backView.backgroundColor = UIColor.StyleFile.BackgroundColor
        self.tableView.backgroundView = backView
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "contactAuthStatusDidChange"), object: nil)
        loadCorrectView()
    }
    
    func setupSearchResultsController() {
        self.resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()
            controller.searchBar.barTintColor = UIColor.StyleFile.BackgroundColor
            controller.searchBar.tintColor = UIColor.StyleFile.DarkGrayColor
            controller.searchBar.backgroundColor = UIColor.StyleFile.BackgroundColor
            controller.searchBar.barStyle = UIBarStyle.default
            controller.searchBar.keyboardType = UIKeyboardType.asciiCapable
            controller.searchBar.keyboardAppearance = UIKeyboardAppearance.dark
            controller.hidesNavigationBarDuringPresentation = false
            
            self.tableView.tableHeaderView = controller.searchBar
            self.definesPresentationContext = true
            
            let textFieldInsideSearchBar = controller.searchBar.value(forKey: "searchField") as? UITextField
            textFieldInsideSearchBar?.layer.borderColor = UIColor.lightGray.cgColor
            textFieldInsideSearchBar?.layer.borderWidth = 0.5
            textFieldInsideSearchBar?.textColor = .clear
            textFieldInsideSearchBar?.textColor = UIColor.StyleFile.DarkGrayColor
            textFieldInsideSearchBar?.backgroundColor = .clear
            
            return controller
        })()
    }
    
    func loadCorrectView() {
        // if not logged in, dismiss
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
        contactsToDisplay = []
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
                    self.contactsToDisplay.append(userWithStatus)
                }
                
                self.cleanContactsAsCircleUsers = self.contactsToDisplay
            }
            
            self.setUpContactSections()
            
            DispatchQueue.main.async {
                if self.searchActive == true {
                    self.updateSearchResults(for: self.resultSearchController)
                }
                self.tableView.reloadData()
                self.updateSpotsLeftLabel()
            }
        })
    }
    
    func setUpContactSections() {
        members = []
        nonMembers = []
        sectionHeaders = []
        
        for user in contactsToDisplay {
            if let relationshipCheck = user.userRelationshipToCurrentUser {
                var sectionHeader = String()
                if relationshipCheck != CircleUser.userRelationshipToCurrentUser.nonMember.rawValue {
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
        var title = String()
        title = "Invite to join Prayer"
        if section == 0 {
            if sectionHeaders.count > 1 {
                title = "Invite member to your Circle"
            } else if sectionHeaders.count == 1 {
                if members.count > 0 {
                    title = "Invite member to your Circle"
                }
            }
        }
        return title
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionHeaders.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowCount = nonMembers.count
        
        if section == 0 {
            if sectionHeaders.count > 1 {
                rowCount = members.count
            } else if sectionHeaders.count == 1 {
                if members.count > 0 {
                    rowCount = members.count
                }
            }
        }
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addCircleMemberCell", for: indexPath) as! AddCircleMemberTableViewCell
 
        var user = CircleUser()
        
        if indexPath.section == 0 {
            if sectionHeaders.count > 1 {
                user = members[indexPath.row]
            } else if sectionHeaders.count == 1 {
                if members.count > 0 {
                    user = members[indexPath.row]
                } else {
                    user = nonMembers[indexPath.row]
                }
            } else {
                user = nonMembers[indexPath.row]
            }
        } else {
            user = nonMembers[indexPath.row]
        }
        
        print("\(user.firstName!) \(user.lastName!) relationship when loading: \(user.userRelationshipToCurrentUser!)")
        updateRelationshipActions(cell: cell, user: user)
        
        if let image = user.profileImageAsUIImage {
            cell.profileImageView.image = image
        } else {
            if let profileImageData = user.profileImage {
                if let profileImage = UIImage(data: profileImageData) {
                    cell.profileImageView.image = profileImage
                }
            }
        }
        
        let fullName = CircleUser().getFullName(user: user)
        cell.fullNameLabel.text = fullName
        cell.inviteButton.tag = indexPath.row
        cell.inviteButton.section = indexPath.section
        cell.inviteButton.addTarget(self, action: #selector(inviteMemberToCircle(sender:)), for: .touchUpInside)
        cell.deleteButton.tag = indexPath.row
        cell.deleteButton.section = indexPath.section
        cell.deleteButton.addTarget(self, action: #selector(deleteCircleMember(sender:)), for: .touchUpInside)
        
        return cell
    }
    
    func updateRelationshipActions(cell: AddCircleMemberTableViewCell, user: CircleUser) {
        if let userRelationship = user.userRelationshipToCurrentUser {
            switch userRelationship {
            case "invited":
                cell.inviteButton.isHidden = true
                cell.deleteButton.isHidden = false
                cell.relationshipStatusLabel.isHidden = false
            case "nonMember":
                cell.inviteButton.isHidden = false
                cell.deleteButton.isHidden = true
                cell.relationshipStatusLabel.isHidden = true
            default:
                cell.inviteButton.isHidden = false
                cell.deleteButton.isHidden = true
                cell.relationshipStatusLabel.isHidden = true
            }
        }
        updateSpotsLeftLabel()
    }
    
    // SECOND ATTEMPT
        @objc func inviteMemberToCircle(sender: CellButton){
            print("send invite fired")
            if CurrentUser.firebaseCircleMembers.count < 5 {
                let buttonTag = sender.tag
                let buttonSection = sender.section
                let indexPath = NSIndexPath(row: buttonTag, section: buttonSection)
                let cell = tableView.cellForRow(at: indexPath as IndexPath) as! AddCircleMemberTableViewCell
    
                var user = CircleUser()
                if indexPath.section == 0 {
                    if sectionHeaders.count > 1 {
                        user = members[indexPath.row]
                    } else if sectionHeaders.count == 1 {
                        if members.count > 0 {
                            user = members[indexPath.row]
                        } else {
                            user = nonMembers[indexPath.row]
                        }
                    } else {
                        user = nonMembers[indexPath.row]
                    }
                } else {
                    user = nonMembers[indexPath.row]
                }
    
                if user.userRelationshipToCurrentUser == CircleUser.userRelationshipToCurrentUser.memberButNoRelation.rawValue {
                    // SAVE TO FIREBASE
                    if let email = user.userEmail {
                        print("user email: \(email)")
                        FirebaseHelper().saveNewCircleUserToFirebase(userEmail: email, ref: self.ref)
                    }
    
                    // SAVE TO CORE DATA (where we're currently getting circle users from)
//                    user.userRelationshipToCurrentUser = CircleUser.userRelationshipToCurrentUser.invited.rawValue
//                    CurrentUser.circleMembers.append(user)
                    updateSpotsLeftLabel()
                    cell.inviteButton.isHidden = true
                    cell.deleteButton.isHidden = false
                    cell.relationshipStatusLabel.isHidden = false
                    self.getContactsData()
                } else {
                    inviteMemberToPrayer(sender: sender)
                }
            }
        }
    
    // FIRST ATTEMPT
//    @objc func inviteMemberToCircle(sender: CellButton){
//        print("send invite fired")
//        if CurrentUser.firebaseCircleMembers.count < 5 {
//            let buttonTag = sender.tag
//            let buttonSection = sender.section
//            let indexPath = NSIndexPath(row: buttonTag, section: buttonSection)
//            let cell = tableView.cellForRow(at: indexPath as IndexPath) as! AddCircleMemberTableViewCell
//
//            var user = CircleUser()
//            if indexPath.section == 0 {
//                if sectionHeaders.count > 1 {
//                    user = members[indexPath.row]
//                } else if sectionHeaders.count == 1 {
//                    if members.count > 0 {
//                        user = members[indexPath.row]
//                    } else {
//                        user = nonMembers[indexPath.row]
//                    }
//                } else {
//                    user = nonMembers[indexPath.row]
//                }
//            } else {
//                user = nonMembers[indexPath.row]
//            }
//
//            if user.userRelationshipToCurrentUser == CircleUser.userRelationshipToCurrentUser.memberButNoRelation.rawValue {
//                // SAVE TO FIREBASE
//                if let email = user.userEmail {
//                    print("user email: \(email)")
//                    FirebaseHelper().saveNewCircleUserToFirebase(userEmail: email, ref: self.ref)
//                }
//
//                showActionButtonForRelationship(cell: cell, user: user)
////                // SAVE TO CORE DATA (where we're currently getting circle users from)
////                user.userRelationshipToCurrentUser = CircleUser.userRelationshipToCurrentUser.invited
//////                CurrentUser.circleMembers.append(user)
////                cell.inviteButton.isHidden = true
////                cell.deleteButton.isHidden = false
////                cell.relationshipStatusLabel.isHidden = false
////                updateSpotsLeftLabel()
//            } else {
//                inviteMemberToPrayer(sender: sender)
//            }
//        }
//    }
    
//    func showActionButtonForRelationship(cell: AddCircleMemberTableViewCell, user: CircleUser) {
//        if let relationship = user.userRelationshipToCurrentUser {
//            print("relationship when trying to update cell: \(relationship)")
//            switch relationship {
//            case "invited":
//                cell.inviteButton.isHidden = true
//                cell.deleteButton.isHidden = false
//                cell.relationshipStatusLabel.isHidden = false
//            case "memberButNoRelation":
//                cell.inviteButton.isHidden = false
//                cell.deleteButton.isHidden = true
//                cell.relationshipStatusLabel.isHidden = true
//            case "nonMember":
//                cell.inviteButton.isHidden = false
//                cell.deleteButton.isHidden = true
//                cell.relationshipStatusLabel.isHidden = true
//            default:
//                cell.inviteButton.isHidden = false
//                cell.deleteButton.isHidden = true
//                cell.relationshipStatusLabel.isHidden = true
//            }
//            updateSpotsLeftLabel()
//        }
//    }
    
    func updateSpotsLeftLabel() {
        circleUserSpotsUsed = CurrentUser.firebaseCircleMembers.count
        if circleUserSpotsUsed < 5 {
            spotsLeftLabel.text = "You still have \(5 - circleUserSpotsUsed) out of 5 Circle Member spots available."
        } else {
            spotsLeftLabel.text = "You have used all 5 of your Circle Member spots. Uninvite or remove someone from your circle if you would like to invite someone else."
        }
    }
    
    //    func updateSpotsLeftLabel() {
    //        circleUserSpotsUsed = CurrentUser.circleMembers.count
    //        if circleUserSpotsUsed < 5 {
    //            spotsLeftLabel.text = "You still have \(5 - circleUserSpotsUsed) out of 5 Circle Member spots available."
    //        } else {
    //            spotsLeftLabel.text = "You have used all 5 of your Circle Member spots. Uninvite or remove someone from your circle if you would like to invite someone else."
    //        }
    //    }
    
//    @objc func inviteMemberToCircle(sender: CellButton){
//        print("send invite fired")
//        if CurrentUser.circleMembers.count < 5 {
//            let buttonTag = sender.tag
//            let buttonSection = sender.section
//            let indexPath = NSIndexPath(row: buttonTag, section: buttonSection)
//            let cell = tableView.cellForRow(at: indexPath as IndexPath) as! AddCircleMemberTableViewCell
//
//            var user = CircleUser()
//            if indexPath.section == 0 {
//                if sectionHeaders.count > 1 {
//                    user = members[indexPath.row]
//                } else if sectionHeaders.count == 1 {
//                    if members.count > 0 {
//                        user = members[indexPath.row]
//                    } else {
//                        user = nonMembers[indexPath.row]
//                    }
//                } else {
//                    user = nonMembers[indexPath.row]
//                }
//            } else {
//                user = nonMembers[indexPath.row]
//            }
//
//            if user.userRelationshipToCurrentUser == CircleUser.userRelationshipToCurrentUser.memberButNoRelation {
//                // SAVE TO FIREBASE
//                if let email = user.userEmail {
//                    print("user email: \(email)")
//                    FirebaseHelper().saveNewCircleUserToFirebase(userEmail: email, ref: self.ref)
//                }
//
//                // SAVE TO CORE DATA (where we're currently getting circle users from)
//                user.userRelationshipToCurrentUser = CircleUser.userRelationshipToCurrentUser.invited
//                CurrentUser.circleMembers.append(user)
//                updateSpotsLeftLabel()
//                cell.inviteButton.isHidden = true
//                cell.deleteButton.isHidden = false
//                cell.relationshipStatusLabel.isHidden = false
//            } else {
//                inviteMemberToPrayer(sender: sender)
//            }
//        }
//    }
    
    func inviteMemberToPrayer(sender: UIButton) {
        let user = nonMembers[sender.tag]

        var emails = [CNLabeledValue<NSString>]()
        var phoneNumbers = [CNLabeledValue<CNPhoneNumber>]()
        var alert = UIAlertController()
        var errorMessage = ""
        
        if let emailsCheck = user.circleMemberEmails {
            emails = emailsCheck
        }
        if let phoneNumbersCheck = user.circleMemberPhoneNumbers {
            phoneNumbers = phoneNumbersCheck
        }
        
        if emails.count > 0 || phoneNumbers.count > 0 {
            let contactName = CircleUser().getFullName(user: user)
            alert = UIAlertController(title: "Invite \(contactName) to Prayer", message: nil, preferredStyle: .actionSheet)
            var i = 0
            if emails.count > 0 {
                if MFMailComposeViewController.canSendMail() {
                    for email in emails {
                        let emailString = email.value as String
                        let action = UIAlertAction(title: emailString, style: .default, handler: { (action) in
                            let composeVC = MFMailComposeViewController()
                            composeVC.mailComposeDelegate = self
                            
                            composeVC.setToRecipients([emailString])
                            composeVC.setSubject("An invitation from [username]")
                            composeVC.setMessageBody("[username] would like to invite you to download Prayer - Swipe To Send.  (There would be a link to download the app here in the near future)", isHTML: false)
                            
                            self.present(composeVC, animated: true, completion: nil)
                        })
                        alert.addAction(action)
                        i += 1
                    }
                } else {
                    errorMessage = "Messaging services are not available at this time"
                }
            }
            
            i = 0
            if phoneNumbers.count > 0 {
                if MFMessageComposeViewController.canSendText() {
                    for phoneNumber in phoneNumbers {
                        let number = "(text) " + phoneNumber.value.stringValue
                        let action = UIAlertAction(title: number, style: .default, handler: { (action) in
                            print("pressed: \(number)")
                            let composeVC = MFMessageComposeViewController()
                            composeVC.messageComposeDelegate = self
                            composeVC.recipients = [number]
                            composeVC.body = "[username] would like to invite you to download Prayer - Swipe To Send."
                            self.present(composeVC, animated: true, completion: nil)
                            
                        })
                        alert.addAction(action)
                        i += 1
                    }
                } else {
                    errorMessage = "Messaging services are not available at this time"
                }
            }
            if errorMessage != "" {
                alert = UIAlertController(title: "There was an error", message: errorMessage, preferredStyle: .actionSheet)
                let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(action)
            } else {
                let action = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alert.addAction(action)
            }
        }
        
        present(alert, animated: true, completion: nil)
        print(alert.actions.count)
        alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
    }
    
    @objc func deleteCircleMember(sender: CellButton) {
        let alert = UIAlertController(title: "Are you sure?", message: "Are you sure you want to remove this Circle Member?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Yes, I'm sure", style: .default) { (action) in
            let buttonTag = sender.tag
            let buttonSection = sender.section
            let indexPath = NSIndexPath(row: buttonTag, section: buttonSection)
            let cell = self.tableView.cellForRow(at: indexPath as IndexPath) as! AddCircleMemberTableViewCell
            
            let user = self.members[indexPath.row]
            
            cell.inviteButton.isHidden = false
            cell.deleteButton.isHidden = true
            cell.relationshipStatusLabel.isHidden = true
            
            if let userEmail = user.userEmail {
                FirebaseHelper().deleteCircleUserFromCurrentUserFirebase(userEmail: userEmail, ref: self.ref)
                print("circle user count after delete called \(CurrentUser.firebaseCircleMembers.count)")
            }
            
            var i = 0
            for circleUser in CurrentUser.firebaseCircleMembers {
                if let circleUserEmail = circleUser.userEmail {
                    if let emailToCheck = user.userEmail {
                        if circleUserEmail == emailToCheck {
                            CurrentUser.firebaseCircleMembers.remove(at: i)
                            print("user removed from firebase")
                        }
                    }
                }
                i += 1
            }
            
            self.updateSpotsLeftLabel()
            self.getContactsData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true) {
            print("completed alert")
        }
    }
    
    //    @objc func deleteCircleMember(sender: CellButton) {
    //        let alert = UIAlertController(title: "Are you sure?", message: "Are you sure you want to remove this Circle Member?", preferredStyle: .alert)
    //        let okAction = UIAlertAction(title: "Yes, I'm sure", style: .default) { (action) in
    //            let buttonTag = sender.tag
    //            let buttonSection = sender.section
    //            let indexPath = NSIndexPath(row: buttonTag, section: buttonSection)
    //            let cell = self.tableView.cellForRow(at: indexPath as IndexPath) as! AddCircleMemberTableViewCell
    //
    //            let user = self.members[indexPath.row]
    //
    //            print("userEmail in delete function: \(user.userEmail!)")
    //            if let userEmail = user.userEmail {
    //                FirebaseHelper().deleteCircleUserFromCurrentUserFirebase(userEmail: userEmail, ref: self.ref)
    //            }
    //
    //            if let idToDelete = user.circleUID {
    //                var matchFound = false
    //                while matchFound == false {
    //                    var i = 0
    //                    for circleMember in CurrentUser.circleMembers {
    //                        if let circleMemberID = circleMember.circleUID {
    //                            if circleMemberID == idToDelete {
    //                                user.userRelationshipToCurrentUser = CircleUser.userRelationshipToCurrentUser.memberButNoRelation
    //                                CurrentUser.circleMembers.remove(at: i)
    //                                cell.inviteButton.isHidden = false
    //                                cell.deleteButton.isHidden = true
    //                                cell.relationshipStatusLabel.isHidden = true
    //                                self.updateSpotsLeftLabel()
    //                                print("deleted: \(user.firstName!) \(user.lastName!)")
    //                                matchFound = true
    //                            }
    //                        }
    //                        i += 1
    //                    }
    //                    matchFound = true
    //                }
    //            }
    //        }
    //        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
    //        alert.addAction(okAction)
    //        alert.addAction(cancelAction)
    //        present(alert, animated: true) {
    //            print("completed alert")
    //        }
    //    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        var labelText = ""
        
        switch result {
        case .cancelled:
            print("cancelled")
        case .sent:
            labelText = "Sent!"
        case .saved:
            labelText = "Saved!"
        case .failed:
            print("failed")
        }
        
        controller.dismiss(animated: true) {
            if labelText != "" {
                Animations().showPopup(labelText: labelText, presentingVC: self)
            }
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                      didFinishWith result: MessageComposeResult) {
        var labelText = ""
        
        switch result {
        case .cancelled:
            print("cancelled")
        case .sent:
            labelText = "Sent!"
        case .failed:
            print("failed")
        }
        
        controller.dismiss(animated: true) {
            if labelText != "" {
                Animations().showPopup(labelText: labelText, presentingVC: self)
            }
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text
        if let searchText = searchText {
            if !searchText.isEmpty {
                self.contactsToDisplay = self.cleanContactsAsCircleUsers.filter { $0.firstName!.contains(searchText) || $0.lastName!.contains(searchText) }
                for contact in self.contactsToDisplay {
                    print("\(contact.firstName!) \(contact.lastName!)")
                }
                self.searchActive = true
            }
            else {
                self.contactsToDisplay = self.cleanContactsAsCircleUsers
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showResultsBeforeSearchingNotification"), object: nil) // Calls SearchVC
                self.searchActive = false
            }
        }
        
        setUpContactSections()
        self.tableView.reloadData()
    }
    
    @objc func handleNotification(_ notification: NSNotification) {
        DispatchQueue.main.async {
            self.loadCorrectView()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "contactAuthStatusDidChange"), object: nil)
    }
}
