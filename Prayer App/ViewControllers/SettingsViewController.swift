//
//  SettingsViewController.swift
//  Prayer App
//
//  Created by Levi on 10/27/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import StoreKit
import Firebase
import SDWebImage
import MessageUI

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var titleImage: UIImageView!
    @IBOutlet weak var timerHeaderButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var settingsProfileButtonImage: UIButton!
    @IBOutlet weak var welcomeLabel: UILabel!
    
    var sectionHeaders = ["Timer Duration","Give Feedback","Settings"]
    var selectedRow = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsProfileButtonImage.layer.cornerRadius = settingsProfileButtonImage.frame.size.height / 2
        settingsProfileButtonImage.clipsToBounds = true
        
        setupFooterView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification2(_:)), name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        TimerStruct().showTimerIfRunning(timerHeaderButton: timerHeaderButton, titleImage: titleImage)
        tableView.reloadData()
        
        
        if Auth.auth().currentUser != nil {
            settingsProfileButtonImage = CurrentUser().setProfileImageButton(button: settingsProfileButtonImage)
            settingsProfileButtonImage.isEnabled = true
            welcomeLabel.text = Utilities().greetingString()
        } else {
            settingsProfileButtonImage.isEnabled = false
            settingsProfileButtonImage.setBackgroundImage(UIImage(named: "settingsPrayerIcon.pdf"), for: .normal)
            welcomeLabel.text = "Welcome To Prayer"
        }
    }
    
    @IBAction func profileImageButtonDidPress(_ sender: Any) {
        performSegue(withIdentifier: "settingsToUpdateProfileSegue", sender: self)
    }
    
    @IBAction func timerButtonDidPress(_ sender: Any) {
        TimerStruct().stopTimer(timerButton: timerHeaderButton, titleImageView: titleImage)
    }
    
    func setupFooterView() {
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 230))
        let footerImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: (tableView.tableFooterView?.frame.height)!))
        let footerImage = UIImage(named: "trees.pdf")
        footerImageView.image = footerImage
        footerImageView.contentMode = UIViewContentMode.scaleAspectFill
        tableView.tableFooterView?.addSubview(footerImageView)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionTitle = sectionHeaders[section]
        return sectionTitle
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
        return sectionHeaders.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows = 0
        switch section {
        case 0:
            numberOfRows = 1
        case 1:
            numberOfRows = 2
        case 2:
            numberOfRows = Settings().settingsCategories.count
        default:
            print("need to change number of sections")
        }
        return numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "timerPreferenceCell", for: indexPath) as! TimerPreferenceTableViewCell
            return cell
        case 1:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
                cell.customCellImageView.image = UIImage(named: "reviewImage.pdf")
                cell.isUserInteractionEnabled = true
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
                cell.customCellImageView.image = UIImage(named: "email.pdf")
                cell.isUserInteractionEnabled = true
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
                cell.customCellImageView.isHidden = true
                return cell
            }

        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath) as! SettingsTableViewCell
            if let label = Settings().settingsCategories[indexPath.row]["title"] as? String {
                cell.label.text = label
            }
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
            cell.customCellImageView.isHidden = true
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = CGFloat()
        
        switch indexPath.section {
        case 0:
            height = 80
        default:
            height = 40
        }
        return height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            switch indexPath.row {
            case 0:
                tableView.deselectRow(at: indexPath, animated: true)
                SKStoreReviewController.requestReview()
            case 1:
                tableView.deselectRow(at: indexPath, animated: true)
                if MFMailComposeViewController.canSendMail() {
                    let composeVC = MFMailComposeViewController()
                    composeVC.mailComposeDelegate = self
                    composeVC.setToRecipients(["levilais@gmail.com"])
                    composeVC.setSubject("Prayer Feedback")
                    composeVC.setMessageBody("A note from Prayer: We are always committed to making Prayer the best experience possible.  Please let us know what you think!", isHTML: false)

                    self.present(composeVC, animated: true, completion: nil)
                }
                // do work for launching email here
                print("email")
            default:
                print("default called")
            }
        case 2:
            selectedRow = indexPath.row
            performSegue(withIdentifier: "settingsToDetailSettings", sender: self)
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            break
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        var labelText = ""
        
        switch result {
        case .cancelled:
            print("cancelled")
        case .sent:
            labelText = "Sent!"
        case .saved:
            labelText = "Saved!"
        case .failed:
            print("failed")
        }
        
        controller.dismiss(animated: true) {
            if labelText != "" {
                Animations().showPopup(labelText: labelText, presentingVC: self)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "settingsToDetailSettings" {
            let destinationVC = segue.destination as? SettingsDetailViewController
            destinationVC?.chosenSection = selectedRow
        }
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
    }
}
