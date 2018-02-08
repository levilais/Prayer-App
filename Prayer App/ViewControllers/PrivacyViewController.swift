//
//  PrivacyViewController.swift
//  Prayer App
//
//  Created by Levi on 2/7/18.
//  Copyright © 2018 App Volks. All rights reserved.
//

import UIKit
import WebKit

class PrivacyViewController: UIViewController, WKUIDelegate {

    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let pdfURL = Bundle.main.url(forResource: "termsAndPrivacy", withExtension: "pdf", subdirectory: nil, localization: nil)  {
            do {
                let data = try Data(contentsOf: pdfURL)
                webView.load(data, mimeType: "application/pdf", characterEncodingName:"", baseURL: pdfURL.deletingLastPathComponent())
                view.addSubview(webView)
            }
            catch {
                // catch errors here
            }
            
        }
        
//        let myURL = URL(string: "https://www.apple.com")
//        let myRequest = URLRequest(url: myURL!)
//        webView.load(myRequest)
    }

    @IBAction func doneButtonDidPress(_ sender: Any) {
        print("done pressed")
        dismiss(animated: true, completion: nil)
    }

}
