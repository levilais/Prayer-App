//
//  PrayerTableViewCell.swift
//  Prayer App
//
//  Created by Levi on 11/5/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit

class PrayerTableViewCell: UITableViewCell {

    @IBOutlet weak var prayerTextView: UITextView!
    @IBOutlet weak var prayedLastLabel: UILabel!
    @IBOutlet weak var prayedCountLabel: UILabel!
    
    var labelArray = [UILabel]()
    var recentlyPrayed = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let textColor = UIColor.StyleFile.DarkGrayColor
        self.prayerTextView.textColor = textColor
        self.backgroundColor = .clear
        self.selectionStyle = .none
    }
    
    override func prepareForReuse() {
        for label in labelArray {
            label.removeFromSuperview()
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func updateCellToShowIfRecentlyPrayed(cell: PrayerTableViewCell, lastPrayedString: String) {
        if lastPrayedString == "today" {
            cell.prayedLastLabel.textColor = UIColor.StyleFile.TealColor
            cell.prayedLastLabel.font = UIFont.StyleFile.LastPrayedBold
            cell.recentlyPrayed = true
        } else {
            cell.prayedLastLabel.textColor = UIColor.StyleFile.MediumGrayColor
            cell.prayedLastLabel.font = UIFont.StyleFile.LastPrayedMedium
            cell.recentlyPrayed = false
        }
    }

}
