//
//  SettingsDetailViewController.swift
//  Prayer App
//
//  Created by Levi on 11/21/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import Firebase

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
        print("chosenSection: \(chosenSection)")
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
                        print("is current user")
                        labelString = "Log Out Of Prayer"
                        cell.settingsToggle.setOn(true, animated: true)
                    } else {
                        print("is not current user")
                        labelString = "Log In To Prayer"
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
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func doneButtonDidPress(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func logInLogOut() {
        print("logInLogOut fired")
        if Auth.auth().currentUser != nil {
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
                tableView.reloadData()
            } catch let signOutError as NSError {
                Utilities().showAlert(title: "Error", message: signOutError.localizedDescription, vc: self)
            }
        } else {
            performSegue(withIdentifier: "settingsToLoginSegue", sender: nil)
        }
        self.tableView.reloadData()
    }
    
    @objc func allowContactsAccess() {
        print("allow contacts access switched")
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
