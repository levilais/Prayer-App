//
//  SettingsTableViewCell.swift
//  Prayer App
//
//  Created by Levi on 11/19/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {

    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        self.selectionStyle = .none
    }

    @IBAction func buttonDidPress(_ sender: Any) {
        print("button pressed")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
