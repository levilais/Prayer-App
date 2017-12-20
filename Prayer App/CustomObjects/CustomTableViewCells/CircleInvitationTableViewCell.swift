//
//  CircleInvitationTableViewCell.swift
//  Prayer App
//
//  Created by Levi on 12/19/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit

class CircleInvitationTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var invitationSinceLabel: UILabel!
    @IBOutlet weak var invitationLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var declineButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .clear
        profileImage.layer.cornerRadius = profileImage.frame.size.height / 2
        profileImage.clipsToBounds = true
        self.selectionStyle = .none
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
