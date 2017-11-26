//
//  CirclesViewController.swift
//  Prayer App
//
//  Created by Levi on 11/16/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import Firebase
import Contacts
import ContactsUI

class CirclesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // TITLE/HEADER
    @IBOutlet weak var titleImage: UIImageView!
    @IBOutlet weak var timerHeaderButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    
    // NOT LOGGED IN VIEW
    @IBOutlet weak var userNotLoggedInView: UIView!
    @IBOutlet weak var explanationLabel: UILabel!
    var hasContactAccess = false
    var showSignUp = true
    
    // LOGGED IN VIEW
    @IBOutlet var circleProfileImageButtons: [UIButton]!
    @IBOutlet weak var circleNameLabel: UILabel!
    @IBOutlet weak var circleJoinedLabel: UILabel!
    @IBOutlet weak var circleAgreedLabel: UILabel!
    @IBOutlet weak var circleAgreedCountLabel: UILabel!
    @IBOutlet weak var deleteFromCircleButton: UIButton!
    @IBOutlet weak var userLoggedInView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var circleSpotFilled = [Bool]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        for circleButton in circleProfileImageButtons {
            circleButton.addTarget(self, action: #selector(circleProfileButtonDidPress(sender:)), for: .touchUpInside)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        getCircleData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification2(_:)), name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        TimerStruct().showTimerIfRunning(timerHeaderButton: timerHeaderButton, titleImage: titleImage)
        
        if Auth.auth().currentUser != nil {
            print("Logged in and has has contacts access")
            userNotLoggedInView.isHidden = true
            userLoggedInView.isHidden = false
            // present loggin in screen showing circles and posts
        } else {
            userNotLoggedInView.isHidden = false
            userLoggedInView.isHidden = true
            print("Not logged in and doesn't have contacts access")
        }
        
    }
    
    @objc func circleProfileButtonDidPress(sender: UIButton) {
        let tag = sender.tag
        if tag < 5 {
//            ContactsHandler().launchPickerView(vc: self)
            self.performSegue(withIdentifier: "selectCircleMembersSegue", sender: self)
        }
    }
    
    func getCircleData() {
        print("tried to get circle data")
        let circleUsers = CurrentUser.circleMembers
        print("was able to get users array")
        print(circleUsers)
        for circleUser in circleUsers {
            if let firstName = circleUser.firstName {
                print(firstName)
            }
        }
    }
    
    @IBAction func timerButtonDidPress(_ sender: Any) {
        TimerStruct().stopTimer(timerButton: timerHeaderButton, titleImageView: titleImage)
    }
    
    @IBAction func loginButtonDidPress(_ sender: Any) {
        showSignUp = false
        performSegue(withIdentifier: "loginSignUpSegue", sender: sender)
    }
    
    @IBAction func createAccountButtonDidPress(_ sender: Any) {
        showSignUp = true
        performSegue(withIdentifier: "loginSignUpSegue", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "loginSignUpSegue") {
            let loginViewController = segue.destination as! LoginViewController
            loginViewController.signupShowing = showSignUp
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
        return "My Active Circle Posts"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "prayerCell", for: indexPath) as! PrayerTableViewCell
        
        cell.prayerTextView.text = "placeholder text"
        cell.prayedLastLabel.text = "prayed last"
        cell.prayedCountLabel.text = "prayer count"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .default, title: "Delete") { (action:UITableViewRowAction, indexPath:IndexPath) in
            print("delete at:\(indexPath)")
//            let prayer = self.fetchedResultsController.object(at: indexPath)
//            prayer.managedObjectContext?.delete(prayer)
//            print("attempting to delete")
//            do {
//                try prayer.managedObjectContext?.save()
//                print("saved!")
//                tableView.reloadData()
//            } catch let error as NSError  {
//                print("Could not save \(error), \(error.userInfo)")
//            } catch {
//            }
        }
        delete.backgroundColor = UIColor.StyleFile.WineColor
            let answered = UITableViewRowAction(style: .default, title: "Answered") { (action:UITableViewRowAction, indexPath:IndexPath) in
//                self.indexPathToMarkAnswered = indexPath
//                Animations().animateMarkAnsweredPopup(view: self.markAnsweredPopoverView, backgroundButton: self.markAnsweredBackgroundButton, subView: self.markAnsweredSubview, viewController: self, textView: self.markAnsweredTextView)
                print("answered at:\(indexPath)")
        }
        answered.backgroundColor = UIColor.StyleFile.DarkBlueColor
        return [delete, answered]
    }
    
    @objc func handleNotification(_ notification: NSNotification) {
        TimerStruct().updateTimerButtonLabel(timerButton: timerHeaderButton)
         print("Circles timer update called")
    }
    
    @objc func handleNotification2(_ notification: NSNotification) {
        Animations().endTimerAnimation(timerButton: timerHeaderButton, titleImage: titleImage)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
    }
}
