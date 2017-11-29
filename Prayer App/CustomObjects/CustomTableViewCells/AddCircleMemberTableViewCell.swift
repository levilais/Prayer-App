//
//  AddCircleMemberTableViewCell.swift
//  Prayer App
//
//  Created by Levi on 11/26/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit

class AddCircleMemberTableViewCell: UITableViewCell {

    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var inviteButton: CustomUIButton!
    @IBOutlet weak var inviteSentButton: CustomUIButton!
    @IBOutlet weak var profileImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        self.profileImageView.clipsToBounds = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
