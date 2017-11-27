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
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var spotsLeftLabel: UILabel!
    var cnContacts = [CNContact]()
    
    // TEST DATA
    var imageNames = ["testCircleProfileImage1.pdf","testCircleProfileImage2.pdf","testCircleProfileImage3.pdf","testCircleProfileImage4.pdf","testCircleProfileImage5.pdf"]
    var names = ["Don Pedro","Donnie Burrito","Don Taco, Sr","Don Taco, Jr","Donny Doolittle"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if ContactsHandler().hasContactsAccess() {
            contactsNotAllowedView.isHidden = true
            doneButton.isHidden = false
            getContactsData()
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
//                explanationLabel.text = "Can't access contacts.  Please go to Settings -> MyApp to enable contact permission"
                print("didn't have access to contacts")
                return
            }
            
            let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey,CNContactEmailAddressesKey,CNContactImageDataKey,CNContactImageDataAvailableKey,CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            
            do {
                try store.enumerateContacts(with: request){
                    (contact, cursor) -> Void in
                    self.cnContacts.append(contact)
                }
            } catch let error {
                NSLog("Fetch contact error: \(error)")
            }
            
            NSLog(">>>> Contact list:")
            for contact in self.cnContacts {
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
        return names.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addCircleMemberCell", for: indexPath) as! AddCircleMemberTableViewCell
        cell.profileImageView.image = UIImage(named: imageNames[indexPath.row])
        cell.fullNameLabel.text = names[indexPath.row]
        cell.inviteButton.tag = indexPath.row
        cell.inviteButton.addTarget(self, action: #selector(sendInvite(sender:)), for: .touchUpInside)
        return cell
    }
    
    @objc func sendInvite(sender: UIButton){
        let buttonTag = sender.tag
        let indexPath = NSIndexPath(row: buttonTag, section: 0)
        let cell = tableView.cellForRow(at: indexPath as IndexPath) as! AddCircleMemberTableViewCell
        cell.inviteButton.isHidden = true
        cell.inviteSentButton.isHidden = false
    
        print("row number: \(buttonTag)")
    }
    
    
}
