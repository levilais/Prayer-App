//
//  AnsweredPrayerTableViewCell.swift
//  Prayer App
//
//  Created by Levi on 11/14/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit

class AnsweredPrayerTableViewCell: UITableViewCell {

    @IBOutlet weak var lastPrayedLabel: UILabel!
    @IBOutlet weak var prayerCountLabel: UILabel!
    @IBOutlet weak var howAnsweredLabel: UILabel!
    @IBOutlet weak var prayerLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        let textColor = UIColor.StyleFile.DarkGrayColor
        self.prayerLabel.textColor = textColor
        self.howAnsweredLabel.textColor = textColor
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
