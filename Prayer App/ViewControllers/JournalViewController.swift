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
    var answeredPrayers = [CurrentUserPrayer]()
    var activePrayers = [CurrentUserPrayer]()
    var prayers = [CurrentUserPrayer]()
    var sectionHeaders = [String]()
    
    var prayersSortedByCategory = [String:[CurrentUserPrayer]]()
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
    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()

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
        
        if Auth.auth().currentUser != nil {
            notLoggedInView.isHidden = true
            preSortedPrayers = []
            setupObservers()
            
            showActive()
            updateView()
            viewAlreadyAppeared = true
        } else {
            notLoggedInView.isHidden = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.setContentOffset(.zero, animated: true)
    }
    
    func setupObservers() {
        print("observers Added")
        if let userID = Auth.auth().currentUser?.uid {
            Database.database().reference().child("users").child(userID).child("prayers").observe(.childAdded) { (snapshot) in
                if let userDictionary = snapshot.value as? NSDictionary {
                    let prayer = FirebaseHelper().prayerFromDictionary(userDictionary: userDictionary)
                    self.preSortedPrayers.append(prayer)
                    print("childAdded Fired")
                }
                self.reloadPrayerData()
            }
            
            Database.database().reference().child("users").child(userID).child("prayers").observe(.childRemoved) { (snapshot) in
                if let userDictionary = snapshot.value as? NSDictionary {
                    let snapshotPrayer = FirebaseHelper().prayerFromDictionary(userDictionary: userDictionary)
                    var i = 0
                    for prayer in self.preSortedPrayers {
                        if let prayerID = prayer.prayerID {
                            if let snapshotPrayerID = snapshotPrayer.prayerID {
                                if prayerID == snapshotPrayerID {
                                    self.preSortedPrayers.remove(at: i)
                                    print("childRemoved Fired")
                                }
                            }
                        }
                        i += 1
                    }
                    self.reloadPrayerData()
                }
            }
            
            Database.database().reference().child("users").child(userID).child("prayers").observe(.childChanged) { (snapshot) in
                if let userDictionary = snapshot.value as? NSDictionary {
                    let snapshotPrayer = FirebaseHelper().prayerFromDictionary(userDictionary: userDictionary)
                    var i = 0
                    for prayer in self.preSortedPrayers {
                        if let prayerID = prayer.prayerID {
                            if let snapshotPrayerID = snapshotPrayer.prayerID {
                                if prayerID == snapshotPrayerID {
                                    self.preSortedPrayers[i] = snapshotPrayer
                                    print("childChanged Fired")
                                }
                            }
                        }
                        i += 1
                    }
                }
                self.reloadPrayerData()
            }
            
        }
    }
    
    func reloadPrayerData() {
        answeredPrayers = []
        activePrayers = []
        prayers = []
        sectionHeaders = []
        prayersSortedByCategory = [:]
        
        print("preSortedPrayers.count: \(preSortedPrayers.count)")
        
        for prayer in preSortedPrayers {
            if let prayerIsAnswered = prayer.isAnswered {
                if !prayerIsAnswered {
                    activePrayers.append(prayer)
                } else {
                    answeredPrayers.append(prayer)
                }
            }
        }
        
        if answeredShowing == true {
            prayers = answeredPrayers
        } else {
            prayers = activePrayers
        }
        
        var prayerArray = [CurrentUserPrayer]()
        for prayer in prayers {
            if let category = prayer.prayerCategory {
                if !sectionHeaders.contains(category) {
                    prayerArray = []
                    sectionHeaders.append(category)
                    prayerArray.append(prayer)
                    prayersSortedByCategory[category] = prayerArray
                } else {
                    prayerArray.append(prayer)
                    prayersSortedByCategory[category] = prayerArray
                }
            }
        }
        updateView()
    }
    
    func updateView() {
        if !answeredShowing {
            if activePrayers.count > 0 {
                tableView.isHidden = false
                messageLabel.isHidden = true
            } else {
                messageLabel.text = "There are no saved active prayers"
                tableView.isHidden = true
                messageLabel.isHidden = false
            }
        } else {
            if answeredPrayers.count > 0 {
                tableView.isHidden = false
                messageLabel.isHidden = true
            } else {
                messageLabel.text = "There are no saved answered prayers"
                tableView.isHidden = true
                messageLabel.isHidden = false
            }
        }
        if viewAlreadyAppeared == true {
            tableView.reloadData()
        }
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
        reloadPrayerData()
    }
    
    func showActive() {
        answerButton.titleLabel?.font = UIFont.StyleFile.ToggleInactiveFont
        activeButton.titleLabel?.font = UIFont.StyleFile.ToggleActiveFont
        toggleButton.setBackgroundImage(UIImage(named: "tableToggleLeftSelected.pdf"), for: .normal)
        answeredShowing = false
        if viewAlreadyAppeared == true {
            reloadPrayerData()
        }
    }
    
    @IBAction func timerButtonDidPress(_ sender: Any) {
        TimerStruct().stopTimer(timerButton: timerHeaderButton, titleImageView: titleImage)
    }
    
    @IBAction func markAnsweredSaveDidPress(_ sender: Any) {
        print("pressed save mark answered")
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
        return sectionHeaders[section]
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
        print("sectioncount: \(sectionHeaders.count)")
        return sectionHeaders.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = Int()
        
        let sections = sectionHeaders.count
        for sectionIndexed in 0...sections {
            if sectionIndexed == section {
                let category = sectionHeaders[section]
                if let prayerArray = prayersSortedByCategory[category] {
                    rows = prayerArray.count
                }
            }
        }
        return rows
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
        cell.prayerTextView.text = prayer.prayerText
        
        var lastPrayerString = String()
//        if !answeredShowing {
//            lastPrayerString = Utilities().dayDifference(from: (prayer.timeStamp?.timeIntervalSince1970)!)
//            cell.prayedLastLabel.text = "Last prayed \(lastPrayerString)"
//        }
        
        if !answeredShowing {
            cell.prayedLastLabel.text = "Last prayed temporary placeholder"
        }
        
        var prayerCount = Int()
        if let prayerCountCheck = prayer.prayerCount {
            prayerCount = prayerCountCheck
        }
        var timeVsTimesString = ""
        if prayerCount == 1 {
            timeVsTimesString = "time"
        } else {
            timeVsTimesString = "times"
        }
        
//        cell.prayerCountLabel.text = "Prayed \(prayerCount) \(timeVsTimesString)"
        
        cell.selectionStyle = .none
        markRecentlyPrayed(cell: cell, lastPrayedString: lastPrayerString)
    }
    
