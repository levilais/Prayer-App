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
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabel: UILabel!
    
    var sectionTitle = String()
    let persistentContainer = NSPersistentContainer(name: "Prayer")
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Prayer> = {
        let fetchRequest: NSFetchRequest<Prayer> = Prayer.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "prayerCategory", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.persistentContainer.viewContext, sectionNameKeyPath: #keyPath(Prayer.prayerCategory), cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    } ()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    fileprivate func updateView() {
        var hasPrayers = false
        if let prayers = fetchedResultsController.fetchedObjects {
            print("prayers.count: \(prayers.count)")
            hasPrayers = prayers.count > 0
        }
    
        tableView.isHidden = !hasPrayers
        messageLabel.isHidden = hasPrayers
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
            if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? PrayerTableViewCell {
                configure(cell, at: indexPath)
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
    
    // MARK: - Table view data source
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
                tableViewHeaderFooterView.contentView.backgroundColor = UIColor(red:0.87, green:0.87, blue:0.87, alpha:1.0)
                tableViewHeaderFooterView.textLabel?.font = UIFont(name: "Baskerville-SemiBold", size: 20)
                tableViewHeaderFooterView.textLabel?.textColor = UIColor(red:0.33, green:0.33, blue:0.33, alpha:1.0)
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "prayerCell", for: indexPath) as? PrayerTableViewCell else {
            fatalError("Unexpected Index Path")
        }
        configure(cell, at: indexPath)
        return cell
    }
    
    func configure(_ cell: PrayerTableViewCell, at indexPath: IndexPath) {
        let prayer = fetchedResultsController.object(at: indexPath)
        cell.prayerTextView.text = prayer.prayerText
        
        let daysAgoString = Utilities().dayDifference(from: (prayer.timeStamp?.timeIntervalSince1970)!)
        cell.prayedLastLabel.text = "Last prayed \(daysAgoString)"
        
        var timeVsTimesString = ""
        if prayer.prayerCount == 1 {
            timeVsTimesString = "time"
        } else {
            timeVsTimesString = "times"
        }
        
        cell.prayedCountLabel.text = "Prayed \(prayer.prayerCount) \(timeVsTimesString)"
        cell.selectionStyle = .none
        
        markRecentlyPrayed(cell: cell, lastPrayedString: daysAgoString)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let prayer = fetchedResultsController.object(at: indexPath)
            prayer.managedObjectContext?.delete(prayer)
            print("attempting to delete")
            do {
                try prayer.managedObjectContext?.save()
                print("saved!")
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            } catch {
            }
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let cell = tableView.cellForRow(at: indexPath) as? PrayerTableViewCell
        var recentPrayed = false
        var amenAction = UIContextualAction()
        
        if let recentlyPrayed = cell?.recentlyPrayed {
            recentPrayed = recentlyPrayed
        }
        
        if recentPrayed == false {
            amenAction = UIContextualAction(style: .normal, title:  "Amen", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                self.markPrayed(indexPath: indexPath)
                success(true)
                
                
            })
            return UISwipeActionsConfiguration(actions: [amenAction])
        } else {
            return nil
        }
    }
    
    func markRecentlyPrayed(cell: PrayerTableViewCell, lastPrayedString: String) {
        if lastPrayedString == "today" {
            cell.prayerTextView.textColor = UIColor.lightGray
            cell.recentlyPrayed = true
        } else {
            cell.prayerTextView.textColor = UIColor.black
            cell.recentlyPrayed = false
        }
    }
    
    func markPrayed(indexPath: IndexPath) {
        let prayer = fetchedResultsController.object(at: indexPath)
        print(prayer.prayerCount)
        let newCount = prayer.prayerCount + 1
        prayer.setValue(newCount, forKey: "prayerCount")
        prayer.setValue(Date(), forKey: "timeStamp")
        print("attempting to set new time stamp")
        do {
            try prayer.managedObjectContext?.save()
            print("saved!")
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        } catch {
        }
    }
}
