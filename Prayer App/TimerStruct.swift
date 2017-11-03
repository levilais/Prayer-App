//
//  TimerStruct.swift
//  Prayer App
//
//  Created by Levi on 11/2/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation
import UIKit

class TimerStruct {
    
    // will set and get from UserDefaults
    static var preferredTimerDuration = Int()
    static var seconds = Int()
    
    func resetSeconds() {
        TimerStruct.seconds = TimerStruct.preferredTimerDuration
        print(TimerStruct.seconds)
        print(TimerStruct.preferredTimerDuration)
    }
    
    func timeString(time: TimeInterval) -> String {
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%2i:%02i", minutes, seconds)
    }
    
    enum Duration: String {
        case oneMinute = "oneMinute"
        case fiveMinutes = "fiveMinutes"
        case tenMinutes = "tenMinutes"
    }
    
    func toggleTimerPreferences(buttons: [UIButton], sender: Int) {
        switch sender {
        case 0:
            buttons[0].setBackgroundImage(UIImage(named: "1Selected.pdf"), for: .normal)
            buttons[1].setBackgroundImage(UIImage(named: "5Deselected.pdf"), for: .normal)
            buttons[2].setBackgroundImage(UIImage(named: "10Deselected.pdf"), for: .normal)
            TimerStruct.preferredTimerDuration = 60
            UserDefaultsHelper().savePreferredTimerDuration()
        case 1:
            buttons[0].setBackgroundImage(UIImage(named: "1Deselected.pdf"), for: .normal)
            buttons[1].setBackgroundImage(UIImage(named: "5Selected.pdf"), for: .normal)
            buttons[2].setBackgroundImage(UIImage(named: "10Deselected.pdf"), for: .normal)
            TimerStruct.preferredTimerDuration = 300
            UserDefaultsHelper().savePreferredTimerDuration()
        case 2:
            buttons[0].setBackgroundImage(UIImage(named: "1Deselected.pdf"), for: .normal)
            buttons[1].setBackgroundImage(UIImage(named: "5Deselected.pdf"), for: .normal)
            buttons[2].setBackgroundImage(UIImage(named: "10Selected.pdf"), for: .normal)
            TimerStruct.preferredTimerDuration = 600
            UserDefaultsHelper().savePreferredTimerDuration()
        default:
            print("sender: \(sender)")
        }
    }
    
    func updateTimerPreferencesDisplay(buttons: [UIButton]) {
        switch TimerStruct.preferredTimerDuration {
        case 60:
            buttons[0].setBackgroundImage(UIImage(named: "1Selected.pdf"), for: .normal)
            buttons[1].setBackgroundImage(UIImage(named: "5Deselected.pdf"), for: .normal)
            buttons[2].setBackgroundImage(UIImage(named: "10Deselected.pdf"), for: .normal)
        case 300:
            buttons[0].setBackgroundImage(UIImage(named: "1Deselected.pdf"), for: .normal)
            buttons[1].setBackgroundImage(UIImage(named: "5Selected.pdf"), for: .normal)
            buttons[2].setBackgroundImage(UIImage(named: "10Deselected.pdf"), for: .normal)
        case 600:
            buttons[0].setBackgroundImage(UIImage(named: "1Deselected.pdf"), for: .normal)
            buttons[1].setBackgroundImage(UIImage(named: "5Deselected.pdf"), for: .normal)
            buttons[2].setBackgroundImage(UIImage(named: "10Selected.pdf"), for: .normal)
        default:
            print("No time saved/found")
        }
    }
}
