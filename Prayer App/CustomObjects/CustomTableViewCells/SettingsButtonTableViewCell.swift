//
//  SettingsButtonTableViewCell.swift
//  Prayer App
//
//  Created by Levi on 11/22/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit

class SettingsButtonTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var actionButton: CustomUIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
