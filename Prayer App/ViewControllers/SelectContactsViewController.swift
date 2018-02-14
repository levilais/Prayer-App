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

class SelectContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UISearchResultsUpdating, UITextFieldDelegate {
    
    var ranCount = Int()
    
    var explicitDismiss = false
    
    // Authorize Contacts View
    @IBOutlet weak var contactsNotAllowedView: UIView!
    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var selectContactsView: UIView!
    @IBOutlet weak var connectToContactsButton: UIButton!
    @IBOutlet weak var maybeLaterButton: UIButton!
    var phoneAlert = UIAlertController()
    
    // Connect To Contacts View
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var spotsLeftLabel: UILabel!
    var circleUserSpotsUsed = Int()
    var cnContacts = [CNContact]()
    var cleanContactsAsCircleUsers = [CircleUser]()
    var contactsToDisplay = [CircleUser]()
    var filteredContacts = [CircleUser]()
    var sortedContacts = [String:[CircleUser]]()
    
    var segueFromSettings = false
    var members = [CircleUser]()
    var nonMembers = [CircleUser]()
    var sectionHeaders = [String]()
    var sortedKeys = [String]()
    
    // COMPOSE VARIABLES
    var messageComposeDelegate: MFMessageComposeViewControllerDelegate!
    var mailComposeDelegate: MFMailComposeViewControllerDelegate!
    var isComposeSegue = false
    
    // FIREBASE
    var ref: DatabaseReference!
    var userRef: DatabaseReference!
    
    // SEARCH
    var searchActive = false
    var resultSearchController = UISearchController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        if let userID = Auth.auth().currentUser?.uid {
            userRef = Database.database().reference().child("users").child(userID)
        }
        self.getUsers()
        setupSearchResultsController()
        
        messageComposeDelegate = self
        mailComposeDelegate = self

