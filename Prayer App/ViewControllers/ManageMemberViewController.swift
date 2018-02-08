//
//  ManageMemberViewController.swift
//  Prayer App
//
//  Created by Levi on 12/28/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class ManageMemberViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var ref: DatabaseReference!
    var usersToDisplay = [MembershipUser]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification3(_:)), name: NSNotification.Name(rawValue: "membershipUserDidSet"), object: nil)
        refreshData()
    }
    
    func refreshData() {
        var newUsersToDisplay = [MembershipUser]()
        for membershipUser in CurrentUser.firebaseMembershipUsers {
            if let membershipStatus = membershipUser.membershipStatus {
                if membershipStatus == MembershipUser.currentUserMembershipStatus.member.rawValue {
                    newUsersToDisplay.append(membershipUser)
                }
            }
        }
        usersToDisplay = newUsersToDisplay
        self.tableView.reloadData()
    }

    @IBAction func doneButtonDidPress(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersToDisplay.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "manageMembersTableViewCell", for: indexPath) as! ManageMembersTableViewCell
        
        let user = usersToDisplay[indexPath.row]
        
        if let profileImage = user.profileImageAsImage {
            cell.profileImage.image = profileImage
        }
        
        let fullName = user.getFullName(user: user as CustomUser)
        cell.leaveCircleButton.tag = indexPath.row
        cell.nameLabel.text = fullName
        cell.leaveCircleButton.addTarget(self, action: #selector(deleteUserFromCircle(sender:)), for: .touchUpInside)
        
        return cell
    }
    
    @objc func deleteUserFromCircle(sender: UIButton) {
        let memberToDelete = usersToDisplay[sender.tag]
        MembershipUser().leaveUsersCircle(membershipUser: memberToDelete)
        refreshData()
    }
    
    @objc func handleNotification3(_ notification: NSNotification) {
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {
                self.refreshData()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "membershipUserDidSet"), object: nil)
    }

}
