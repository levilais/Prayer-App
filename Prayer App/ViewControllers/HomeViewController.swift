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
    var membershipPrayers = [CirclePrayer]()
    var cleanData = [String:[Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification2(_:)), name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification3(_:)), name: NSNotification.Name(rawValue: "membershipUserDidSet"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification4(_:)), name: NSNotification.Name(rawValue: "membershipPrayersUpdated"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "clearContentOnLogOut"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification5(_:)), name: NSNotification.Name(rawValue: "clearContentOnLogOut"), object: nil)
        
        
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
        var title = String()
        let sectionKey = Array(cleanData.keys)[section] as String
        switch sectionKey {
        case "invitationUsers":
            title = "Action Items"
        case "membershipPrayers":
            title = "Circle Prayers"
        default:
            break
        }
        return title
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return cleanData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowCount = Int()
        
        let sectionTitles = Array(cleanData.keys) as [String]
        let section = sectionTitles[section]
        if let objectArray = cleanData[section] {
            rowCount = objectArray.count
        }
        
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let sectionTitles = Array(cleanData.keys) as [String]
        let section = sectionTitles[indexPath.section]
        
        switch section {
        case "invitationUsers":
            print("invitation cell")
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
        case "membershipPrayers":
            print("membership cell")
            let cell = tableView.dequeueReusableCell(withIdentifier: "circlePrayerCell", for: indexPath) as! CirclePrayerTableViewCell
            if let prayerArray = cleanData["membershipPrayers"] as? [CirclePrayer] {
                let prayer = prayerArray[indexPath.row]
                if let firstName = prayer.firstName {
                    if let lastName = prayer.lastName {
                        let fullName = firstName + " " + lastName
                        cell.fullNameLabel.text = fullName
                        if let prayerText = prayer.prayerText {
                            cell.prayerTextLabel.text = prayerText
                        }
                    }
                }
                if let ownerUserID = prayer.prayerOwnerUserID {
                    for membershipUser in CurrentUser.firebaseMembershipUsers {
                        if let memberUserID = membershipUser.userID {
                            if ownerUserID == memberUserID {
                                if let profileImage = membershipUser.profileImageAsImage {
                                    cell.profileImageView.image = profileImage
                                }
                                if let membershipUserCircleUserProfileImages = membershipUser.membershipUserCircleImages {
                                    print("HomeViewController Stage 6")
                                    if membershipUserCircleUserProfileImages.count > 0 {
                                        var i = 0
                                        for pImageView in cell.senderPrayerCircleMembers {
                                            if i < membershipUserCircleUserProfileImages.count {
                                                pImageView.image = membershipUserCircleUserProfileImages[i]
                                                pImageView.isHidden = false
                                                cell.senderPrayerCircleMembersTintImage[i].isHidden = false
                                            } else {
                                                pImageView.isHidden = true
                                                cell.senderPrayerCircleMembersTintImage[i].isHidden = true
                                            }
                                            i += 1
                                        }
                                    } else {
                                        for pImageView in cell.senderPrayerCircleMembers {
                                            pImageView.isHidden = true
                                        }
                                        for imageTint in cell.senderPrayerCircleMembersTintImage {
                                            imageTint.isHidden = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return cell
        default:
            let cell = UITableViewCell()
            return cell
        }
    }
    
    @objc func acceptInvite(sender: CellButton) {
        let buttonTag = sender.tag
        let buttonSection = sender.section
        let indexPath = NSIndexPath(row: buttonTag, section: buttonSection)
        let memberUser = invitationUsers[indexPath.row]
        if let memberEmail = memberUser.userEmail {
            FirebaseHelper().acceptInvite(userEmail: memberEmail, ref: ref)
        }
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
        loadData()
        print("cleanData when invites updated: \(cleanData)")
    }
    
    @objc func handleNotification4(_ notification: NSNotification) {
       loadData()
        print("cleanData when prayers updated: \(cleanData)")
    }
    
    @objc func handleNotification5(_ notification: NSNotification) {
        loadData()
        print("clear data because logout was called")
    }
    
    func loadData() {
        self.cleanData = [:]
        self.invitationUsers = []
        self.membershipPrayers = []

        var matchDetermined = false
        while matchDetermined == false {
            for user in CurrentUser.firebaseMembershipUsers {
                if let membershipStatus = user.membershipStatus {
                    if membershipStatus == MembershipUser.currentUserMembershipStatus.invited.rawValue {
                        self.invitationUsers.append(user)
                        matchDetermined = true
                    }
                }
            }
            matchDetermined = true
        }
        
        for prayer in CurrentUser.membershipCirclePrayers {
            self.membershipPrayers.append(prayer)
        }
        
        if self.invitationUsers.count > 0 {
            self.cleanData["invitationUsers"] = self.invitationUsers
        }
    
        if self.membershipPrayers.count > 0 {
            self.cleanData["membershipPrayers"] = self.membershipPrayers
        }
        
        DispatchQueue.main.async {
            self.showHideTable()
            self.tableView.reloadData()
        }
    }
    
    func showHideTable() {
        if self.cleanData.count > 0 {
            self.tableView.isHidden = false
            self.messageLabel.isHidden = true
        } else {
            self.tableView.isHidden = true
            self.messageLabel.isHidden = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "membershipUserDidSet"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "membershipPrayersUpdated"), object: nil)
    }

}
