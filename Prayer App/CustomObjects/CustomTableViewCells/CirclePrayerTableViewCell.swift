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
    @IBOutlet weak var whoAgreedInPrayerLabel: UILabel!
    @IBOutlet weak var agreeButton: CellButton!
        
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        self.selectionStyle = .none
        self.profileImageView.clipsToBounds = true
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.height / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
