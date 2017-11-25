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
        
        //TODO: Code for our button
//        let bthWidth = 200
//        let btnHeight = 60
//
//        self.frame.size = CGSize(width: bthWidth, height: btnHeight)
//        self.frame.origin = CGPoint(x: (((superview?.frame.width)! / 2) - (self.frame.width / 2)), y: self.frame.origin.y)
        
        
        self.layer.cornerRadius = CGFloat(self.frame.size.height / 2)
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.StyleFile.DarkGrayColor.cgColor
        self.layer.backgroundColor = UIColor.clear.cgColor
        
        self.setTitleColor(UIColor.StyleFile.DarkGrayColor, for: .normal)
        self.titleLabel?.font = UIFont.StyleFile.BorderedButtonFont
        self.titleLabel?.adjustsFontSizeToFitWidth = true
        self.setTitle(self.titleLabel?.text?.capitalized, for: .normal)
    }
    
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        if drawCount == 0 {
            self.sizeToFit()
            let width = self.frame.size.width + 20
            self.frame = CGRect(x: self.frame.minX - 20, y: self.frame.minY, width: width, height: self.frame.size.height)
            drawCount += 1
        }
    }
}