//    func configureUnanswered(_ cell: PrayerTableViewCell, at indexPath: IndexPath) {
//        let prayer = fetchedResultsController.object(at: indexPath)
//        cell.prayerTextView.text = prayer.prayerText
//
//        var lastPrayerString = String()
//        if !answeredShowing {
//            lastPrayerString = Utilities().dayDifference(from: (prayer.timeStamp?.timeIntervalSince1970)!)
//            cell.prayedLastLabel.text = "Last prayed \(lastPrayerString)"
//        }
//
//        var timeVsTimesString = ""
//        if prayer.prayerCount == 1 {
//            timeVsTimesString = "time"
//        } else {
//            timeVsTimesString = "times"
//        }
//
//        cell.prayedCountLabel.text = "Prayed \(prayer.prayerCount) \(timeVsTimesString)"
//        cell.selectionStyle = .none
//
//        markRecentlyPrayed(cell: cell, lastPrayedString: lastPrayerString)
//    }
    
    func configureAnswered(_ cell: AnsweredPrayerTableViewCell, at indexPath: IndexPath) {
        let prayer = prayerAtIndexPath(indexPath: indexPath)
        cell.prayerLabel.text = prayer.prayerText
        
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateStyle = .short
//
//        if let date = prayer.lastPrayed {
//            cell.lastPrayedLabel.text = "Answered on \(dateFormatter.string(from: date))"
//        }
        
        cell.lastPrayedLabel.text = "Answered on Temporary Placeholder)"
        
        if let answeredPrayer = prayer.howAnswered {
            cell.howAnsweredLabel.text = answeredPrayer
            print("howAnswered: \(answeredPrayer) for index: \(indexPath)")
        }
        
        var prayerCount = Int()
        if let prayerCountCheck = prayer.prayerCount {
            prayerCount = prayerCountCheck
        }
        var timeVsTimesString = ""
        if prayerCount == 1 {
            timeVsTimesString = "time"
        } else {
            timeVsTimesString = "times"
        }
        cell.prayerCountLabel.text = "Prayed \(prayerCount) \(timeVsTimesString)"
        
//        cell.prayerCountLabel.text = "Prayed \(prayer.prayerCount) \(timeVsTimesString)"
        
        cell.selectionStyle = .none
    }
    
