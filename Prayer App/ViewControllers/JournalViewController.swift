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
    
    var preSortedPrayers = [CurrentUserPrayer]()
    var sortedPrayers = [String:[CurrentUserPrayer]]()
    var viewIsVisible = false
    var viewAlreadyAppeared = false
    
    // HEADER VIEW
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var titleImage: UIImageView!
    @IBOutlet weak var timerHeaderButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    
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
    
    // DATA HANDLING
    var userRef: DatabaseReference!
    @IBOutlet weak var refreshButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        markAnsweredTextView.layer.borderColor = UIColor(red:0.76, green:0.76, blue:0.76, alpha:1.0).cgColor
        markAnsweredTextView.layer.borderWidth = 1.0
        
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification2(_:)), name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        tableView.estimatedRowHeight = 40
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
                                            print("is new answer, reload called")
                                            self.reloadPrayers()
                                        } else {
                                            print("not new answer, refresh called")
                                            i = 0
                                            for preSortedPrayer in self.preSortedPrayers {
                                                if let prayerKey = preSortedPrayer.key {
                                                    if prayerKey == changedPrayerKey {
                                                        self.preSortedPrayers[i] = changedPrayer
                                                        self.refreshPrayers()
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
    }
    
    func showActive() {
        answerButton.titleLabel?.font = UIFont.StyleFile.ToggleInactiveFont
        activeButton.titleLabel?.font = UIFont.StyleFile.ToggleActiveFont
        toggleButton.setBackgroundImage(UIImage(named: "tableToggleLeftSelected.pdf"), for: .normal)
        answeredShowing = false
        reloadPrayers()
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
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
                self.toggleTableIsHidden()
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
        
        if !answeredShowing {
            cell.prayedLastLabel = FirebaseHelper().daysSinceTimeStampLabel(cellLabel: cell.prayedLastLabel, prayer: prayer, cell: cell)
        }
    
        var prayerCount = Int()
        if let prayerCountCheck = prayer.prayerCount {
            prayerCount = prayerCountCheck
        }
        cell.prayedCountLabel.text = "Prayed \(Utilities().numberOfTimesString(count: prayerCount))"
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
            return [delete, answered]
            
        }
        return [delete]
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if !answeredShowing {
            var amenAction = UIContextualAction()
            amenAction = UIContextualAction(style: .normal, title:  "Amen", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                self.markPrayed(indexPath: indexPath)
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
    
    func prayerAtIndexPath(indexPath: IndexPath) -> CurrentUserPrayer {
        var prayer = CurrentUserPrayer()
        let prayerCategory = Array(sortedPrayers.keys)[indexPath.section] as String
        if let arrayOfPrayersInSection = sortedPrayers[prayerCategory] {
            prayer = arrayOfPrayersInSection[indexPath.row]
        }
        return prayer
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
