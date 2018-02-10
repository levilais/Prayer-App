//
//  ConnectionTracker.swift
//  Prayer App
//
//  Created by Levi on 2/10/18.
//  Copyright © 2018 App Volks. All rights reserved.
//

import Foundation
import UIKit


class ConnectionTracker {
    static var isConnected: Bool? {
        didSet {
            if let connection = ConnectionTracker.isConnected {
                if connection {
                    print("became connected")
                } else {
                    print("became disconnected")
                }
            }
        }
    }
    
    func presentNotConnectedAlert(messageDirections: String, viewController: UIViewController) {
        let alert = UIAlertController(title: "No Connectection Detected", message: messageDirections, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        viewController.present(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.StyleFile.DarkGrayColor
    }
}
