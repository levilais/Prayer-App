//
//  ManageMembersTableViewCell.swift
//  Prayer App
//
//  Created by Levi on 12/28/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit

class ManageMembersTableViewCell: UITableViewCell {

    @IBOutlet weak var leaveCircleButton: UIButton!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        self.profileImage.layer.cornerRadius = profileImage.frame.size.height / 2
        self.profileImage.clipsToBounds = true
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        

        // Configure the view for the selected state
    }

}
