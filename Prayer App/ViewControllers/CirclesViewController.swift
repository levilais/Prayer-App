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
    @IBOutlet var circleProfileImages: [UIImageView]!
    @IBOutlet var circleProfileImageButtons: [UIButton]!
    @IBOutlet weak var circleNameLabel: UILabel!
    @IBOutlet weak var circleJoinedLabel: UILabel!
    @IBOutlet weak var circleAgreedLabel: UILabel!
    @IBOutlet weak var circleAgreedCountLabel: UILabel!
    @IBOutlet weak var deleteFromCircleButton: UIButton!
    @IBOutlet weak var userLoggedInView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var circleSpotFilled = [false,false,false,false,false]
    var selectedCircleMember = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for circleButton in circleProfileImageButtons {
            circleButton.addTarget(self, action: #selector(circleProfileButtonDidPress(sender:)), for: .touchUpInside)
        }

        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        print("CurrentUser.firebaseCircleMembers.count: \(CurrentUser.firebaseCircleMembers.count)")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification2(_:)), name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        TimerStruct().showTimerIfRunning(timerHeaderButton: timerHeaderButton, titleImage: titleImage)
        
        if Auth.auth().currentUser != nil {
            userNotLoggedInView.isHidden = true
            userLoggedInView.isHidden = false
            setCircleData()
        } else {
            userNotLoggedInView.isHidden = false
            userLoggedInView.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        for button in circleProfileImageButtons {
            button.layer.cornerRadius = button.frame.size.height / 2
            button.clipsToBounds = true
        }
        
        for imageView in circleProfileImages {
            imageView.layer.cornerRadius = imageView.frame.size.height / 2
            imageView.clipsToBounds = true
        }
    }
    
    @objc func circleProfileButtonDidPress(sender: UIButton) {
        let tag = sender.tag
        if circleSpotFilled[tag] {
            toggleCircleMemberDetailContent(buttonTag: tag)
            selectedCircleMember = tag
        } else {
            self.performSegue(withIdentifier: "selectCircleMembersSegue", sender: self)
        }
    }
    
    func toggleCircleMemberDetailContent(buttonTag: Int) {
        if CurrentUser.firebaseCircleMembers.count == 0 {
            circleNameLabel.text = "Tap above to send invitation"
            circleJoinedLabel.text = ""
            circleAgreedLabel.text = ""
            circleAgreedCountLabel.text = ""
            deleteFromCircleButton.isHidden = true
        } else {
            let circleUser = CurrentUser.firebaseCircleMembers[buttonTag]
            for button in circleProfileImageButtons {
                if button.tag != buttonTag && button.tag < CurrentUser.firebaseCircleMembers.count {
                    button.layer.backgroundColor = UIColor.StyleFile.TealColor.cgColor
                } else {
                    button.layer.backgroundColor = UIColor.clear.cgColor
                }
            }
            circleNameLabel.text = circleUser.getFullName(user: circleUser)
            circleJoinedLabel.text = "You are still waiting for your invitation to be accepted"
            circleAgreedLabel.text = ""
            circleAgreedCountLabel.text = ""
            deleteFromCircleButton.isHidden = false
        }
    }
     
//    func toggleCircleMemberDetailContent(buttonTag: Int) {
//        if CurrentUser.circleMembers.count == 0 {
//            circleNameLabel.text = "Tap above to send invitation"
//            circleJoinedLabel.text = ""
//            circleAgreedLabel.text = ""
//            circleAgreedCountLabel.text = ""
//            deleteFromCircleButton.isHidden = true
//        } else {
//            let circleUser = CurrentUser.circleMembers[buttonTag]
//            for button in circleProfileImageButtons {
//                if button.tag != buttonTag && button.tag < CurrentUser.circleMembers.count {
//                    button.layer.backgroundColor = UIColor.StyleFile.TealColor.cgColor
//                } else {
//                    button.layer.backgroundColor = UIColor.clear.cgColor
//                }
//            }
//            circleNameLabel.text = circleUser.getFullName(user: circleUser)
//            circleJoinedLabel.text = "You are still waiting for your invitation to be accepted"
//            circleAgreedLabel.text = ""
//            circleAgreedCountLabel.text = ""
//            deleteFromCircleButton.isHidden = false
//        }
//    }
    
//    func setCircleData() {
//        let circleUsers = CurrentUser.circleMembers
//        let circleCount = circleUsers.count
//
//        for i in 0...4 {
//            switch i {
//            case 0 ..< circleCount:
//                let circleUser = circleUsers[i]
//                circleProfileImages[i].image = UIImage(data: circleUser.profileImage!)
//                circleSpotFilled[i] = true
//            case circleCount ... 4:
//                circleProfileImages[i].image = UIImage(named: "addCircleMemberIcon.pdf")
//                circleSpotFilled[i] = false
//            default:
//                print("failure")
//            }
//        }
//
//        for button in circleProfileImageButtons {
//            button.layer.cornerRadius = button.frame.size.height / 2
//            button.clipsToBounds = true
//        }
//
//        for imageView in circleProfileImages {
//            imageView.layer.cornerRadius = imageView.frame.size.height / 2
//            imageView.clipsToBounds = true
//        }
//        toggleCircleMemberDetailContent(buttonTag: selectedCircleMember)
//    }
    
    func setCircleData() {
        let circleUsers = CurrentUser.firebaseCircleMembers
        let circleCount = circleUsers.count
        
        for i in 0...4 {
            switch i {
            case 0 ..< circleCount:
                let circleUser = circleUsers[i]
                if let image = circleUser.profileImageAsUIImage {
                    circleProfileImages[i].image = image
                }
                circleSpotFilled[i] = true
            case circleCount ... 4:
                circleProfileImages[i].image = UIImage(named: "addCircleMemberIcon.pdf")
                circleSpotFilled[i] = false
            default:
                print("failure")
            }
        }
        
        toggleCircleMemberDetailContent(buttonTag: 0)
    }

    
    @IBAction func deleteCircleMemberDidPress(_ sender: Any) {
        print("circleMember.count before: \(CurrentUser.circleMembers.count)")
        let alert = UIAlertController(title: "Are you sure", message: "Are you sure you want to remove this Circle Member", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Yes, I'm sure", style: .default) { (action) in
            CurrentUser.circleMembers.remove(at: self.selectedCircleMember)
            self.circleSpotFilled[self.selectedCircleMember] = false
            self.selectedCircleMember = 0
            print("circleMember.count after: \(CurrentUser.circleMembers.count)")
            self.setCircleData()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true) {
            print("completed alert")
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
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
