//
//  JournalViewController.swift
//  Prayer App
//
//  Created by Levi on 11/5/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import CoreData

class JournalViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!

    var prayers: [NSManagedObject] = [NSManagedObject]()
    var prayersByCategory: Array<[NSManagedObject]> = Array<[NSManagedObject]>()
    
    var prayerCategoryHeadersHard = ["Personal","Julie","Our Marriage"]
    var prayersByCategoryHard: [Int: [String]] = [:]
    
    var prayer1Hard = ["Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore ","Last prayed 3 days ago","Prayed 5 times"]
    var prayer2Hard = ["Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore ","Last prayed 1 day ago","Prayed 4 times"]
    var prayer3Hard = ["Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore ","Last prayed 1 week ago","prayed 5 times"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        prayersByCategory = [0 : prayer1, 1 : prayer2, 2 : prayer3]
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableViewAutomaticDimension
        
        if let results = CoreDataHelper().getPrayers() {
            prayers = results
        }
        
        let prayer = prayers[0]
        if let prayerTextString = prayer.value(forKey: "prayerText") as? String {
            print("prayerTextString: \(prayerTextString)")
        }
        
//        tableView.reloadData()
    }


    @IBAction func prayerIconDidPress(_ sender: Any) {
        dismiss(animated: false, completion: nil)
    }
    
    // MARK: - Table view data source
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor(red:0.78, green:0.78, blue:0.78, alpha:1.0)
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: self.view.frame.width - 20, height: 30))
//        label.text = prayerCategoryHeaders[section]
        label.font = UIFont(name: "Baskerville", size: 20)
        view.addSubview(label)
        
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return  prayers.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prayers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "prayerCell", for: indexPath) as! PrayerTableViewCell
        
//        if let prayerDataForCategory = prayersByCategory[indexPath.section] {
//            cell.prayerTextView.text = prayerDataForCategory[0]
//            cell.prayedLastLabel.text = prayerDataForCategory[1]
//            cell.prayedCountLabel.text = prayerDataForCategory[2]
//        }
        
//        swipeRight.direction = UISwipeGestureRecognizerDirection.right
//        self.tableView.cellForRow(at: indexPath)?.addGestureRecognizer(swipeRight)
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
        {
            let amenAction = UIContextualAction(style: .normal, title:  "Amen", handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
                print("Attempted animation")
                if let cell = self.tableView.cellForRow(at: indexPath) as? PrayerTableViewCell {
                    cell.prayerTextView.textColor = UIColor.lightGray
                }
                
                success(true)
            })
            return UISwipeActionsConfiguration(actions: [amenAction])
        }
}
