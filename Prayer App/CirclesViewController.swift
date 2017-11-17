//
//  CirclesViewController.swift
//  Prayer App
//
//  Created by Levi on 11/16/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit

class CirclesViewController: UIViewController {

    @IBOutlet weak var titleImage: UIImageView!
    @IBOutlet weak var timerHeaderButton: UIButton!
    @IBOutlet weak var headerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification(_:)), name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotification2(_:)), name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
        TimerStruct().showTimerIfRunning(timerHeaderButton: timerHeaderButton, titleImage: titleImage)
    }
    
    @IBAction func timerButtonDidPress(_ sender: Any) {
        TimerStruct().stopTimer(timerButton: timerHeaderButton, titleImageView: titleImage)
    }
    
    @objc func handleNotification(_ notification: NSNotification) {
        TimerStruct().updateTimerButtonLabel(timerButton: timerHeaderButton)
         print("Circles timer update called")
    }
    
    @objc func handleNotification2(_ notification: NSNotification) {
        Animations().endTimerAnimation(timerButton: timerHeaderButton, titleImage: titleImage)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerSecondsChanged"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timerExpiredIsTrue"), object: nil)
    }
}
