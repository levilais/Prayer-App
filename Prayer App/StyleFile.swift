//
//  StyleFile.swift
//  Prayer App
//
//  Created by Levi on 11/16/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    struct StyleFile {
        static let BackgroundColor = UIColor(red:0.93, green:0.93, blue:0.93, alpha:1.0)
        static let CategoryButtonSelectedColor = UIColor(red:0.75, green:0.75, blue:0.75, alpha:1.0)
        static let DarkGrayColor = UIColor(red:0.33, green:0.33, blue:0.33, alpha:1.0)
        static let LightGrayColor = UIColor(red:0.87, green:0.87, blue:0.87, alpha:1.0)
        static let GoldColor = UIColor(red:0.67, green:0.65, blue:0.58, alpha:1.0)
        static let TealColor = UIColor(red:0.58, green:0.66, blue:0.67, alpha:1.0)
        static let DarkBlueColor = UIColor(red:0.00, green:0.15, blue:0.26, alpha:1.0)
        static let WineColor = UIColor(red:0.65, green:0.23, blue:0.31, alpha:1.0)
    }
}

extension UIFont {
    struct StyleFile {
        static let ButtonFont = UIFont(name: "Baskerville", size: 15)
        static let SectionHeaderFont = UIFont(name: "Baskerville-SemiBold", size: 20)
        static let ToggleActiveFont = UIFont(name: "Baskerville-SemiBold", size: 17)
        static let ToggleInactiveFont = UIFont(name: "Baskerville", size: 17)
        static let ButtonTimerFont = UIFont(name: "HelveticaNeue-Thin", size: 20)
    }
}

