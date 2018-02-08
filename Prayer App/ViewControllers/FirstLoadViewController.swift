//
//  FirstLoadViewController.swift
//  Prayer App
//
//  Created by Levi on 12/2/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit

class FirstLoadViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if Loads.firstLoadPresented == true {
            self.dismiss(animated: false, completion: nil)
        }
        Loads.firstLoadPresented = true
        UserDefaultsHelper().saveLoad()
    }

    @IBAction func loginDidPress(_ sender: Any) {
        performSegue(withIdentifier: "firstLoadToLoginSegue", sender: self)
    }
    
    @IBAction func signUpDidPress(_ sender: Any) {
        performSegue(withIdentifier: "firstLoadToSignupSegue", sender: self)
    }
    
    @IBAction func maybeLaterDidPress(_ sender: Any) {
        self.view.window!.rootViewController?.dismiss(animated: false, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? LoginViewController {
            if segue.identifier == "firstLoadToSignupSegue" {
                vc.signupShowing = true
            } else if segue.identifier == "firstLoadToLoginSegue" {
                vc.signupShowing = false
            }
            vc.firstLoadSignUp = true
        }
    }
}
