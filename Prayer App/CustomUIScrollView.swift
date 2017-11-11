//
//  CustomUIScrollView.swift
//  Prayer App
//
//  Created by Levi on 11/9/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit

class CustomUIScrollView: UIScrollView {
    override func touchesShouldCancel(in view: UIView) -> Bool {
        if (view is UIButton) {
            return true
        }
        return super.touchesShouldCancel(in: view)
    }
}
