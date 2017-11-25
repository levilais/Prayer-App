//
//  SettingsClass.swift
//  Prayer App
//
//  Created by Levi on 11/21/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation
import UIKit

class Settings {

    var settingsCategories = [
        [
        "title": "Account",
        "subCategories":
            [
            ["subTitle":"Log In","actionType":0],
            ["subTitle":"Delete Account","actionType":1]
            ]
        ],
        
        [
        "title": "Friends",
        "subCategories":
            [
            ["subTitle":"Connect To Contacts","actionType":0]
            ]
        ]
    ]
    
    enum ActionType: Int {
        case toggle = 0
        case button = 1
        case image = 2
    }
}

