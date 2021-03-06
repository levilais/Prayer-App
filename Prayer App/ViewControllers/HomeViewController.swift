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
    @IBOutlet weak var refreshButton: UIButton!
    
    var showSignUp = true
    var viewIsVisible = false
    var ref: DatabaseReference!
    var userRef: DatabaseReference!
    var dataFirstLoaded = false
    
    var preSortedData = [AnyObject]()
    
    var invitationUsers = [MembershipUser]()
    var membershipPrayers = [MembershipPrayer]()
    var prayerQueue = [MembershipPrayer]()
    var cleanData = [String:[Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        viewIsVisible = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification2(_:)), name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification3(_:)), name: NSNotification.Name(rawValue: "membershipUserDidSet"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "clearContentOnLogOut"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification4(_:)), name: NSNotification.Name(rawValue: "clearContentOnLogOut"), object: nil)
        
        
        TimerStruct().showTimerIfRunning(timerHeaderButton: timerHeaderButton, titleImage: titleImage)
        if let userID = Auth.auth().currentUser?.uid {
            userNotLoggedInView.isHidden = true
            userLoggedInView.isHidden = false
            userRef = Database.database().reference().child("users").child(userID)
            self.setupObservers()
        } else {
            userNotLoggedInView.isHidden = false
            userLoggedInView.isHidden = true
        }
        
        tableView.rowHeight = UITableViewAutomaticDimension
        
        self.loadData()
        refreshTable()
        greetingLabel.text = "Prayerline"
    }
    
    func firstLoad(completed: @escaping (Bool) -> Void) {
        userRef.child("memberships").observeSingleEvent(of: .value, with: { (snapshot) -> Void in
            var newMembershipUsers = [MembershipUser]()
            for membershipSnap in snapshot.children {
                let newMembershipUser = MembershipUser().membershipUserFromSnapshot(snapshot: membershipSnap as! DataSnapshot)
                newMembershipUsers.append(newMembershipUser)
            }
            CurrentUser.firebaseMembershipUsers = newMembershipUsers
            self.loadData()
            self.refreshTable()
            completed(true)
        })
    }
    
    func setupObservers() {
        firstLoad { (success) in
            self.userRef.child("memberships").observe(.childAdded, with: { (snapshot) -> Void in
                let newMembershipUser = MembershipUser().membershipUserFromSnapshot(snapshot: snapshot)
                var matchExists = false
                for membershipUser in CurrentUser.firebaseMembershipUsers {
                    if let membershipUserKey = membershipUser.key {
                        if let newMembershipUserKey = newMembershipUser.key {
                            if membershipUserKey == newMembershipUserKey {
                                matchExists = true
                            }
                        }
                    }
                }
                if matchExists == false {
                    CurrentUser.firebaseMembershipUsers.append(newMembershipUser)
                    if self.viewIsVisible {
                        self.showRefreshButton()
                    } else {
                        self.loadData()
                        self.refreshTable()
                        self.tableView.scrollsToTop = true
                    }
                }
            })
            
            self.userRef.child("memberships").observe(.childRemoved, with: { (snapshot) -> Void in
                let removedMembershipUser = MembershipUser().membershipUserFromSnapshot(snapshot: snapshot)
                if let removedMembershipUserKey = removedMembershipUser.key {
                    var i = 0
                    for membershipUser in CurrentUser.firebaseMembershipUsers {
                        if let key = membershipUser.key {
                            if removedMembershipUserKey == key {
                                CurrentUser.firebaseMembershipUsers.remove(at: i)
                            }
                        }
                        i += 1
                    }
                }
                self.loadData()
                self.refreshTable()
            })
            
            self.userRef.child("memberships").observe(.childChanged, with: { (snapshot) -> Void in
                let changedMembershipUser = MembershipUser().membershipUserFromSnapshot(snapshot: snapshot)
                if let changedMembershipUserKey = changedMembershipUser.key {
                    var i = 0
                    for membershipUser in CurrentUser.firebaseMembershipUsers {
                        if let key = membershipUser.key {
                            if changedMembershipUserKey == key {
                                CurrentUser.firebaseMembershipUsers[i] = changedMembershipUser
                                self.loadData()
                                self.refreshTable()
                            }
                        }
                        i += 1
                    }
                }
            })
            self.setupMembershipPrayerObservers()
        }
    }
    
    func membershipPrayersFirstLoad(completed: @escaping (Bool) -> Void) {
        CurrentUser.firebaseMembershipPrayers.removeAll()
        for membershipUser in CurrentUser.firebaseMembershipUsers {
            if let membershipStatus = membershipUser.membershipStatus {
                if membershipStatus == MembershipUser.currentUserMembershipStatus.member.rawValue {
                    if let membershipUserCirclePrayersRef = membershipUser.membershipUserCirclePrayersRef {
                        membershipUserCirclePrayersRef.observeSingleEvent(of: .value, with: { (snapshot) -> Void in
                            for membershipPrayerSnap in snapshot.children {
                                let newMembershipPrayer = MembershipPrayer().membershipPrayerFromSnapshot(snapshot: membershipPrayerSnap as! DataSnapshot)
                                CurrentUser.firebaseMembershipPrayers.append(newMembershipPrayer)
                            }
                            self.loadData()
                            self.refreshTable()
                            completed(true)
                        })
                    }
                }
            }
        }
    }
    
    func setupMembershipPrayerObservers() {
        self.membershipPrayersFirstLoad(completed: { (success) in
            for membershipUser in CurrentUser.firebaseMembershipUsers {
                if let membershipStatus = membershipUser.membershipStatus {
                    if membershipStatus == MembershipUser.currentUserMembershipStatus.member.rawValue {
                        if let membershipUserCirclePrayersRef = membershipUser.membershipUserCirclePrayersRef {
                            membershipUserCirclePrayersRef.observe(.childAdded, with: { (snapshot) -> Void in
                                let newMembershipPrayer = MembershipPrayer().membershipPrayerFromSnapshot(snapshot: snapshot)
                                var matchExists = false
                                for membershipPrayer in CurrentUser.firebaseMembershipPrayers {
                                    if let prayerKey = membershipPrayer.key {
                                        if let newPrayerKey = newMembershipPrayer.key {
                                            if prayerKey == newPrayerKey {
                                                matchExists = true
                                            }
                                        }
                                    }
                                }
                                
                                for membershipPrayer in self.prayerQueue {
                                    if let prayerKey = membershipPrayer.key {
                                        if let newPrayerKey = newMembershipPrayer.key {
                                            if prayerKey == newPrayerKey {
                                                matchExists = true
                                            }
                                        }
                                    }
                                }
                                if matchExists == false {
                                    if self.viewIsVisible {
                                        self.prayerQueue.append(newMembershipPrayer)
                                        self.showRefreshButton()
                                    } else {
                                        CurrentUser.firebaseMembershipPrayers.append(newMembershipPrayer)
                                    }
                                }
                            })
                            membershipUserCirclePrayersRef.observe(.childRemoved, with: { (snapshot) -> Void in
                                let removedMembershipPrayer = MembershipPrayer().membershipPrayerFromSnapshot(snapshot: snapshot)
                                if let removedMembershipPrayerKey = removedMembershipPrayer.key {
                                    var i = 0
                                    for membershipPrayer in CurrentUser.firebaseMembershipPrayers {
                                        if let key = membershipPrayer.key {
                                            if removedMembershipPrayerKey == key {
                                                CurrentUser.firebaseMembershipPrayers.remove(at: i)
                                            }
                                        }
                                        i += 1
                                    }
                                }
                                self.loadData()
                                self.refreshTable()
                            })
                            membershipUserCirclePrayersRef.observe(.childChanged, with: { (snapshot) -> Void in
                                let changedMembershipPrayer = MembershipPrayer().membershipPrayerFromSnapshot(snapshot: snapshot)
                                if let changedMembershipPrayerKey = changedMembershipPrayer.key {
                                    var i = 0
                                    for membershipPrayer in CurrentUser.firebaseMembershipPrayers {
                                        if let key = membershipPrayer.key {
                                            if changedMembershipPrayerKey == key {
                                                CurrentUser.firebaseMembershipPrayers[i] = changedMembershipPrayer
                                                self.loadData()
                                                let indexPath = self.indexPathForPrayer(membershipPrayer: changedMembershipPrayer)
                                                if let cell = self.tableView.cellForRow(at: indexPath) as? CirclePrayerTableViewCell {
                                                    self.updatePrayerCellLabels(prayer: changedMembershipPrayer, cell: cell)
                                                }
                                            }
                                        }
                                        i += 1
                                    }
                                }
                            })
                        }
                    }
                }
            }
        })
    }
    
    func loadData() {
        var newInvitationUsers = [MembershipUser]()
        var matchDetermined = false
        while matchDetermined == false {
            for user in CurrentUser.firebaseMembershipUsers {
                if let membershipStatus = user.membershipStatus {
                    if membershipStatus == MembershipUser.currentUserMembershipStatus.invited.rawValue {
                        newInvitationUsers.append(user)
                        matchDetermined = true
                    }
                }
            }
            matchDetermined = true
        }
        self.invitationUsers = newInvitationUsers
        
        var newMembershipPrayers = [MembershipPrayer]()
        for prayer in CurrentUser.firebaseMembershipPrayers {
            newMembershipPrayers.append(prayer)
        }
        
        newMembershipPrayers.sort { $0.key! < $1.key! }
        self.membershipPrayers = newMembershipPrayers.reversed()
        
        var newCleanData = [String:[Any]]()
        if self.invitationUsers.count > 0 {
            newCleanData["invitationUsers"] = self.invitationUsers
        }
        
        if self.membershipPrayers.count > 0 {
            newCleanData["membershipPrayers"] = self.membershipPrayers
        }
        
        self.cleanData = newCleanData
    }
    
    func refreshTable() {
        DispatchQueue.main.async {
            self.showHideTable()
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
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
    
    @IBAction func refreshButtonDidPress(_ sender: Any) {
        for prayer in self.prayerQueue {
            CurrentUser.firebaseMembershipPrayers.append(prayer)
        }
        self.prayerQueue = []
        self.setupMembershipPrayerObservers()
        loadData()
        refreshTable()
        tableView.scrollsToTop = true
        hideRefreshButton()
    }
    
    func showRefreshButton() {
        refreshButton.isHidden = false
    }
    
    func hideRefreshButton() {
        refreshButton.isHidden = true
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "invitationCell", for: indexPath) as! CircleInvitationTableViewCell
            let membershipUser = invitationUsers[indexPath.row]
            
            if let membershipStatus = membershipUser.membershipStatus {
                if membershipStatus == MembershipUser.currentUserMembershipStatus.invited.rawValue {
                    if let image = membershipUser.profileImageAsImage {
                        cell.profileImage.image = image
                    } else {
                        cell.profileImage.image = UIImage(named: "settingsPrayerIcon.pdf")
                    }
                    
                    if let currentUserFirstName = CurrentUser.currentUser.firstName {
                        let name = CustomUser().getFullName(user: membershipUser)
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "circlePrayerCell", for: indexPath) as! CirclePrayerTableViewCell
            
            if let prayerArray = cleanData["membershipPrayers"] as? [MembershipPrayer] {
                let prayer = prayerArray[indexPath.row]
                
                updatePrayerCellLabels(prayer: prayer, cell: cell)

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
                            }
                        }
                    }
                }
                
                cell.agreeButton.tag = indexPath.row
                cell.agreeButton.section = indexPath.section
                cell.agreeButton.addTarget(self, action: #selector(markAgreed(sender:)), for: .touchUpInside)
            }
            return cell
        default:
            let cell = UITableViewCell()
            return cell
        }
    }
    
    func updatePrayerCellLabels(prayer: MembershipPrayer, cell: CirclePrayerTableViewCell) {
        if let agreedCount = prayer.agreedCount {
            if let firstName = prayer.firstName {
                cell.whoAgreedInPrayerLabel.text = "This prayer has been prayed \(Utilities().numberOfTimesString(count: agreedCount)) by \(firstName)'s Circle"
                cell.whoAgreedInPrayerLabel.textColor = UIColor.StyleFile.MediumGrayColor
            }
        }
        
        if let lastPrayedDate = prayer.lastPrayed {
            cell.prayerRequestedDate.text = "Last prayed \(Utilities().dayDifference(timeStampAsDouble: lastPrayedDate))"
            let lastPrayed = Utilities().dayDifference(timeStampAsDouble: lastPrayedDate)
            if lastPrayed == "today" {
                cell.prayerRequestedDate.textColor = UIColor.StyleFile.TealColor
                cell.prayerRequestedDate.font = UIFont.StyleFile.LastPrayedBold
                cell.prayerTextLabel.textColor = UIColor.StyleFile.MediumGrayColor
            } else {
                cell.prayerRequestedDate.textColor = UIColor.StyleFile.MediumGrayColor
                cell.prayerRequestedDate.font = UIFont.StyleFile.LastPrayedMedium
                cell.prayerTextLabel.textColor = UIColor.StyleFile.DarkGrayColor
            }
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var amenAction = UIContextualAction()
        amenAction = UIContextualAction(style: .normal, title:  "Amen", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            if let isConnected = ConnectionTracker.isConnected {
                if isConnected {
                    self.markPrayed(indexPath: indexPath)
                } else {
                    ConnectionTracker().presentNotConnectedAlert(messageDirections: "Marking a Prayer prayed requires an internet connection.  Please re-establish your internet connection and try again.", viewController: self)
                }
            }
            success(true)
        })
        amenAction.backgroundColor = UIColor.StyleFile.TealColor
        return UISwipeActionsConfiguration(actions: [amenAction])
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.none
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        var isPrayerCell = false
        let sectionTitles = Array(cleanData.keys) as [String]
        let section = sectionTitles[indexPath.section]
        if let objectArray = cleanData[section] {
            if objectArray[indexPath.row] is MembershipPrayer {
                isPrayerCell = true
            }
        }
        return isPrayerCell
    }
    
    func markPrayed(indexPath: IndexPath) {
        agreeInPrayer(indexPath: indexPath)
    }
    
    @objc func markAgreed(sender: CellButton) {
        if let isConnected = ConnectionTracker.isConnected {
            if isConnected {
                let row = sender.tag
                let section = sender.section
                let indexPath = NSIndexPath(row: row, section: section)
                agreeInPrayer(indexPath: indexPath as IndexPath)
            } else {
                ConnectionTracker().presentNotConnectedAlert(messageDirections: "Marking a Prayer prayed requires an internet connection.  Please re-establish your internet connection and try again.", viewController: self)
            }
        }
    }
    
    func agreeInPrayer(indexPath: IndexPath) {
        if let prayer = prayerAtIndexPath(indexPath: indexPath) {
            if let prayerRef = prayer.itemRef {
                prayerRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                    if var prayer = currentData.value as? [String : AnyObject] {
                        var agreedCount = prayer["agreedCount"] as? Int ?? 0
                        agreedCount += 1
                        
                        var newWhoAgreed = [String:AnyObject]()
                        if let userID = CurrentUser.currentUser.userID {
                            if let whoAgreed = prayer["whoAgreed"] as? [String : AnyObject] {
                                newWhoAgreed = whoAgreed
                            }
                            newWhoAgreed[userID] = userID as AnyObject?
                        }
                        
                        prayer["whoAgreed"] = newWhoAgreed as AnyObject?
                        prayer["agreedCount"] = agreedCount as AnyObject?
                        prayer["lastPrayedDate"] = ServerValue.timestamp() as AnyObject?
                        currentData.value = prayer
                        return TransactionResult.success(withValue: currentData)
                    }
                    return TransactionResult.success(withValue: currentData)
                }) { (error, committed, snapshot) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                }
                
                if let userID = CurrentUser.currentUser.userID {
                    if let prayerOwnerID = prayer.prayerOwnerUserID {
                        let circleRef = Database.database().reference().child("users").child(prayerOwnerID).child("circleUsers").child(userID)
                        circleRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                            if var user = currentData.value as? [String : AnyObject] {
                                var agreedInPrayerCount = user["agreedInPrayerCount"] as? Int ?? 0
                                agreedInPrayerCount += 1
                                
                                let timeStamp = user["lastAgreedInPrayerDate"] as? Double ?? 0
                                
                                user["agreedInPrayerCount"] = agreedInPrayerCount as AnyObject?
                                user["lastAgreedInPrayerDate"] = ServerValue.timestamp() as AnyObject?
                                currentData.value = user
                                
                                for membershipUser in CurrentUser.firebaseMembershipUsers {
                                    if let membershipUserID = membershipUser.userID {
                                        if prayerOwnerID == membershipUserID {
                                            if let messagingTokens = membershipUser.messagingTokens {
                                                let calendar = NSCalendar.current
                                                let interval = timeStamp / 1000
                                                let date = Date(timeIntervalSince1970: interval)
                                                if !calendar.isDateInToday(date) {
                                                    NotificationsHelper().sendAgreedNotification(messagingTokens: messagingTokens)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                return TransactionResult.success(withValue: currentData)
                            }
                            return TransactionResult.success(withValue: currentData)
                        }) { (error, committed, snapshot) in
                            if let error = error {
                                print(error.localizedDescription)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func prayerAtIndexPath(indexPath: IndexPath) -> MembershipPrayer? {
        var prayer = MembershipPrayer()
        let sectionTitles = Array(cleanData.keys) as [String]
        let section = sectionTitles[indexPath.section]
        if let objectArray = cleanData[section] {
            if let prayerCheck = objectArray[indexPath.row] as? MembershipPrayer {
                prayer = prayerCheck
            }
        }
        return prayer
    }
    
    func indexPathForPrayer(membershipPrayer: MembershipPrayer) -> IndexPath {
        var section = Int()
        var row = Int()
        var sectionIndex = 0
        for sectionKey in Array(cleanData.keys) {
            if sectionKey == "membershipPrayers" {
                section = sectionIndex
            }
            sectionIndex += 1
        }
        
        if let membershipPrayerKey = membershipPrayer.key {
            if let arrayOfPrayersInSection = cleanData["membershipPrayers"] as? [MembershipPrayer] {
                var rowIndex = 0
                for prayer in arrayOfPrayersInSection {
                    if let prayerKey = prayer.key {
                        if membershipPrayerKey == prayerKey {
                            row = rowIndex
                        }
                    }
                    rowIndex += 1
                }
            }
        }
        return IndexPath(row: row, section: section)
    }

    @objc func acceptInvite(sender: CellButton) {
        let buttonTag = sender.tag
        let buttonSection = sender.section
        let indexPath = NSIndexPath(row: buttonTag, section: buttonSection)
        let memberUser = invitationUsers[indexPath.row]
        MembershipUser().acceptInvite(membershipUser: memberUser)
    }
    
    @objc func declineInvite(sender: CellButton) {
        let buttonTag = sender.tag
        let buttonSection = sender.section
        let indexPath = NSIndexPath(row: buttonTag, section: buttonSection)
        let memberUser = invitationUsers[indexPath.row]
        MembershipUser().declineInvite(membershipUser: memberUser)
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
        var count = 0
        for user in CurrentUser.firebaseMembershipUsers {
            if let status = user.membershipStatus {
                if status == MembershipUser.currentUserMembershipStatus.invited.rawValue {
                    count += 1
                }
            }
        }
        if invitationUsers.count == count {
            loadData()
            refreshTable()
        }
    }
    
    @objc func handleNotification4(_ notification: NSNotification) {
        loadData()
        refreshTable()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        viewIsVisible = false
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "membershipUserDidSet"), object: nil)
        for prayer in self.prayerQueue {
            CurrentUser.firebaseMembershipPrayers.append(prayer)
        }
        self.prayerQueue = []
        self.hideRefreshButton()
    }
}