//    func configureAnswered(_ cell: AnsweredPrayerTableViewCell, at indexPath: IndexPath) {
//        let prayer = fetchedResultsController.object(at: indexPath)
//        cell.prayerLabel.text = prayer.prayerText
//
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateStyle = .short
//        if let date = prayer.timeStamp{
//            cell.lastPrayedLabel.text = "Answered on \(dateFormatter.string(from: date))"
//        }
//
//        if let answeredPrayer = prayer.howAnswered {
//            cell.howAnsweredLabel.text = answeredPrayer
//            print("howAnswered: \(answeredPrayer) for index: \(indexPath)")
//        }
//
//        var timeVsTimesString = ""
//        if prayer.prayerCount == 1 {
//            timeVsTimesString = "time"
//        } else {
//            timeVsTimesString = "times"
//        }
//        cell.prayerCountLabel.text = "Prayed \(prayer.prayerCount) \(timeVsTimesString)"
//
//        cell.selectionStyle = .none
//    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .default, title: "Delete") { (action:UITableViewRowAction, indexPath:IndexPath) in
            print("delete at:\(indexPath)")
            let prayer = self.prayerAtIndexPath(indexPath: indexPath)
            
            if let prayerID = prayer.prayerID {
                FirebaseHelper().deletePrayerFromFirebase(prayerID: prayerID, ref: self.ref)
            }
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
    
//    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//        let delete = UITableViewRowAction(style: .default, title: "Delete") { (action:UITableViewRowAction, indexPath:IndexPath) in
//            print("delete at:\(indexPath)")
//            let prayer = self.fetchedResultsController.object(at: indexPath)
//
//            if let prayerID = prayer.prayerID {
//                FirebaseHelper().deletePrayerFromFirebase(prayerID: prayerID, ref: self.ref)
//            }
//
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
//        }
//        delete.backgroundColor = UIColor.StyleFile.WineColor
//
//        if !answeredShowing {
//            let more = UITableViewRowAction(style: .default, title: "Answered") { (action:UITableViewRowAction, indexPath:IndexPath) in
//                self.indexPathToMarkAnswered = indexPath
//                Animations().animateMarkAnsweredPopup(view: self.markAnsweredPopoverView, backgroundButton: self.markAnsweredBackgroundButton, subView: self.markAnsweredSubview, viewController: self, textView: self.markAnsweredTextView)
//            }
//            more.backgroundColor = UIColor.StyleFile.DarkBlueColor
//                return [delete, more]
//
//            }
//        return [delete]
//    }
    
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
    
    func markRecentlyPrayed(cell: PrayerTableViewCell, lastPrayedString: String) {
        if lastPrayedString == "today" {
            cell.prayedLastLabel.textColor = UIColor.StyleFile.TealColor
            cell.prayedLastLabel.font = UIFont.StyleFile.LastPrayedBold
            cell.recentlyPrayed = true
        } else {
            cell.prayedLastLabel.textColor = UIColor.StyleFile.MediumGrayColor
            cell.prayedLastLabel.font = UIFont.StyleFile.LastPrayedMedium
            cell.recentlyPrayed = false
        }
    }
    
    func markPrayed(indexPath: IndexPath) {
        let prayer = prayerAtIndexPath(indexPath: indexPath)
        let newCount = prayer.prayerCount! + 1
        let date = Date()
        if let prayerID = prayer.prayerID {
            FirebaseHelper().markPrayedInFirebase(prayerID: prayerID, newLastPrayedDate: date, newPrayerCount: Int(newCount), ref: ref)
        }
    }
    
