//
//  PopupViewController.swift
//  Prayer App
//
//  Created by Levi on 12/7/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit

class PopupViewController: UIViewController {
    @IBOutlet weak var popupBackground: UIView!
    @IBOutlet weak var labelBackground: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var topContraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomConstraint.constant = bottomConstraint.constant + 50
        topContraint.constant = topContraint.constant + 50
    }
}
