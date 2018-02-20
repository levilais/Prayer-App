//
//  JournalViewController.swift
//  Prayer App
//
//  Created by Levi on 11/5/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FirebaseDatabase

class JournalViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    
    var tempReloadCount = 0
    
    var preSortedPrayers = [CurrentUserPrayer]()
    var sortedPrayers = [String:[CurrentUserPrayer]]()
    var viewIsVisible = false
    var viewAlreadyAppeared = false
    
    // HEADER VIEW
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var titleImage: UIImageView!
    @IBOutlet weak var timerHeaderButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    
    // POST TO CIRCLES POPUP VIEW
    @IBOutlet weak var postToPrayerCircleView: UIView!
    @IBOutlet weak var postToPrayerCircleSubview: UIView!
    @IBOutlet var postToPrayerCircleMembers: [UIImageView]!
    @IBOutlet weak var postToPrayerCirclePopupBackgroundButton: UIButton!
    var shareText = String()
    
    // NOT LOGGED IN VIEW
    @IBOutlet weak var notLoggedInView: UIView!
    var showSignUp = true
    
    // SUBHEADER VIEW
    @IBOutlet weak var activeButton: UIButton!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var answerButton: UIButton!
    
    // TABLEVIEW
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    var sectionTitle = String()
    var answeredShowing = false
    
    // MARK ANSWERED POPUP
    @IBOutlet weak var markAnsweredPopoverView: UIView!
    @IBOutlet weak var markAnsweredBackgroundButton: UIButton!
    @IBOutlet weak var markAnsweredSubview: UIView!
    @IBOutlet weak var markAnsweredTextView: UITextView!
    var indexPathToMarkAnswered: IndexPath = IndexPath()
    
    var userRef: DatabaseReference!
    @IBOutlet weak var refreshButton: UIButton!
    
    // EDIT PRAYER VARIABLES
    var editPrayerTopic = String()
    var editPrayerText = String()
    var editPrayerID = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        markAnsweredTextView.layer.borderColor = UIColor(red:0.76, green:0.76, blue:0.76, alpha:1.0).cgColor
        markAnsweredTextView.layer.borderWidth = 1.0
        
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("view will appear called")
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification2(_:)), name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        TimerStruct().showTimerIfRunning(timerHeaderButton: timerHeaderButton, titleImage: titleImage)
        viewIsVisible = true
        if let userID = Auth.auth().currentUser?.uid {
            notLoggedInView.isHidden = true
            viewAlreadyAppeared = true
            userRef = Database.database().reference().child("users").child(userID)
            setupObservers()
        } else {
            notLoggedInView.isHidden = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.setContentOffset(.zero, animated: true)
    }
    
    func firstLoad(completed: @escaping (Bool) -> Void) {
        userRef.child("prayers").observeSingleEvent(of: .value, with: { (snapshot) -> Void in
            CurrentUser.currentUserPrayers.removeAll()
            for prayerSnap in snapshot.children {
                let newPrayer = CurrentUserPrayer().currentUserPrayerFromSnapshot(snapshot: prayerSnap as! DataSnapshot)
                
                CurrentUser.currentUserPrayers.append(newPrayer)
            }
            self.reloadPrayers()
            DispatchQueue.main.async {
                UIView.performWithoutAnimation {
                    self.tableView.reloadData()
                    self.toggleTableIsHidden()
                }
            }
            completed(true)
        })
    }
    
    func setupObservers() {
        firstLoad { (success) in
            self.userRef.child("prayers").observe(.childAdded, with: { (snapshot) -> Void in
                let newPrayer = CurrentUserPrayer().currentUserPrayerFromSnapshot(snapshot: snapshot)
                var matchExists = false
                for prayer in CurrentUser.currentUserPrayers {
                    if let prayerKey = prayer.key {
                        if let newPrayerKey = newPrayer.key {
                            if prayerKey == newPrayerKey {
                                matchExists = true
                            }
                        }
                    }
                }
                if matchExists == false {
                    CurrentUser.currentUserPrayers.append(newPrayer)
                    if self.viewIsVisible {
                        self.showRefreshButton()
                    } else {
                        self.reloadPrayers()
                        DispatchQueue.main.async {
                            UIView.performWithoutAnimation {
                                self.tableView.reloadData()
                                self.toggleTableIsHidden()
                            }
                        }
                        self.tableView.scrollsToTop = true
                    }
                }
            })

            self.userRef.child("prayers").observe(.childRemoved, with: { (snapshot) -> Void in
                let removedPrayer = CurrentUserPrayer().currentUserPrayerFromSnapshot(snapshot: snapshot)
                if let removedPrayerKey = removedPrayer.key {
                    var i = 0
                    for prayer in CurrentUser.currentUserPrayers {
                        if let key = prayer.key {
                            if removedPrayerKey == key {
                                CurrentUser.currentUserPrayers.remove(at: i)
                            }
                        }
                        i += 1
                    }
                }
                self.reloadPrayers()
                DispatchQueue.main.async {
                    UIView.performWithoutAnimation {
                        self.tableView.reloadData()
                        self.toggleTableIsHidden()
                    }
                }
            })
            
            self.userRef.child("prayers").observe(.childChanged, with: { (snapshot) -> Void in
                let changedPrayer = CurrentUserPrayer().currentUserPrayerFromSnapshot(snapshot: snapshot)
                if let changedPrayerKey = changedPrayer.key {
                    var i = 0
                    for prayer in CurrentUser.currentUserPrayers {
                        if let key = prayer.key {
                            if changedPrayerKey == key {
                                CurrentUser.currentUserPrayers[i] = changedPrayer
                                if let changedPrayerIsAnswered = changedPrayer.isAnswered {
                                    if let prayerIsAnswered = prayer.isAnswered {
                                        if prayerIsAnswered == false && changedPrayerIsAnswered == true {
                                            self.reloadPrayers()
                                            DispatchQueue.main.async {
                                                UIView.performWithoutAnimation {
                                                    self.tableView.reloadData()
                                                    self.toggleTableIsHidden()
                                                }
                                            }
                                        } else {
                                            i = 0
                                            for preSortedPrayer in self.preSortedPrayers {
                                                if let prayerKey = preSortedPrayer.key {
                                                    if prayerKey == changedPrayerKey {
                                                        self.preSortedPrayers[i] = changedPrayer
                                                        self.refreshPrayers()

                                                        if let isAnswered = prayer.isAnswered {
                                                            if !isAnswered {
                                                                let indexPath = self.indexPathForPrayer(currentUserPrayer: changedPrayer)
                                                                if let cell = self.tableView.cellForRow(at: indexPath) as? PrayerTableViewCell {
                                                                    self.setUnansweredCellLabels(prayer: prayer, cell: cell)
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                i += 1
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        i += 1
                    }
                }
            })
        }
    }
    
    @IBAction func refreshButtonDidPress(_ sender: Any) {
        reloadPrayers()
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
                self.toggleTableIsHidden()
            }
        }
        tableView.scrollsToTop = true
        hideRefreshButton()
    }
 
    func showRefreshButton() {
        refreshButton.isHidden = false
    }
    
    func hideRefreshButton() {
        refreshButton.isHidden = true
    }
    
    @IBAction func activeButtonDidPress(_ sender: Any) {
        showActive()
    }
    
    @IBAction func toggleButtonDidPress(_ sender: Any) {
        if answeredShowing == false {
            showAnswered()
        } else {
            showActive()
        }
    }
    
    @IBAction func answerButtonDidPress(_ sender: Any) {
        showAnswered()
    }
    
    func showAnswered() {
        answerButton.titleLabel?.font = UIFont.StyleFile.ToggleActiveFont
        activeButton.titleLabel?.font = UIFont.StyleFile.ToggleInactiveFont
        toggleButton.setBackgroundImage(UIImage(named: "tableToggleRightSelected.pdf"), for: .normal)
        answeredShowing = true
        reloadPrayers()
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
                self.toggleTableIsHidden()
            }
        }
        hideRefreshButton()
    }
    
    func showActive() {
        answerButton.titleLabel?.font = UIFont.StyleFile.ToggleInactiveFont
        activeButton.titleLabel?.font = UIFont.StyleFile.ToggleActiveFont
        toggleButton.setBackgroundImage(UIImage(named: "tableToggleLeftSelected.pdf"), for: .normal)
        answeredShowing = false
        reloadPrayers()
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
                self.toggleTableIsHidden()
            }
        }
        hideRefreshButton()
    }
    
    func reloadPrayers() {
        preSortedPrayers = []
        for prayer in CurrentUser.currentUserPrayers {
            if let isAnswered = prayer.isAnswered {
                if answeredShowing {
                    if isAnswered {
                        self.preSortedPrayers.append(prayer)
                    }
                } else {
                    if !isAnswered {
                        self.preSortedPrayers.append(prayer)
                    }
                }
            }
        }
        refreshPrayers()
    }
    
    func refreshPrayers() {
        sortedPrayers = [:]
        if self.preSortedPrayers.count > 0 {
            for prayer in self.preSortedPrayers.reversed() {
                if let prayerCategory = prayer.prayerCategory {
                    if self.sortedPrayers.keys.contains(prayerCategory) {
                        if var prayerArray = sortedPrayers[prayerCategory] {
                            prayerArray.append(prayer)
                            sortedPrayers[prayerCategory] = prayerArray
                        }
                    } else {
                        let newArray = [prayer]
                        sortedPrayers[prayerCategory] = newArray
                    }
                }
            }
        }
    }
    
    func toggleTableIsHidden() {
        if preSortedPrayers.count > 0 {
            tableView.isHidden = false
            messageLabel.isHidden = true
        } else {
            tableView.isHidden = true
            messageLabel.isHidden = false
            if !answeredShowing {
                messageLabel.text = "There are no saved active prayers"
            } else {
                messageLabel.text = "There are no saved answered prayers"
            }
        }
    }
    
    @IBAction func timerButtonDidPress(_ sender: Any) {
        TimerStruct().stopTimer(timerButton: timerHeaderButton, titleImageView: titleImage)
    }
    
    @IBAction func markAnsweredSaveDidPress(_ sender: Any) {
        markAnswered()
        dismissMarkAnsweredPopup()
    }
    
    @IBAction func markAnsweredCancelDidPress(_ sender: Any) {
        dismissMarkAnsweredPopup()
    }
    
    @IBAction func markAnsweredBackgroundButtonDidPress(_ sender: Any) {
        dismissMarkAnsweredPopup()
    }
    
    func dismissMarkAnsweredPopup() {
        self.markAnsweredPopoverView.alpha = 0
        self.markAnsweredTextView.text = ""
        self.markAnsweredTextView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        markAnsweredTextView.resignFirstResponder()
    }

    @IBAction func prayerIconDidPress(_ sender: Any) {
        _ = navigationController?.popViewController(animated: false)
    }
    
    @IBAction func createAccountDidPress(_ sender: Any) {
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
        } else if (segue.identifier == "showEditPrayerSegue") {
            let editPrayerViewController = segue.destination as! EditPrayerViewController
            editPrayerViewController.prayerID = self.editPrayerID
            editPrayerViewController.prayerText = self.editPrayerText
            editPrayerViewController.prayerTopic = self.editPrayerTopic
        }
    }
    
    // TABLE VIEW DATA SOURCE
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionKey = Array(sortedPrayers.keys)[section] as String
        return sectionKey
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sortedPrayers.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let prayerCategory = Array(sortedPrayers.keys)[section] as String
        if let sectionArray = sortedPrayers[prayerCategory] {
            return sectionArray.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if !answeredShowing {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "prayerCell", for: indexPath) as? PrayerTableViewCell else {
                fatalError("Unexpected Index Path")
            }
            
            configureUnanswered(cell, at: indexPath)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "answeredPrayerCell", for: indexPath) as? AnsweredPrayerTableViewCell else {
                fatalError("Unexpected Index Path")
            }
            configureAnswered(cell, at: indexPath)
            return cell
        }
    }
    
    func configureUnanswered(_ cell: PrayerTableViewCell, at indexPath: IndexPath) {
        let prayer = prayerAtIndexPath(indexPath: indexPath)
        
        if let prayerText = prayer.prayerText {
            cell.prayerTextView.text = prayerText
        }
    
        setUnansweredCellLabels(prayer: prayer, cell: cell)
    }
    
    func setUnansweredCellLabels(prayer: CurrentUserPrayer, cell: PrayerTableViewCell) {
        if let prayerCount = prayer.prayerCount {
            cell.prayedCountLabel.text = "Prayed \(Utilities().numberOfTimesString(count: prayerCount))"
        }
        
        if !answeredShowing {
            cell.prayedLastLabel = FirebaseHelper().daysSinceTimeStampLabel(cellLabel: cell.prayedLastLabel, prayer: prayer, cell: cell)
        }
    }
    
    func configureAnswered(_ cell: AnsweredPrayerTableViewCell, at indexPath: IndexPath) {
        let prayer = prayerAtIndexPath(indexPath: indexPath)
        cell.prayerLabel.text = prayer.prayerText
        
        cell.lastPrayedLabel = FirebaseHelper().dateAnsweredLabel(cellLabel: cell.lastPrayedLabel, prayer: prayer)
        
        if let answeredPrayer = prayer.howAnswered {
            cell.howAnsweredLabel.text = answeredPrayer
        }
        
        var prayerCount = Int()
        if let prayerCountCheck = prayer.prayerCount {
            prayerCount = prayerCountCheck
        }
        cell.prayerCountLabel.text = "Prayed \(Utilities().numberOfTimesString(count: prayerCount))"
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .default, title: "Delete") { (action:UITableViewRowAction, indexPath:IndexPath) in
            let prayer = self.prayerAtIndexPath(indexPath: indexPath)
            prayer.itemRef?.removeValue()
        }
        delete.backgroundColor = UIColor.StyleFile.WineColor
        
        if !answeredShowing {
            let answered = UITableViewRowAction(style: .default, title: "Answered") { (action:UITableViewRowAction, indexPath:IndexPath) in
                self.indexPathToMarkAnswered = indexPath
                Animations().animateMarkAnsweredPopup(view: self.markAnsweredPopoverView, backgroundButton: self.markAnsweredBackgroundButton, subView: self.markAnsweredSubview, viewController: self, textView: self.markAnsweredTextView)
            }
            answered.backgroundColor = UIColor.StyleFile.DarkBlueColor
            let edit = UITableViewRowAction(style: .default, title: "Edit") { (action:UITableViewRowAction, indexPath:IndexPath) in
                self.indexPathToMarkAnswered = indexPath
                let prayer = self.prayerAtIndexPath(indexPath: indexPath)
                if let prayerTopic = prayer.prayerCategory {
                    self.editPrayerTopic = prayerTopic
                }
                if let prayerText = prayer.prayerText {
                    self.editPrayerText = prayerText
                }
                if let prayerID = prayer.key {
                    self.editPrayerID = prayerID
                }
                self.performSegue(withIdentifier: "showEditPrayerSegue", sender: self)
            }
            edit.backgroundColor = UIColor.StyleFile.GreenColor
            
            let share = UITableViewRowAction(style: .default, title: "Share") { (action:UITableViewRowAction, indexPath:IndexPath) in
                self.indexPathToMarkAnswered = indexPath
                let prayer = self.prayerAtIndexPath(indexPath: indexPath)
                if let prayerText = prayer.prayerText {
                    self.shareText = prayerText
                }
                self.shareToCircle()
            }
            share.backgroundColor = UIColor.StyleFile.PurpleColor
            return [delete, answered, share, edit]
            
        }
        return [delete]
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if !answeredShowing {
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
        return nil
    }
    
    func markPrayed(indexPath: IndexPath) {
        let prayer = prayerAtIndexPath(indexPath: indexPath)
        CurrentUserPrayer().markPrayerPrayed(prayer: prayer)
    }
    
    func markAnswered() {
        let prayer = prayerAtIndexPath(indexPath: indexPathToMarkAnswered)
        if let answeredPrayer = markAnsweredTextView.text {
            var trimmedText = answeredPrayer.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedText == "" {
                trimmedText = "Undisclosed"
            }
            let howAnswered = trimmedText
            CurrentUserPrayer().markPrayerAnswered(prayer: prayer, howAnswered: howAnswered)
        }
    }
    
    @IBAction func shareDidPress(_ sender: Any) {
        print("share pressed")
        CirclePrayer().saveNewCirclePrayer(prayerText: self.shareText.trimmingCharacters(in: .whitespaces), userRef: userRef)
        dismissShareToPrayerCirclePopup()
        Animations().showPopup(labelText: "Shared!", presentingVC: self)
    }
    
    @IBAction func cancelDidPress(_ sender: Any) {
        dismissShareToPrayerCirclePopup()
    }
    
    @IBAction func backgroundButtonDidPress(_ sender: Any) {
        dismissShareToPrayerCirclePopup()
    }
    
    func shareToCircle() {
        if let isConnected = ConnectionTracker.isConnected {
            if isConnected {
                if CurrentUser.firebaseCircleMembers.count > 0 {
                    var actualMembers = [CircleUser]()
                    for circleUser in CurrentUser.firebaseCircleMembers {
                        if let relationship = circleUser.relationshipToCurrentUser {
                            if relationship == CircleUser.userRelationshipToCurrentUser.myCircleMember.rawValue {
                                actualMembers.append(circleUser)
                            }
                        }
                    }
                    
                    if actualMembers.count > 0 {
                        for imageView in postToPrayerCircleMembers {
                            imageView.layer.cornerRadius = imageView.frame.height / 2
                            imageView.clipsToBounds = true
                        }
                        
                        for i in 0...4 {
                            if i < actualMembers.count {
                                let circleUser = actualMembers[i]
                                if let image = circleUser.profileImageAsImage {
                                    postToPrayerCircleMembers[i].image = image
                                }
                            } else {
                                postToPrayerCircleMembers[i].image = UIImage(named: "profilImageDefault")
                            }
                        }
                        Animations().animateShareFromJournalToCirclePopup(view: postToPrayerCircleView, backgroundButton: postToPrayerCirclePopupBackgroundButton, subView: postToPrayerCircleSubview, viewController: self)
                    } else {
                        let alert = UIAlertController(title: "No Circle Members Found", message: "1) You must invite a user to your Circle and 2) an invite must be accepted in order to share Prayers to your Circle.", preferredStyle: .alert)
                        let action = UIAlertAction(title: "Add Members", style: .default, handler: { (action) in
                            self.performSegue(withIdentifier: "journalViewToAddContactsViewSegue", sender: self)
                        })
                        alert.addAction(action)
                        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true, completion: nil)
                        alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
                    }
                } else if Auth.auth().currentUser != nil {
                    let alert = UIAlertController(title: "No Circle Members Found", message: "You will need to add Circle Members in order to share Prayers to your Circle.", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Add Members", style: .default, handler: { (action) in
                        self.performSegue(withIdentifier: "journalViewToAddContactsViewSegue", sender: self)
                    })
                    alert.addAction(action)
                    let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                    alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
                } else {
                    let alert = UIAlertController(title: "No Account Found", message: "You will need to create an account and add Circle Members in order to share Prayers to your Circle.", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Create Account", style: .default, handler: { (action) in
                        self.performSegue(withIdentifier: "loginSignUpSegue", sender: self)
                    })
                    alert.addAction(action)
                    let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                    alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
                }
            } else {
                ConnectionTracker().presentNotConnectedAlert(messageDirections: "Sharing a Prayer to your Prayer Circle requires an internet connection.  Please re-establish your internet connection and try again.", viewController: self)
            }
        }
    }
    
    func dismissShareToPrayerCirclePopup() {
        self.postToPrayerCircleView.alpha = 0
    }
    
    func prayerAtIndexPath(indexPath: IndexPath) -> CurrentUserPrayer {
        var prayer = CurrentUserPrayer()
        let prayerCategory = Array(sortedPrayers.keys)[indexPath.section] as String
        if let arrayOfPrayersInSection = sortedPrayers[prayerCategory] {
            prayer = arrayOfPrayersInSection[indexPath.row]
        }
        return prayer
    }
    
    func indexPathForPrayer(currentUserPrayer: CurrentUserPrayer) -> IndexPath {
        var section = Int()
        var row = Int()
        if let prayerCategory = currentUserPrayer.prayerCategory {
            if let currentUserPrayerKey = currentUserPrayer.key {
                let prayerKeys = Array(sortedPrayers.keys)
                
                var sectionIndex = 0
                for key in prayerKeys {
                    if key == prayerCategory {
                        section = sectionIndex
                    }
                    sectionIndex += 1
                }
                
                if let arrayOfPrayersInSection = sortedPrayers[prayerCategory] {
                    var rowIndex = 0
                    for prayer in arrayOfPrayersInSection {
                        if let prayerKey = prayer.key {
                            if currentUserPrayerKey == prayerKey {
                                row = rowIndex
                            }
                        }
                        rowIndex += 1
                    }
                }
            }
        }
        return IndexPath(row: row, section: section)
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
        viewIsVisible = false
    }
}