//    func markPrayed(indexPath: IndexPath) {
//        let prayer = fetchedResultsController.object(at: indexPath)
//        let newCount = prayer.prayerCount + 1
//        let date = Date()
//        prayer.setValue(newCount, forKey: "prayerCount")
//        prayer.setValue(date, forKey: "timeStamp")
//
//        do {
//            try prayer.managedObjectContext?.save()
//        } catch let error as NSError  {
//            print("Could not save \(error), \(error.userInfo)")
//        }
//
//        if let prayerID = prayer.prayerID {
//            FirebaseHelper().markPrayedInFirebase(prayerID: prayerID, newLastPrayedDate: date, newPrayerCount: Int(newCount), ref: ref)
//        }
//    }
    
    func markAnswered() {
        let prayer = prayerAtIndexPath(indexPath: indexPathToMarkAnswered)
        var howAnswered = String()
        if let answeredPrayer = markAnsweredTextView.text {
            var trimmedText = answeredPrayer.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedText == "" {
                trimmedText = "Undisclosed"
            }
            howAnswered = trimmedText
        }

        if let prayerID = prayer.prayerID {
            FirebaseHelper().markAnsweredInFirebase(prayerID: prayerID, howAnswered: howAnswered, isAnswered: true, ref: ref)
        }
        
        tableView.reloadData()
    }
    
    func prayerAtIndexPath(indexPath: IndexPath) -> CurrentUserPrayer {
        var prayer = CurrentUserPrayer()
        let category = sectionHeaders[indexPath.section]
        if let categoryPrayerArray = prayersSortedByCategory[category] {
            prayer = categoryPrayerArray[indexPath.row]
        }
        print("prayerID: \(prayer.prayerID!)")
        return prayer
    }
    
    
//    func markAnswered() {
//        let prayer = fetchedResultsController.object(at: indexPathToMarkAnswered)
//        prayer.setValue(true, forKey: "isAnswered")
//        var howAnswered = String()
//        if let answeredPrayer = markAnsweredTextView.text {
//            var trimmedText = answeredPrayer.trimmingCharacters(in: .whitespacesAndNewlines)
//            if trimmedText == "" {
//                trimmedText = "Undisclosed"
//            }
//            howAnswered = trimmedText
//        }
//        prayer.setValue(howAnswered, forKey: "howAnswered")
//
//        do {
//            try prayer.managedObjectContext?.save()
//        } catch let error as NSError  {
//            print("Could not save \(error), \(error.userInfo)")
//        }
//
//        if let prayerID = prayer.prayerID {
//            FirebaseHelper().markAnsweredInFirebase(prayerID: prayerID, howAnswered: howAnswered, isAnswered: true, ref: ref)
//        }
//
//        tableView.reloadData()
//    }
    
    @objc func handleNotification(_ notification: NSNotification) {
        TimerStruct().updateTimerButtonLabel(timerButton: timerHeaderButton)
         print("Journal timer update called")
    }
    
    @objc func handleNotification2(_ notification: NSNotification) {
        Animations().endTimerAnimation(timerButton: timerHeaderButton, titleImage: titleImage)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
    }
}
