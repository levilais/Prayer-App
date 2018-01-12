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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification3(_:)), name: NSNotification.Name(rawValue: "membershipUserDidSet"), object: nil)
    }

    @IBAction func doneButtonDidPress(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CurrentUser.firebaseMembershipUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "manageMembersTableViewCell", for: indexPath) as! ManageMembersTableViewCell
        
        let user = CurrentUser.firebaseMembershipUsers[indexPath.row]
        
        if let profileImage = user.profileImageAsImage {
            print("got image as UIImage")
            cell.profileImage.image = profileImage
        }
        
        let fullName = user.getFullName(user: user as User)
        cell.nameLabel.text = fullName
        cell.leaveCircleButton.addTarget(self, action: #selector(deleteUserFromCircle(sender:)), for: .touchUpInside)
        
        return cell
    }
    
    @objc func deleteUserFromCircle(sender: UIButton) {
        let memberToDelete = CurrentUser.firebaseMembershipUsers[sender.tag]
        if let memberToDeleteID = memberToDelete.userID {
            if let userID = Auth.auth().currentUser?.uid {
                ref.child("users").child(memberToDeleteID).child("circleUsers").child(userID).removeValue { error, _ in
                    if let error = error {
                        print("error \(error.localizedDescription)")
                    }
                }
                ref.child("users").child(userID).child("memberships").child(memberToDeleteID).removeValue { error, _ in
                    if let error = error {
                        print("error \(error.localizedDescription)")
                    }
                }
//                CurrentUser.membershipUserPrayers.removeAll()
            }
        }
    }
    
    @objc func handleNotification3(_ notification: NSNotification) {
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "membershipUserDidSet"), object: nil)
    }

}
