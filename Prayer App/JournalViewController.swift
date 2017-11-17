//
//  JournalViewController.swift
//  Prayer App
//
//  Created by Levi on 11/5/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import CoreData

class JournalViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    
    // HEADER VIEW
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var titleImage: UIImageView!
    @IBOutlet weak var timerHeaderButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    
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
    let persistentContainer = NSPersistentContainer(name: "Prayer")
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Prayer> = {
        let fetchRequest: NSFetchRequest<Prayer> = Prayer.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "prayerCategory", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.persistentContainer.viewContext, sectionNameKeyPath: #keyPath(Prayer.prayerCategory), cacheName: nil)
        
        let predicate = NSPredicate(format: "isAnswered = \(NSNumber(value:false))")
        fetchedResultsController.fetchRequest.predicate = predicate
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    } ()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        markAnsweredTextView.layer.borderColor = UIColor(red:0.76, green:0.76, blue:0.76, alpha:1.0).cgColor
        markAnsweredTextView.layer.borderWidth = 1.0
        
        persistentContainer.loadPersistentStores { (persistentStoreDescription, error) in
            if let error = error {
                print("Unable to Load Persistent Store")
                print("\(error), \(error.localizedDescription)")
            } else {
                self.updateView()
                do {
                    try self.fetchedResultsController.performFetch()
                } catch {
                    let fetchError = error as NSError
                    print("Unable to Perform Fetch Request")
                    print("\(fetchError), \(fetchError.localizedDescription)")
                }
                self.updateView()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification2(_:)), name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableViewAutomaticDimension
        
        TimerStruct().showTimerIfRunning(timerHeaderButton: timerHeaderButton, titleImage: titleImage)
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
        
        let predicate = NSPredicate(format: "isAnswered = \(NSNumber(value:true))")
        fetchedResultsController.fetchRequest.predicate = predicate
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("fetch wasn't performed")
        }
        
        tableView.reloadData()
        updateView()
    }
    
    func showActive() {
        answerButton.titleLabel?.font = UIFont.StyleFile.ToggleInactiveFont
        activeButton.titleLabel?.font = UIFont.StyleFile.ToggleActiveFont
        toggleButton.setBackgroundImage(UIImage(named: "tableToggleLeftSelected.pdf"), for: .normal)
        answeredShowing = false
        
        let predicate = NSPredicate(format: "isAnswered = \(NSNumber(value:false))")
        fetchedResultsController.fetchRequest.predicate = predicate
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("fetch wasn't performed")
        }
        tableView.reloadData()
        updateView()
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
    
    fileprivate func updateView() {
        if !answeredShowing {
            
            let predicate = NSPredicate(format: "isAnswered = \(NSNumber(value:false))")
            fetchedResultsController.fetchRequest.predicate = predicate
            do {
                try fetchedResultsController.performFetch()
            } catch {
                print("fetch wasn't performed")
            }
            
            var hasPrayers = false
            if let prayers = fetchedResultsController.fetchedObjects {
                hasPrayers = prayers.count > 0
            }
            messageLabel.text = "There are no saved active prayers"
            tableView.isHidden = !hasPrayers
            messageLabel.isHidden = hasPrayers
        } else {
            let predicate = NSPredicate(format: "isAnswered = \(NSNumber(value:true))")
            fetchedResultsController.fetchRequest.predicate = predicate
            do {
                try fetchedResultsController.performFetch()
            } catch {
                print("fetch wasn't performed")
            }
            
            var hasPrayers = false
            if let prayers = fetchedResultsController.fetchedObjects {
                hasPrayers = prayers.count > 0
            }
            messageLabel.text = "There are no saved answered prayers"
            tableView.isHidden = !hasPrayers
            messageLabel.isHidden = hasPrayers
        }
    }
    
    @objc func applicationDidEnterBackground(_ notification: Notification) {
        do {
            try persistentContainer.viewContext.save()
        } catch {
            print("Unable to Save Changes")
            print("\(error), \(error.localizedDescription)")
        }
    }

    @IBAction func prayerIconDidPress(_ sender: Any) {
        _ = navigationController?.popViewController(animated: false)
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        updateView()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            if let indexPath = newIndexPath {
                tableView.insertRows(at: [indexPath], with: .fade)
            }
            break
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            break
        case .update:
            if !answeredShowing {
                if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? PrayerTableViewCell {
                    configureUnanswered(cell, at: indexPath)
                }
            } else {
                if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? AnsweredPrayerTableViewCell {
                    configureAnswered(cell, at: indexPath)
                }
            }
           
            break
        case .move:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            break
        }
    }
    
    // TABLE VIEW DATA SOURCE
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionInfo = fetchedResultsController.sections?[section] else { fatalError("Unexpected Section") }
        sectionTitle = sectionInfo.name
        return sectionInfo.name
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
        guard let sections = fetchedResultsController.sections else { return 0 }
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultsController.sections?[section] else { fatalError("Unexpected Section") }
        return sectionInfo.numberOfObjects
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
        let prayer = fetchedResultsController.object(at: indexPath)
        cell.prayerTextView.text = prayer.prayerText
        
        var lastPrayerString = String()
        if !answeredShowing {
            lastPrayerString = Utilities().dayDifference(from: (prayer.timeStamp?.timeIntervalSince1970)!)
            cell.prayedLastLabel.text = "Last prayed \(lastPrayerString)"
        }
