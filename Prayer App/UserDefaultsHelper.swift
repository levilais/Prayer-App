//
//  UserDefaultsHelper.swift
//  Prayer App
//
//  Created by Levi on 10/25/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation

class UserDefaultsHelper {
    func saveLoad() {
         UserDefaults.standard.set(Loads.loadCount, forKey: "loads")
    }
    func getLoads() {
        if let loads = UserDefaults.standard.object(forKey: "loads") as? Int {
            Loads.loadCount = loads
        }
    }
    
    func savePreferredTimerDuration() {
        UserDefaults.standard.set(TimerStruct.preferredTimerDuration, forKey: "preferredTimerDuration")
    }
    
    func getPreferredTimerDuration() {
        if let preferredTimerDuration = UserDefaults.standard.object(forKey: "preferredTimerDuration") as? Int {
            TimerStruct.preferredTimerDuration = preferredTimerDuration
        } else {
            TimerStruct.preferredTimerDuration = 60
        }
    }
}
