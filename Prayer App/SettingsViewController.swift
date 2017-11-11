//
//  SettingsViewController.swift
//  Prayer App
//
//  Created by Levi on 10/27/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import StoreKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var imageNames: [String] = ["swipeToSend.pdf","swipeToSave.pdf"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell", for: indexPath) as! HeaderTableViewCell
            cell.label.text = "Timer Duration"
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "timerPreferenceCell", for: indexPath) as! TimerPreferenceTableViewCell
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell", for: indexPath) as! HeaderTableViewCell
            cell.label.text = "How To"
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
            cell.customCellImageView.image = UIImage(named: imageNames[0])
            return cell
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
            cell.customCellImageView.image = UIImage(named: imageNames[1])
            return cell
        case 5:
            let cell = tableView.dequeueReusableCell(withIdentifier: "headerCell", for: indexPath) as! HeaderTableViewCell
            cell.label.text = "Review"
            return cell
        case 6:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
            cell.customCellImageView.image = UIImage(named: "reviewImage.pdf")
            cell.isUserInteractionEnabled = true
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
            cell.customCellImageView.isHidden = true
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = CGFloat()
        
        switch indexPath.row {
        case 0,2,5:
            height = 30
        case 1:
            height = 80
        case 3,4,6:
            height = 40
        default:
            height = 30
        }
        return height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 6:
            tableView.deselectRow(at: indexPath, animated: true)
            SKStoreReviewController.requestReview()
        default:
            break
        }
    }
    
    @IBAction func settingsButtonDidPress(_ sender: Any) {
        _ = navigationController?.popViewController(animated: false)
    }
}