//        else {
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateStyle = .short
//            if let date = prayer.timeStamp{
//                cell.prayedLastLabel.text = "Answered on \(dateFormatter.string(from: date))"
//            }
//        }
        
        var timeVsTimesString = ""
        if prayer.prayerCount == 1 {
            timeVsTimesString = "time"
        } else {
            timeVsTimesString = "times"
        }
        
//        if let how = prayer.howAnswered {
//            print("howAnswered: \(how) for index: \(indexPath)")
//        }
        
        cell.prayedCountLabel.text = "Prayed \(prayer.prayerCount) \(timeVsTimesString)"
        cell.selectionStyle = .none
        
        markRecentlyPrayed(cell: cell, lastPrayedString: lastPrayerString)
    }
    
    func configureAnswered(_ cell: AnsweredPrayerTableViewCell, at indexPath: IndexPath) {
        let prayer = fetchedResultsController.object(at: indexPath)
        cell.prayerLabel.text = prayer.prayerText

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        if let date = prayer.timeStamp{
            cell.lastPrayedLabel.text = "Answered on \(dateFormatter.string(from: date))"
        }
        
        if let answeredPrayer = prayer.howAnswered {
            cell.howAnsweredLabel.text = answeredPrayer
            print("howAnswered: \(answeredPrayer) for index: \(indexPath)")
        }
        
        var timeVsTimesString = ""
        if prayer.prayerCount == 1 {
            timeVsTimesString = "time"
        } else {
            timeVsTimesString = "times"
        }
        cell.prayerCountLabel.text = "Prayed \(prayer.prayerCount) \(timeVsTimesString)"

        cell.selectionStyle = .none
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .default, title: "Delete") { (action:UITableViewRowAction, indexPath:IndexPath) in
            print("delete at:\(indexPath)")
            let prayer = self.fetchedResultsController.object(at: indexPath)
            prayer.managedObjectContext?.delete(prayer)
            print("attempting to delete")
            do {
                try prayer.managedObjectContext?.save()
                print("saved!")
                tableView.reloadData()
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            } catch {
            }
        }
        delete.backgroundColor = UIColor.StyleFile.WineColor
        
        if !answeredShowing {
            let more = UITableViewRowAction(style: .default, title: "Answered") { (action:UITableViewRowAction, indexPath:IndexPath) in
                self.indexPathToMarkAnswered = indexPath
                Animations().animateMarkAnsweredPopup(view: self.markAnsweredPopoverView, backgroundButton: self.markAnsweredBackgroundButton, subView: self.markAnsweredSubview, viewController: self, textView: self.markAnsweredTextView)
            }
            more.backgroundColor = UIColor.StyleFile.DarkBlueColor
                return [delete, more]
            
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
        let prayer = fetchedResultsController.object(at: indexPath)
        let newCount = prayer.prayerCount + 1
        prayer.setValue(newCount, forKey: "prayerCount")
        prayer.setValue(Date(), forKey: "timeStamp")
        do {
            try prayer.managedObjectContext?.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    func markAnswered() {
        let prayer = fetchedResultsController.object(at: indexPathToMarkAnswered)
        prayer.setValue(true, forKey: "isAnswered")
        var howAnswered = String()
        if let answeredPrayer = markAnsweredTextView.text {
            var trimmedText = answeredPrayer.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedText == "" {
                trimmedText = "Undisclosed"
            }
            howAnswered = trimmedText
        }
        prayer.setValue(howAnswered, forKey: "howAnswered")
        
        do {
            try prayer.managedObjectContext?.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
        tableView.reloadData()
    }
    
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
