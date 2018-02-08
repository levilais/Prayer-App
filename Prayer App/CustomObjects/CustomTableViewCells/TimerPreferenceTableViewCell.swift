//
//  TimerPreferenceTableViewCell.swift
//  Prayer App
//
//  Created by Levi on 11/2/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit

class TimerPreferenceTableViewCell: UITableViewCell {

    @IBOutlet var timerButtons: [UIButton]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        self.selectionStyle = .none
        TimerStruct().updateTimerPreferencesDisplay(buttons: timerButtons)
    }
    
    @IBAction func timerButtonPressed(_ sender: Any) {
        if let tag = (sender as AnyObject).tag {
            TimerStruct().toggleTimerPreferences(buttons: timerButtons, sender: tag)
        }
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
