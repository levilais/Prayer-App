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
    @IBOutlet weak var agreeButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
