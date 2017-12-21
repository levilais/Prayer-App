//
//  SettingsDetailViewController.swift
//  Prayer App
//
//  Created by Levi on 11/21/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import Firebase
import Contacts
import ContactsUI

class SettingsDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleImage: UIImageView!
    @IBOutlet weak var timerHeaderButton: UIButton!
    
    var sectionPassedFromParentView = Int()
    var chosenSection = Int()
    var actionType = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification2(_:)), name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        TimerStruct().showTimerIfRunning(timerHeaderButton: timerHeaderButton, titleImage: titleImage)
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = Int()
        
        let chosenCategory = Settings().settingsCategories[chosenSection]
        
        if let categoryArray = chosenCategory["subCategories"] {
            count = (categoryArray as AnyObject).count
        }
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var labelText = String()
        
        let category = Settings().settingsCategories[chosenSection]
        if let subCategories = category["subCategories"] as? [AnyObject] {
            if let subCategory = subCategories[indexPath.row] as? [String:AnyObject] {
                if let subTitle = subCategory["subTitle"] as? String {
                    labelText = subTitle
                }
                if let actionTypeCheck = subCategory["actionType"] as? Int {
                    actionType = actionTypeCheck
                }
            }
        }
        
        var labelString = labelText
        var cellToReturn = UITableViewCell()
        
        switch actionType {
        case 0:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "settingsToggleCell", for: indexPath) as? SettingsToggleTableViewCell {
                
                if labelText == "Log In" {
                    cell.settingsToggle.addTarget(self, action: #selector(logInLogOut), for: .touchUpInside)
                    if Auth.auth().currentUser != nil {
                        labelString = "Log Out Of Prayer"
                        cell.settingsToggle.setOn(true, animated: true)
                    } else {
                        labelString = "Log In To Prayer"
                        cell.settingsToggle.setOn(false, animated: true)
                    }
                } else if labelText == "Connect To Contacts" {
                    cell.settingsToggle.addTarget(self, action: #selector(allowContactsAccess(toggleSwitch:)), for: .touchUpInside)
                    if ContactsHandler().contactsAuthStatus() == ".authorized" {
                        labelString = "Connected To Contacts"
                        cell.settingsToggle.setOn(true, animated: true)
                    } else {
                        labelString = "Connect To Contacts"
                        cell.settingsToggle.setOn(false, animated: true)
                    }
                }
                
                cell.label.text = labelString
                cellToReturn = cell
            }
        case 1:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "settingsButtonCell", for: indexPath) as? SettingsButtonTableViewCell {
                cell.label.text = labelString
                cellToReturn = cell
            }
        case 2:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath) as? SettingsTableViewCell {
                
                cell.label.text = labelString
                cellToReturn = cell
            }
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cellToReturn = cell
        }
        return cellToReturn
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let category = Settings().settingsCategories[chosenSection]
        if let subCategories = category["subCategories"] as? [AnyObject] {
            if let subCategory = subCategories[indexPath.row] as? [String:AnyObject] {
                if let subTitle = subCategory["subTitle"] as? String {
                    if subTitle == "Edit Profile" {
                        if Auth.auth().currentUser != nil {
                            performSegue(withIdentifier: "settingsDetailToUpdateProfileSegue", sender: self)
                        } else {
                            performSegue(withIdentifier: "settingsToLoginSegue", sender: nil)
                        }
                    }
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func doneButtonDidPress(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func logInLogOut() {
        if Auth.auth().currentUser != nil {
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
                CurrentUser.firebaseCircleMembers.removeAll()
                CurrentUser.firebaseMembershipUsers.removeAll()
                FirebaseHelper.firebaseUserEmails.removeAll()
                tableView.reloadData()
            } catch let signOutError as NSError {
                Utilities().showAlert(title: "Error", message: signOutError.localizedDescription, vc: self)
            }
        } else {
            performSegue(withIdentifier: "settingsToLoginSegue", sender: nil)
        }
        self.tableView.reloadData()
    }
    
    @objc func allowContactsAccess(toggleSwitch: UISwitch) {
        if ContactsHandler().contactsAuthStatus() == ".authorized" {
            let alert = UIAlertController(title: "Instructions", message: "In order to disconnect the Prayer app from your Contacts, you'll need to go to Settings > Privacy > Contacts > Prayer", preferredStyle: .alert)
            let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: {
                toggleSwitch.setOn(true, animated: true)
            })
            alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
        } else {
            performSegue(withIdentifier: "settingsDetailToContactsAuth", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "settingsDetailToContactsAuth" {
            let toViewController = segue.destination as! SelectContactsViewController
            toViewController.segueFromSettings = true
        }
    }

    
    
    @IBAction func timerHeaderButtonDidPress(_ sender: Any) {
        TimerStruct().stopTimer(timerButton: timerHeaderButton, titleImageView: titleImage)
    }
    
    @objc func handleNotification(_ notification: NSNotification) {
        TimerStruct().updateTimerButtonLabel(timerButton: timerHeaderButton)
    }
    
    @objc func handleNotification2(_ notification: NSNotification) {
        Animations().endTimerAnimation(timerButton: timerHeaderButton, titleImage: titleImage)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
    }
}
