//
//  CirclePrayerTableViewCell.swift
//  Prayer App
//
//  Created by Levi on 12/21/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit

class CirclePrayerTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var prayerRequestedDate: UILabel!
    @IBOutlet weak var prayerTextLabel: UILabel!
    @IBOutlet var senderPrayerCircleMembers: [UIImageView]!
    @IBOutlet weak var whoAgreedInPrayerLabel: UILabel!
    @IBOutlet weak var agreeButton: CellButton!
    
    @IBOutlet var senderPrayerCircleMembersTintImage: [UIImageView]!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        self.selectionStyle = .none
        
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        
        for circleMembersImageView in senderPrayerCircleMembers {
            circleMembersImageView.layer.cornerRadius = circleMembersImageView.frame.height / 2
            circleMembersImageView.clipsToBounds = true
        }
        
        for circleMembersImageTintView in senderPrayerCircleMembersTintImage {
            circleMembersImageTintView.layer.cornerRadius = circleMembersImageTintView.frame.height / 2
            circleMembersImageTintView.clipsToBounds = true
            circleMembersImageTintView.backgroundColor = UIColor.StyleFile.TealColor
            circleMembersImageTintView.alpha = 0.5
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
