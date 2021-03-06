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

class CirclesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

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
    @IBOutlet weak var refreshButton: UIButton!
    
    var viewIsVisible = false
    var circleSpotFilled = [false,false,false,false,false]
    var profileImageLoaded = [false,false,false,false,false]
    var selectedCircleMember = 0
    var ref: DatabaseReference!
    var userRef: DatabaseReference!
    var indexPathForEdit: IndexPath?
    var circlePrayers = [CirclePrayer]()
    
    var phoneAlert = UIAlertController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for circleButton in circleProfileImageButtons {
            circleButton.addTarget(self, action: #selector(circleProfileButtonDidPress(sender:)), for: .touchUpInside)
        }
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        viewIsVisible = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification2(_:)), name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification3(_:)), name: NSNotification.Name(rawValue: "circleMemberAdded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification4(_:)), name: NSNotification.Name(rawValue: "circleUserProfileImageDidSet"), object: nil)
        
        TimerStruct().showTimerIfRunning(timerHeaderButton: timerHeaderButton, titleImage: titleImage)
        
        if Auth.auth().currentUser != nil {
            userNotLoggedInView.isHidden = true
            userLoggedInView.isHidden = false
            selectedCircleMember = 0
            if let userID = Auth.auth().currentUser?.uid {
                userRef = Database.database().reference().child("users").child(userID)
                setupObservers()
                setupCircleUserObservers()
            }
            if let userPhone = CurrentUser.currentUser.userPhone {
                print("has phone number")
            } else {
                if Loads.askedAboutPhone == false {
                    presentPhoneNumberRequestAlert()
                } else {
                    print("already asked for phone")
                }
            }
            setCircleData()
            toggleTableIsHidden()
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
    
    func toggleTableIsHidden() {
        if CurrentUser.currentUserCirclePrayers.count > 0 {
            tableView.isHidden = false
        } else {
            tableView.isHidden = true
        }
    }
    
    func firstLoad(completed: @escaping (Bool) -> Void) {
        userRef.child("circlePrayers").observeSingleEvent(of: .value, with: { (snapshot) -> Void in
            CurrentUser.currentUserCirclePrayers.removeAll()
            for prayerSnap in snapshot.children {
                let newPrayer = CirclePrayer().circlePrayerFromSnapshot(snapshot: prayerSnap as! DataSnapshot)
                CurrentUser.currentUserCirclePrayers.append(newPrayer)
            }
            self.reloadData()
            self.toggleTableIsHidden()
            completed(true)
        })
    }
    
    func setupObservers() {
        firstLoad { (success) in
            self.userRef.child("circlePrayers").observe(.childAdded, with: { (snapshot) -> Void in
                let newPrayer = CirclePrayer().circlePrayerFromSnapshot(snapshot: snapshot)
                var matchExists = false
                for prayer in CurrentUser.currentUserCirclePrayers {
                    if let prayerKey = prayer.key {
                        if let newPrayerKey = newPrayer.key {
                            if prayerKey == newPrayerKey {
                                matchExists = true
                            }
                        }
                    }
                }
                
                if !matchExists {
                    CurrentUser.currentUserCirclePrayers.append(newPrayer)
                    if self.viewIsVisible {
                        self.showRefreshButton()
                    } else {
                        self.reloadData()
                        self.tableView.scrollsToTop = true
                    }
                }
            })
            
            self.userRef.child("circlePrayers").observe(.childRemoved, with: { (snapshot) -> Void in
                let removedPrayer = CirclePrayer().circlePrayerFromSnapshot(snapshot: snapshot)
                if let removedPrayerKey = removedPrayer.key {
                    var i = 0
                    for circlePrayer in CurrentUser.currentUserCirclePrayers {
                        if let key = circlePrayer.key {
                            if removedPrayerKey == key {
                                CurrentUser.currentUserCirclePrayers.remove(at: i)
                            }
                        }
                        i += 1
                    }
                }
                if CurrentUser.currentUserCirclePrayers.count > 0 {
                    self.reloadData()
                } else {
                    self.toggleTableIsHidden()
                }
            })
            
            self.userRef.child("circlePrayers").observe(.childChanged, with: { (snapshot) -> Void in
                let changedPrayer = CirclePrayer().circlePrayerFromSnapshot(snapshot: snapshot)
                if let changedPrayerKey = changedPrayer.key {
                    var i = 0
                    for circlePrayer in CurrentUser.currentUserCirclePrayers {
                        if let key = circlePrayer.key {
                            if changedPrayerKey == key {
                                CurrentUser.currentUserCirclePrayers[i] = changedPrayer
                                let indexPath = self.indexPathForPrayer(circlePrayer: changedPrayer)
                                if let cell = self.tableView.cellForRow(at: indexPath) as? PrayerTableViewCell {
                                    self.setCellLabels(prayer: changedPrayer, cell: cell)
                                }
                            }
                        }
                        i += 1
                    }
                }
            })
        }
    }
    
    func firstCircleUserLoad(completed: @escaping (Bool) -> Void) {
        userRef.child("circleUsers").observeSingleEvent(of: .value, with: { (snapshot) -> Void in
            for userSnap in snapshot.children {
                let newUser = CircleUser().circleUserFromSnapshot(snapshot: userSnap as! DataSnapshot)
                var matchExists = false
                for user in CurrentUser.firebaseCircleMembers {
                    if let userKey = user.key {
                        if let newUserKey = newUser.key {
                            if userKey == newUserKey {
                                matchExists = true
                            }
                        }
                    }
                }
                if !matchExists {
                    CurrentUser.firebaseCircleMembers.append(newUser)
                    FirebaseHelper().setCircleUserProfileImageFromFirebase(circleUser: newUser)
                    self.setCircleData()
                }
            }
            self.setCircleData()
            completed(true)
        })
    }
    
    func setupCircleUserObservers() {
        firstCircleUserLoad { (success) in
            self.userRef.child("circleUsers").observe(.childAdded, with: { (snapshot) -> Void in
                let newUser = CircleUser().circleUserFromSnapshot(snapshot: snapshot)
                var matchExists = false
                for user in CurrentUser.firebaseCircleMembers {
                    if let userKey = user.key {
                        if let newUserKey = newUser.key {
                            if userKey == newUserKey {
                                matchExists = true
                            }
                        }
                    }
                }
                
                if !matchExists {
                    CurrentUser.firebaseCircleMembers.append(newUser)
                    FirebaseHelper().setCircleUserProfileImageFromFirebase(circleUser: newUser)
                    self.setCircleData()
                }
            })
            
            self.userRef.child("circleUsers").observe(.childRemoved, with: { (snapshot) -> Void in
                let removedUser = CircleUser().circleUserFromSnapshot(snapshot: snapshot)
                if let removedUserKey = removedUser.key {
                    var i = 0
                    for user in CurrentUser.firebaseCircleMembers {
                        if let key = user.key {
                            if removedUserKey == key {
                                if self.selectedCircleMember > 0 {
                                    self.selectedCircleMember -= 1
                                }
                                CurrentUser.firebaseCircleMembers.remove(at: i)
                            }
                        }
                        i += 1
                    }
                }
                self.setCircleData()
            })
            
            self.userRef.child("circleUsers").observe(.childChanged, with: { (snapshot) -> Void in
                let changedUser = CircleUser().circleUserFromSnapshot(snapshot: snapshot)
                if let changedUserKey = changedUser.key {
                    var i = 0
                    for user in CurrentUser.firebaseCircleMembers {
                        if let key = user.key {
                            if changedUserKey == key {
                                CurrentUser.firebaseCircleMembers[i] = changedUser
                                FirebaseHelper().setCircleUserProfileImageFromFirebase(circleUser: changedUser)
                            }
                        }
                        i += 1
                    }
                    self.setCircleData()
                }
            })
        }
    }
    
    @IBAction func refreshButtonDidPress(_ sender: Any) {
        self.reloadData()
        tableView.scrollsToTop = true
        hideRefreshButton()
    }
    
    func showRefreshButton() {
        refreshButton.isHidden = false
    }
    
    func hideRefreshButton() {
        refreshButton.isHidden = true
    }
    
    
    private var cellHeights: [IndexPath: CGFloat?] = [:]
    var expandedIndexPaths: [IndexPath] = []
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = cellHeights[indexPath] {
            return height ?? UITableViewAutomaticDimension
        }
        return UITableViewAutomaticDimension
    }

    func expandCell(cell: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            if !expandedIndexPaths.contains(indexPath) {
                expandedIndexPaths.append(indexPath)
                cellHeights[indexPath] = nil
                tableView.reloadRows(at: [indexPath], with: .none)
            }
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
        return "My Circle Posts"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return circlePrayers.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .default, title: "Delete") { (action:UITableViewRowAction, indexPath:IndexPath) in
            let prayer = self.circlePrayers[indexPath.row]
            prayer.itemRef?.removeValue()
        }
        
        delete.backgroundColor = UIColor.StyleFile.WineColor
        return [delete]
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var amenAction = UIContextualAction()
        amenAction = UIContextualAction(style: .normal, title:  "Amen", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            self.markPrayed(indexPath: indexPath)
            success(true)
        })
        amenAction.backgroundColor = UIColor.StyleFile.TealColor
        return UISwipeActionsConfiguration(actions: [amenAction])
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "prayerCell", for: indexPath) as! PrayerTableViewCell
        
        let prayer = circlePrayers[indexPath.row]
        
        if let prayerText = prayer.prayerText {
            cell.prayerTextView.text = prayerText
        }
        
        setCellLabels(prayer: prayer, cell: cell)
        
        if let lastPrayed = prayer.lastPrayed {
            let string = Utilities().dayDifference(timeStampAsDouble: lastPrayed)
            if string == "today" {
                cell.prayerTextView.textColor = UIColor.StyleFile.MediumGrayColor
            } else {
                cell.prayerTextView.textColor = UIColor.StyleFile.DarkGrayColor
            }
        }
        
        return cell
    }
    
    func setCellLabels(prayer: CirclePrayer, cell: PrayerTableViewCell) {
        if let lastPrayedCheck = prayer.lastPrayed {
            let lastPrayed = Utilities().dayDifference(timeStampAsDouble: lastPrayedCheck)
            cell.prayedLastLabel.text = "Last prayed \(Utilities().dayDifference(timeStampAsDouble: lastPrayedCheck))"
            if lastPrayed == "today" {
                cell.prayedLastLabel.textColor = UIColor.StyleFile.TealColor
                cell.prayedLastLabel.font = UIFont.StyleFile.LastPrayedBold
            } else {
                cell.prayedLastLabel.textColor = UIColor.StyleFile.MediumGrayColor
                cell.prayedLastLabel.font = UIFont.StyleFile.LastPrayedMedium
            }
        }
        
        if let agreedCountCheck = prayer.agreedCount {
            cell.prayedCountLabel.text = "Prayed \(Utilities().numberOfTimesString(count: agreedCountCheck))"
        }
    }
    
    func markPrayed(indexPath: IndexPath) {
        if let isConnected = ConnectionTracker.isConnected {
            if isConnected {
                let prayer = circlePrayers[indexPath.row]
                if let prayerRef = prayer.itemRef {
                    prayerRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
                        if var prayer = currentData.value as? [String : AnyObject] {
                            var agreedCount = prayer["agreedCount"] as? Int ?? 0
                            agreedCount += 1
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
                }
            } else {
                ConnectionTracker().presentNotConnectedAlert(messageDirections: "Marking a Prayer prayed requires an internet connection.  Please re-establish your internet connection and try again.", viewController: self)
            }
        }
    }
    
    func loadData() {
        if CurrentUser.firebaseCircleMembers.count == 0 && circlePrayers.count > 0 {
            userRef.child("circlePrayers").removeValue()
        }
        self.reloadData()
    }
    
    func reloadData() {
        if CurrentUser.firebaseCircleMembers.count > 0 {
            var acceptedUserExists = false
            for user in CurrentUser.firebaseCircleMembers {
                if let userRelationship = user.relationshipToCurrentUser {
                    if userRelationship == CircleUser.userRelationshipToCurrentUser.myCircleMember.rawValue {
                        acceptedUserExists = true
                    }
                }
            }
            if acceptedUserExists {
                circlePrayers = CurrentUser.currentUserCirclePrayers.reversed()
                if circlePrayers.count > 0 {
                    DispatchQueue.main.async {
                        UIView.performWithoutAnimation {
                            self.tableView.reloadData()
                        }
                    }
                } else {
                    self.toggleTableIsHidden()
                }
            } else {
                if let currentUserRef = CurrentUser.currentUser.userRef {
                    currentUserRef.child("circlePrayers").removeValue()
                }
                CurrentUser.currentUserCirclePrayers.removeAll()
                circlePrayers.removeAll()
                self.toggleTableIsHidden()
            }
        }
    }
    
    // CIRCLE DATA AND LOGIN/SIGNUP DATA
    @objc func circleProfileButtonDidPress(sender: UIButton) {
        let tag = sender.tag
        if circleSpotFilled[tag] {
            toggleCircleMemberDetailContent(buttonTag: tag)
            selectedCircleMember = tag
        } else {
            if let isConnected = ConnectionTracker.isConnected {
                if isConnected {
                    self.performSegue(withIdentifier: "selectCircleMembersSegue", sender: self)
                } else {
                    ConnectionTracker().presentNotConnectedAlert(messageDirections: "Inviting users to your Circle requires an internet connection.  Please re-establish your internet connection and try again.", viewController: self)
                }
            }
        }
    }
    
    func toggleCircleMemberDetailContent(buttonTag: Int) {
        if CurrentUser.firebaseCircleMembers.count == 0 {
            circleNameLabel.text = "Tap above to send invitation"
            circleJoinedLabel.text = ""
            circleAgreedLabel.text = ""
            circleAgreedCountLabel.text = ""
            deleteFromCircleButton.isHidden = true
            for button in circleProfileImageButtons {
                button.layer.backgroundColor = UIColor.clear.cgColor
            }
        } else {
            let circleUser = CurrentUser.firebaseCircleMembers[buttonTag]
            for button in circleProfileImageButtons {
                if button.tag != buttonTag && button.tag < CurrentUser.firebaseCircleMembers.count {
                    button.layer.backgroundColor = UIColor.StyleFile.TealColor.cgColor
                } else {
                    button.layer.backgroundColor = UIColor.clear.cgColor
                }
            }
            
            var agreedCount = Int()
            var lastAgreedDate = Double()
            var joinedCircleDate = Double()
            
            if let agreedCountCheck = circleUser.agreedInPrayerCount {
                agreedCount = agreedCountCheck
            } else {
                agreedCount = 0
            }
            if let lastAgreedDateCheck = circleUser.lastAgreedInPrayerDate {
                lastAgreedDate = lastAgreedDateCheck
            } else {
                lastAgreedDate = 0 as Double
            }
            if let joinedCircleDateCheck = circleUser.dateJoinedCircle {
                joinedCircleDate = joinedCircleDateCheck
            }
            
            if let userRelationship = circleUser.relationshipToCurrentUser {
                switch userRelationship {
                case "invited":
                    circleNameLabel.text = circleUser.getFullName(user: circleUser)
                    circleJoinedLabel.text = "You are still waiting for your invitation to be accepted"
                    circleAgreedLabel.text = ""
                    circleAgreedCountLabel.text = ""
                    deleteFromCircleButton.isHidden = false
                case "myCircleMember":
                    circleNameLabel.text = circleUser.getFullName(user: circleUser)
                    circleJoinedLabel.text = "Joined your Circle on \(Utilities().dateFromDouble(timeStampAsDouble: joinedCircleDate))"
                    circleAgreedCountLabel.text = "Agreed in Prayer \(Utilities().numberOfTimesString(count: agreedCount))"
                    if lastAgreedDate != 0 {
                        circleAgreedLabel.text = "Last agreed in Prayer \(Utilities().dayDifference(timeStampAsDouble: lastAgreedDate))"
                    } else {
                        circleAgreedLabel.text = ""
                    }
                    deleteFromCircleButton.isHidden = false
                default:
                    print("default called")
                }
            }
        }
    }
    
    func setCircleData() {
        let circleUsers = CurrentUser.firebaseCircleMembers
        let circleCount = circleUsers.count
        
        for i in 0...4 {
            switch i {
            case 0 ..< circleCount:
                let circleUser = circleUsers[i]
                
                if profileImageLoaded[i] == false {
                    if let image = circleUser.profileImageAsImage {
                        circleProfileImages[i].image = image
                        profileImageLoaded[i] = true
                    } else {
                        circleProfileImages[i].image = UIImage(named: "settingsPrayerIcon.pdf")
                    }
                }

                circleSpotFilled[i] = true
            case circleCount ... 4:
                circleProfileImages[i].image = UIImage(named: "addCircleMemberIcon.pdf")
                circleSpotFilled[i] = false
            default:
                print("failure")
            }
        }
        toggleCircleMemberDetailContent(buttonTag: selectedCircleMember)
        self.reloadData()   
    }
    
    
    @IBAction func deleteCircleMemberDidPress(_ sender: Any) {
        let alert = UIAlertController(title: "Are you sure", message: "Are you sure you want to remove this Circle Member", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Yes, I'm sure", style: .default) { (action) in
            let circleUser = CurrentUser.firebaseCircleMembers[self.selectedCircleMember]
            
            CircleUser().removeUserFromCircle(circleUser: circleUser)
            
            self.circleSpotFilled[self.selectedCircleMember] = false
            self.selectedCircleMember = 0
            self.loadData()
            self.setCircleData()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
        alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
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
    
    func indexPathForPrayer(circlePrayer: CirclePrayer) -> IndexPath {
        var row = Int()
        if let circlePrayerKey = circlePrayer.key {
            var rowIndex = 0
            for prayer in circlePrayers {
                if let prayerKey = prayer.key {
                    if circlePrayerKey == prayerKey {
                        row = rowIndex
                    }
                }
                rowIndex += 1
            }
        }
        return IndexPath(row: row, section: 0)
    }
    
    func presentPhoneNumberRequestAlert() {
        phoneAlert = UIAlertController(title: "Be Found!", message: "You are currently only able to be found by your email address. Add your phone number so that your contacts can better find you.", preferredStyle: .alert)

        phoneAlert.addTextField { (textField) in
            textField.placeholder = "Example: 555-555-5555"
            textField.keyboardType = UIKeyboardType.numberPad
            textField.keyboardAppearance = UIKeyboardAppearance.dark
            textField.delegate = self
        }
        
        phoneAlert.addAction(UIAlertAction(title: "Save Number", style: .default, handler: { [weak phoneAlert] (_) in
            if let textField = phoneAlert?.textFields![0] {
                if let number = textField.text {
                    if number.count == 12 {
                        self.userRef.child("userPhone").setValue(number)
                        print("phone number: \(number)")
                        Animations().showPopup(labelText: "Saved!", presentingVC: self)
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
            self.setCircleData()
        }
    }
    
    @objc func handleNotification4(_ notification: NSNotification) {
        DispatchQueue.main.async {
            self.setCircleData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "circleMemberAdded"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "circleUserProfileImageDidSet"), object: nil)
        viewIsVisible = false
        selectedCircleMember = 0
    }
}
