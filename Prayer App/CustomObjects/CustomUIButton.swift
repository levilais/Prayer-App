//
//  CustomUIButton.swift
//  Prayer App
//
//  Created by Levi on 11/22/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit

class CustomUIButton: UIButton {
    var drawCount = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = CGFloat(self.frame.size.height / 2)
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.StyleFile.DarkGrayColor.cgColor
        self.layer.backgroundColor = UIColor.clear.cgColor
        
        self.setTitleColor(UIColor.StyleFile.DarkGrayColor, for: .normal)
        self.titleLabel?.font = UIFont.StyleFile.BorderedButtonFont
        self.titleLabel?.adjustsFontSizeToFitWidth = true
        self.setTitle(self.titleLabel?.text?.capitalized, for: .normal)
    }
    
    override func draw(_ rect: CGRect) {
        if drawCount == 0 {
            self.sizeToFit()
            let width = self.frame.size.width + 20
            self.frame = CGRect(x: self.frame.minX - 20, y: self.frame.minY, width: width, height: self.frame.size.height)
            drawCount += 1
        }
    }
}