        let backView = UIView(frame: self.tableView.bounds)
        backView.backgroundColor = UIColor.StyleFile.BackgroundColor
        self.tableView.backgroundView = backView
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "contactAuthStatusDidChange"), object: nil)
        loadCorrectView()
        
        if let userPhone = CurrentUser.currentUser.userPhone {
            print("has phone number")
        } else {
            print("no phone")
            presentPhoneNumberRequestAlert()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        isComposeSegue = false
        print("viewDidAppear Ran")
    }
    
    func getUsers() {
        ref.child("users").observe(.childAdded) { (snapshot) in
            if let userDictionary = snapshot.value as? NSDictionary {
                if let email = userDictionary["userEmail"] as? String {
                    if !FirebaseHelper.firebaseUserEmails.contains(email) {
                        FirebaseHelper.firebaseUserEmails.append(email)
                    }
                }
            }
        }
    }
    
    func getUserEmails(completion: @escaping (Bool) -> Void) {
        ref.child("users").queryOrderedByKey().observeSingleEvent(of: .value) { (snapshot) in
            if let userDictionary = snapshot.value as? NSDictionary {
                if let email = userDictionary["userEmail"] as? String {
                    if !FirebaseHelper.firebaseUserEmails.contains(email) {
                        FirebaseHelper.firebaseUserEmails.append(email)
                    }
                }
            }
            completion(true)
        }
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
        if ContactsHandler().contactsAuthStatus() == ".authorized" {
            if segueFromSettings == true {
                dismiss(animated: true, completion: nil)
            } else {
                contactsNotAllowedView.isHidden = true
                doneButton.isHidden = false
                selectContactsView.isHidden = false
                self.getUserEmails(completion: { (success) in
                    self.getContactsData()
                })
                if let userPhone = CurrentUser.currentUser.userPhone {
                    print("has phone number")
                } else {
                    if Loads.askedAboutPhone == false {
                        presentPhoneNumberRequestAlert()
                    }
                }
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
                var newCnContacts = [CNContact]()
                try store.enumerateContacts(with: request){
                    (contact, cursor) -> Void in
                    if (contact.isKeyAvailable(CNContactFamilyNameKey)) || (contact.isKeyAvailable(CNContactGivenNameKey)) {
                        newCnContacts.append(contact)
                    }
                }
                self.cnContacts = newCnContacts
            } catch let error {
                NSLog("Fetch contact error: \(error)")
            }
            
            var newContactsToDisplay = [CircleUser]()
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
                    newContactsToDisplay.append(userWithStatus)
                }
            }
            
            self.contactsToDisplay = newContactsToDisplay
            self.cleanContactsAsCircleUsers = self.contactsToDisplay
            
            self.setUpContactSections()
            
            DispatchQueue.main.async {
                if self.searchActive == true {
                    self.updateSearchResults(for: self.resultSearchController)
                }
                self.tableView.reloadData()
            }
        })
    }

    func setUpContactSections() {
        var newSortedContacts = [String:[CircleUser]]()
        if self.contactsToDisplay.count > 0 {
            for circleUser in self.contactsToDisplay {
                if let relationship = circleUser.relationshipToCurrentUser {
                    if relationship != CircleUser.userRelationshipToCurrentUser.nonMember.rawValue {
                        if let email = circleUser.userEmail {
                            if let currentUserEmail = CurrentUser.currentUser.userEmail {
                                if email != currentUserEmail {
                                    if var oldArray = newSortedContacts["Invite member to your Circle"] {
                                        oldArray.append(circleUser)
                                        newSortedContacts["Invite member to your Circle"] = oldArray
                                    } else {
                                        let newArray = [circleUser]
                                        newSortedContacts["Invite member to your Circle"] = newArray
                                    }
                                }
                            }
                        }
                    } else {
                        if var oldArray = newSortedContacts["Invite to join Prayer"] {
                            oldArray.append(circleUser)
                            newSortedContacts["Invite to join Prayer"] = oldArray
                        } else {
                            let newArray = [circleUser]
                            newSortedContacts["Invite to join Prayer"] = newArray
                        }
                    }
                }
            }
        }
        sortedContacts = newSortedContacts
        
        let keys = Array(sortedContacts.keys)
        sortedKeys = keys.sorted()
    }

    @IBAction func doneButtonDidPress(_ sender: Any) {
        dismissView()
    }
    
    func dismissView() {
        print("dismiss view called")
        if self.navigationController != nil {
            self.navigationController?.popToRootViewController(animated: true)
        } else if segueFromSettings == true {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.view.window!.rootViewController?.dismiss(animated: true, completion: nil)
        }
        self.explicitDismiss = true
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
        return sortedKeys[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedKeys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionArray = sortedContacts[sortedKeys[section]] {
            return sectionArray.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addCircleMemberCell", for: indexPath) as! AddCircleMemberTableViewCell
        
        let user = contactAtIndexPath(indexPath: indexPath)
        updateRelationshipActions(cell: cell, user: user)
        
        if let image = user.profileImageAsImage {
            cell.profileImageView.image = image
        } else {
            if let profileImageData = user.profileImageAsData {
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
    
    func contactAtIndexPath(indexPath: IndexPath) -> CircleUser {
        var contact = CircleUser()
        if let sectionArray = sortedContacts[sortedKeys[indexPath.section]] {
            contact = sectionArray[indexPath.row]
        }
        return contact
    }
    
    func updateRelationshipActions(cell: AddCircleMemberTableViewCell, user: CircleUser) {
        if let userRelationship = user.relationshipToCurrentUser {
            switch userRelationship {
            case "invited":
                cell.inviteButton.isHidden = true
                cell.deleteButton.isHidden = false
                cell.relationshipStatusLabel.text = "Invited"
                cell.relationshipStatusLabel.isHidden = false
            case "myCircleMember":
                cell.inviteButton.isHidden = true
                cell.deleteButton.isHidden = false
                cell.relationshipStatusLabel.text = "Circle Member"
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
    
    @objc func inviteMemberToCircle(sender: CellButton) {
        if CurrentUser.firebaseCircleMembers.count < 5 {
            let buttonTag = sender.tag
            let buttonSection = sender.section
            let indexPath = IndexPath(row: buttonTag, section: buttonSection)
            let cell = tableView.cellForRow(at: indexPath as IndexPath) as! AddCircleMemberTableViewCell
            let user = contactAtIndexPath(indexPath: indexPath as IndexPath)
            
            if user.relationshipToCurrentUser == CircleUser.userRelationshipToCurrentUser.memberButNoRelation.rawValue {
                if let email = user.userEmail {
                    FirebaseHelper().inviteUserToCircle(userEmail: email, ref: self.ref)
                }
                
                updateSpotsLeftLabel()
                cell.inviteButton.isHidden = true
                cell.deleteButton.isHidden = false
                cell.relationshipStatusLabel.isHidden = false
                self.getContactsData()
            } else {
                inviteContactToPrayer(sender: sender)
            }
        }
    }
    
    func updateSpotsLeftLabel() {
        circleUserSpotsUsed = CurrentUser.firebaseCircleMembers.count
        if circleUserSpotsUsed < 5 {
            spotsLeftLabel.text = "You still have \(5 - circleUserSpotsUsed) out of 5 Circle Member spots available."
        } else {
            spotsLeftLabel.text = "You have used all 5 of your Circle Member spots. Uninvite or remove someone from your circle if you would like to invite someone else."
        }
    }
    
    func inviteContactToPrayer(sender: CellButton) {
        let buttonTag = sender.tag
        let buttonSection = sender.section
        let indexPath = IndexPath(row: buttonTag, section: buttonSection)
        let user = contactAtIndexPath(indexPath: indexPath as IndexPath)
        
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
                            if let firstName = CurrentUser.currentUser.firstName {
                                if let lastName = CurrentUser.currentUser.lastName {
                                    composeVC.setSubject("A Prayer invitation from \(firstName) \(lastName)")
                                    composeVC.setMessageBody("I want to invite you to download Prayer - Swipe To Send.  Get it here: https://itunes.apple.com/us/app/prayer-swipe-to-send/id1303817456?ls=1&mt=8", isHTML: false)
                                    self.isComposeSegue = true
                                    self.present(composeVC, animated: true, completion: nil)
                                }
                            }
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
                        let number = phoneNumber.value.stringValue
                        var phoneType = ""
                        if let label = phoneNumber.label {
                            let labelString = CNLabeledValue<NSString>.localizedString(forLabel: label)
                            phoneType = "(\(labelString)) "
                        }
                        let numberString = phoneType + phoneNumber.value.stringValue
                        let action = UIAlertAction(title: numberString, style: .default, handler: { (action) in
                            let composeVC = MFMessageComposeViewController()
                            composeVC.messageComposeDelegate = self
                            composeVC.recipients = [number]
                            composeVC.body = "I want to invite you to download Prayer - Swipe To Send.  Get it here: https://itunes.apple.com/us/app/prayer-swipe-to-send/id1303817456?ls=1&mt=8"
                            self.isComposeSegue = true
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
        alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
    }
    
    @objc func deleteCircleMember(sender: CellButton) {
        ranCount = 0
        let alert = UIAlertController(title: "Are you sure?", message: "Are you sure you want to remove this Circle Member?", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Yes, I'm sure", style: .default) { (action) in
            let buttonTag = sender.tag
            let buttonSection = sender.section
            let indexPath = NSIndexPath(row: buttonTag, section: buttonSection)
            let cell = self.tableView.cellForRow(at: indexPath as IndexPath) as! AddCircleMemberTableViewCell
            
            let user = self.contactAtIndexPath(indexPath: indexPath as IndexPath)
            
            cell.inviteButton.isHidden = false
            cell.deleteButton.isHidden = true
            cell.relationshipStatusLabel.isHidden = true
            
            CircleUser().removeUserFromCircle(circleUser: user)
            
            self.updateSpotsLeftLabel()
            self.getContactsData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
        alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
    }
    
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
                if self.resultSearchController.isActive == true {
                    self.resultSearchController.isActive = false
                    self.resultSearchController.resignFirstResponder()
                    self.searchActive = false
                }
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
                self.resultSearchController.isActive = false
                self.resultSearchController.resignFirstResponder()
                self.searchActive = false
                Animations().showPopup(labelText: labelText, presentingVC: self)
            }
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text
        if let searchText = searchText {
            if !searchText.isEmpty {
                self.contactsToDisplay = self.cleanContactsAsCircleUsers.filter { $0.firstName!.contains(searchText) || $0.lastName!.contains(searchText) }
                self.searchActive = true
            }
            else {
                self.contactsToDisplay = self.cleanContactsAsCircleUsers
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showResultsBeforeSearchingNotification"), object: nil)
                self.searchActive = false
            }
        }
        
        setUpContactSections()
        self.tableView.reloadData()
    }
    
    func presentPhoneNumberRequestAlert() {
        phoneAlert = UIAlertController(title: "Be Found!", message: "You are currently only able to be found by your email address. Add your phone number so that your contacts can better find you.", preferredStyle: .alert)
        
        phoneAlert.addTextField { (textField) in
            textField.placeholder = "Example: 555-555-5555"
            textField.keyboardType = UIKeyboardType.numberPad
            textField.delegate = self
        }
        
        phoneAlert.addAction(UIAlertAction(title: "Save Number", style: .default, handler: { [weak phoneAlert] (_) in
            if let textField = phoneAlert?.textFields![0] {
                if let number = textField.text {
                    if number.count == 12 {
                        self.userRef.child("userPhone").setValue(number)
                        Animations().showPopup(labelText: "Saved!", presentingVC: self)
                        print("phone number: \(number)")
                    } else {
                        print("attempting to re-set message")
                        phoneAlert?.title = "Oops!"
                        phoneAlert?.message = "Please make sure that you enter your whole 10-digit phone number"
                        self.present(phoneAlert!, animated: true, completion: nil)
                    }
                }
            }
        }))
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        phoneAlert.addAction(cancelAction)
        
        self.present(phoneAlert, animated: true, completion: nil)
        phoneAlert.view.tintColor = UIColor.StyleFile.DarkGrayColor
        Loads.askedAboutPhone = true
        UserDefaults.standard.set(Loads.askedAboutPhone, forKey: "askedAboutPhone")
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == phoneAlert.textFields![0] {
            let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
            let components = newString.components(separatedBy: NSCharacterSet.decimalDigits.inverted)
            
            let decimalString = components.joined(separator: "") as NSString
            let length = decimalString.length
            let hasLeadingOne = length > 0 && decimalString.character(at: 0) == (1 as unichar)
            
            if length == 0 || (length > 10 && !hasLeadingOne) || length > 11
            {
                let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int
                return (newLength > 10) ? false : true
            }
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            if hasLeadingOne
            {
                formattedString.append("1 ")
                index += 1
            }
            if (length - index) > 3
            {
                let areaCode = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", areaCode)
                index += 3
            }
            if length - index > 3
            {
                let prefix = decimalString.substring(with: NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            
            let remainder = decimalString.substring(from: index)
            formattedString.append(remainder)
            textField.text = formattedString as String
            return false
        }
        else
        {
            return true
        }
    }
    
    @objc func handleNotification(_ notification: NSNotification) {
        DispatchQueue.main.async {
            self.loadCorrectView()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "contactAuthStatusDidChange"), object: nil)
        if isComposeSegue == false {
            if explicitDismiss == false {
                dismissView()
            }
        }
    }
}
