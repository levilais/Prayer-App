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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification2(_:)), name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification3(_:)), name: NSNotification.Name(rawValue: "membershipUserAdded"), object: nil)
        
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
                // reload data here
            }
//            ref.child("users").child(userID).child("prayers").observe(.childRemoved) { (snapshot) in
//                if let userDictionary = snapshot.value as? NSDictionary {
//                    let snapshotPrayer = FirebaseHelper().prayerFromDictionary(userDictionary: userDictionary)
//                    var i = 0
//                    for prayer in self.preSortedPrayers {
//                        if let prayerID = prayer.prayerID {
//                            if let snapshotPrayerID = snapshotPrayer.prayerID {
//                                if prayerID == snapshotPrayerID {
//                                    self.preSortedPrayers.remove(at: i)
//                                }
//                            }
//                        }
//                        i += 1
//                    }
//                    // reload data here
//                }
//            }
            
//            ref.child("users").child(userID).child("prayers").observe(.childChanged) { (snapshot) in
//                if let userDictionary = snapshot.value as? NSDictionary {
//                    let snapshotPrayer = FirebaseHelper().prayerFromDictionary(userDictionary: userDictionary)
//                    var i = 0
//                    for prayer in self.preSortedPrayers {
//                        if let prayerID = prayer.prayerID {
//                            if let snapshotPrayerID = snapshotPrayer.prayerID {
//                                if prayerID == snapshotPrayerID {
//                                    self.preSortedPrayers[i] = snapshotPrayer
//                                }
//                            }
//                        }
//                        i += 1
//                    }
//                }
//                // reload data here
//            }
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
        return CurrentUser.firebaseMembershipUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "invitationCell", for: indexPath) as! CircleInvitationTableViewCell
        
        let membershipUser = CurrentUser.firebaseMembershipUsers[indexPath.row]
        
        if let image = membershipUser.profileImageAsImage {
            cell.profileImage.image = image
        }
        
        if let currentUserFirstName = CurrentUser.currentUser.firstName {
            let name = User().getFullName(user: membershipUser)
            cell.invitationLabel.text = "\(currentUserFirstName), \(name) has invited you to be one of their 5 Prayer Circle members."
            cell.nameLabel.text = name
        }
        if let dateInvitedString = membershipUser.dateInvited {
            cell.invitationSinceLabel.text = "Request sent \(Utilities().dayDifference(timeStampAsDouble: dateInvitedString))"
        }
        
        return cell
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
            self.tableView.reloadData()
            self.tableView.isHidden = false
            self.messageLabel.isHidden = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "membershipUserAdded"), object: nil)
    }

}
