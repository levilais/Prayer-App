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
    static var timer = Timer()
    static var timerIsRunning = false
    static var preferredTimerDuration = Int()
    static var timerExpired = false {
        didSet {
            if timerExpired == true {
                let expirationDict:[String: Bool] = ["timerExpired": timerExpired]
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil, userInfo: expirationDict)
            }
        }
    }
    
    static var seconds = Int() {
        didSet  {
            let timerDict:[String: Int] = ["timerSeconds": seconds]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil, userInfo: timerDict)
        }
    }
    
    func startTimer(timerButton: UIButton, titleImageView: UIImageView) {
        TimerStruct().resetSeconds()
        titleImageView.isHidden = true
        timerButton.setTitle(TimerStruct().timeString(time: TimeInterval(TimerStruct.seconds)), for: .normal)
        timerButton.alpha = 1
        timerButton.isHidden = false
        TimerStruct.timerIsRunning = true
        TimerStruct().runTimer()
    }
    
    @objc func updateTimer() {
        if TimerStruct.seconds < 1 {
            TimerStruct.timer.invalidate()
            TimerStruct.timerIsRunning = false
            TimerStruct.timerExpired = true
        } else {
            TimerStruct.seconds -= 1
        }
    }
    
    func updateTimerButtonLabel(timerButton: UIButton) {
        UIView.performWithoutAnimation {
            timerButton.setTitle(TimerStruct().timeString(time: TimeInterval(TimerStruct.seconds)), for: .normal)
            timerButton.layoutIfNeeded()
        }
    }
    
    func runTimer() {
        TimerStruct.timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(TimerStruct.updateTimer)), userInfo: nil, repeats: true)
    }
    
    @objc func stopTimer(timerButton: UIButton, titleImageView: UIImageView) {
        titleImageView.isHidden = false
        timerButton.isHidden = true
        TimerStruct.timerIsRunning = false
        TimerStruct.timer.invalidate()
        UIView.performWithoutAnimation {
            timerButton.setTitle("\(TimerStruct.seconds)", for: .normal)
            timerButton.layoutIfNeeded()
        }
    }

    func resetSeconds() {
        TimerStruct.seconds = TimerStruct.preferredTimerDuration
    }
    
    func timeString(time: TimeInterval) -> String {
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%2i:%02i", minutes, seconds)
    }
    
    func showTimerIfRunning(timerHeaderButton: UIButton, titleImage: UIImageView) {
        if TimerStruct.timerIsRunning {
            titleImage.isHidden = true
            UIView.performWithoutAnimation {
                timerHeaderButton.setTitle(TimerStruct().timeString(time: TimeInterval(TimerStruct.seconds)), for: .normal)
                timerHeaderButton.isHidden = false
                timerHeaderButton.layoutIfNeeded()
            }
            
        } else {
            titleImage.isHidden = false
            timerHeaderButton.isHidden = true
        }
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
