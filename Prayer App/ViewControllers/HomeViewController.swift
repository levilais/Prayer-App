//
//  HomeViewController.swift
//  Prayer App
//
//  Created by Levi on 11/16/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import Firebase

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var titleImage: UIImageView!
    @IBOutlet weak var timerHeaderButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var userNotLoggedInView: UIView!
    @IBOutlet weak var userLoggedInView: UIView!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageLabel: UILabel!
    
    var showSignUp = true
    var ref: DatabaseReference!
    var invitationUsers = [MembershipUser]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification2(_:)), name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification3(_:)), name: NSNotification.Name(rawValue: "membershipUserDidSet"), object: nil)
        
        TimerStruct().showTimerIfRunning(timerHeaderButton: timerHeaderButton, titleImage: titleImage)
        if Auth.auth().currentUser != nil {
            userNotLoggedInView.isHidden = true
            userLoggedInView.isHidden = false
        } else {
            userNotLoggedInView.isHidden = false
            userLoggedInView.isHidden = true
        }
        
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        
        setupObservers()
        greetingLabel.text = "Prayerline"
    }
    
    func setupObservers() {
        if let userID = Auth.auth().currentUser?.uid {
            ref.child("users").child(userID).child("memberships").observe(.childAdded) { (snapshot) in
                if let userDictionary = snapshot.value as? NSDictionary {
                    FirebaseHelper().addNewConnectionToCurrentUserMemberships(userDictionary: userDictionary)
                }
                // reload data here if necessary
            }
        
            
            ref.child("users").child(userID).child("memberships").observe(.childChanged) { (snapshot) in
                if let userDictionary = snapshot.value as? NSDictionary {
                    let snapshotMembershipUser = FirebaseHelper().membershipUserFromDictionary(userDictionary: userDictionary)
                    var i = 0
                    for user in CurrentUser.firebaseMembershipUsers {
                        if let userID = user.userID {
                            if let snapshotUserID = snapshotMembershipUser.userID {
                                if userID == snapshotUserID {
                                    CurrentUser.firebaseMembershipUsers[i] = snapshotMembershipUser
                                }
                            }
                        }
                        i += 1
                    }
                }
                // reload data here if necessary
            }
        
    
  
            ref.child("users").child(userID).child("memberships").observe(.childRemoved) { (snapshot) in
                if let userDictionary = snapshot.value as? NSDictionary {
                    let snapshotMembershipUser = FirebaseHelper().membershipUserFromDictionary(userDictionary: userDictionary)
                    var i = 0
                    for user in CurrentUser.firebaseMembershipUsers {
                        if let userID = user.userID {
                            if let snapshotUserID = snapshotMembershipUser.userID {
                                if userID == snapshotUserID {
                                    CurrentUser.firebaseMembershipUsers.remove(at: i)
                                    print("removedMember at: \(i)")
                                }
                            }
                        }
                        i += 1
                    }
                    // reload data here
                }
            }
        }
    }

    func loadHomeScreenData() {
        
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
        return "Action Items"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return invitationUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "invitationCell", for: indexPath) as! CircleInvitationTableViewCell
        let membershipUser = invitationUsers[indexPath.row]
        
        if let membershipStatus = membershipUser.membershipStatus {
            if membershipStatus == MembershipUser.currentUserMembershipStatus.invited.rawValue {
                if let image = membershipUser.profileImageAsImage {
                    cell.profileImage.image = image
                }
                
                if let currentUserFirstName = CurrentUser.currentUser.firstName {
                    let name = User().getFullName(user: membershipUser)
                    cell.invitationLabel.text = "\(currentUserFirstName), \(name) has invited you to be one of their 5 Prayer Circle members.  Would you like to accept their invitation?"
                    cell.nameLabel.text = name
                }
                if let dateInvitedString = membershipUser.dateInvited {
                    cell.invitationSinceLabel.text = "Request sent \(Utilities().dayDifference(timeStampAsDouble: dateInvitedString))"
                }
                
                cell.acceptButton.tag = indexPath.row
                cell.acceptButton.section = indexPath.section
                cell.acceptButton.addTarget(self, action: #selector(acceptInvite(sender:)), for: .touchUpInside)
                cell.declineButton.tag = indexPath.row
                cell.declineButton.section = indexPath.section
                cell.declineButton.addTarget(self, action: #selector(declineInvite(sender:)), for: .touchUpInside)
            }
        }
        
        return cell
    }
    
    @objc func acceptInvite(sender: CellButton) {
        let buttonTag = sender.tag
        let buttonSection = sender.section
        let indexPath = NSIndexPath(row: buttonTag, section: buttonSection)
        let memberUser = invitationUsers[indexPath.row]
        if let memberEmail = memberUser.userEmail {
            FirebaseHelper().acceptInvite(userEmail: memberEmail, ref: ref)
        }
        
//        let cell = tableView.cellForRow(at: indexPath as IndexPath) as! CircleInvitationTableViewCell
    }
    
    @objc func declineInvite(sender: CellButton) {
        let buttonTag = sender.tag
        let buttonSection = sender.section
        let indexPath = NSIndexPath(row: buttonTag, section: buttonSection)
        let memberUser = invitationUsers[indexPath.row]
        if let memberEmail = memberUser.userEmail {
            FirebaseHelper().declineInvite(userEmail: memberEmail, ref: ref)
        }
//        let cell = tableView.cellForRow(at: indexPath as IndexPath) as! CircleInvitationTableViewCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction func timerButtonDidPress(_ sender: Any) {
        TimerStruct().stopTimer(timerButton: timerHeaderButton, titleImageView: titleImage)
    }
    
    @IBAction func signUpDidPress(_ sender: Any) {
        showSignUp = true
        performSegue(withIdentifier: "loginSignUpSegue", sender: sender)
    }
    
    @IBAction func loginDidPress(_ sender: Any) {
        showSignUp = false
        performSegue(withIdentifier: "loginSignUpSegue", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "loginSignUpSegue") {
            let loginViewController = segue.destination as! LoginViewController
            loginViewController.signupShowing = showSignUp
        }
    }
    
    @objc func handleNotification(_ notification: NSNotification) {
        TimerStruct().updateTimerButtonLabel(timerButton: timerHeaderButton)
    }
    
    @objc func handleNotification2(_ notification: NSNotification) {
        Animations().endTimerAnimation(timerButton: timerHeaderButton, titleImage: titleImage)
    }
    
    @objc func handleNotification3(_ notification: NSNotification) {
        DispatchQueue.main.async {
            
            self.invitationUsers = []
            print("1")
            var matchDetermined = false
            print("2")
            while matchDetermined == false {
                print("3")
                for user in CurrentUser.firebaseMembershipUsers {
                    print("4")
                    if let membershipStatus = user.membershipStatus {
                        print("5")
                        if membershipStatus == MembershipUser.currentUserMembershipStatus.invited.rawValue {
                            print("6")
                            self.invitationUsers.append(user)
                            print("7")
                            matchDetermined = true
                        }
                    }
                }
                print("8")
                matchDetermined = true
            }
            if self.invitationUsers.count > 0 {
                print("9")
                self.tableView.isHidden = false
                self.messageLabel.isHidden = true
            } else {
                print("10")
                self.tableView.isHidden = true
                self.messageLabel.isHidden = false
            }
            print("11")
            self.tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "membershipUserDidSet"), object: nil)
    }

}
