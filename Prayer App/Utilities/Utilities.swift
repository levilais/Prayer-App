//
//  Utilities.swift
//  Prayer App
//
//  Created by Levi on 11/4/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation
import UIKit

class Utilities {
    func showAlert(title: String, message: String, vc: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        vc.present(alert, animated: true, completion: nil)
    }
    
    func greetingString() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        var greeting = String()
        if hour >= 0 && hour < 12 {
            greeting = "Good morning, "
        } else if hour >= 12 && hour < 17 {
            greeting = "Good afternoon, "
        } else if hour >= 17 {
            greeting = "Good evening, "
        }
        return greeting
    }
    
    func dayDifference(timeStampAsDouble: Double) -> String {
        let calendar = NSCalendar.current
        let interval = timeStampAsDouble / 1000
        let date = Date(timeIntervalSince1970: interval)
        if calendar.isDateInYesterday(date) { return "yesterday" }
        else if calendar.isDateInToday(date) { return "today" }
        else {
            let startOfNow = calendar.startOfDay(for: Date())
            let startOfTimeStamp = calendar.startOfDay(for: date)
            let components = calendar.dateComponents([.day], from: startOfNow, to: startOfTimeStamp)
            let day = components.day!
            if day < 1 { return "\(abs(day)) days ago" }
            else { return "In \(day) days" }
        }
    }
    
    func dayAnswered(timeStampAsDouble: Double) -> String {
        var dateString = String()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let interval = timeStampAsDouble / 1000
        let date = Date(timeIntervalSince1970: interval)
        dateString = "Answered on \(dateFormatter.string(from: date))"
        return dateString
    }
    
    func setupTextFieldLook(textField: UITextField) {
        let myColor: UIColor = UIColor.lightGray
        textField.layer.borderColor = myColor.cgColor
        textField.layer.borderWidth = 0.5
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = UITextFieldViewMode.always
    }
    
    func formattedEmailString(emailTextFieldString: String?) -> String {
        var email = String()
        if let emailCheck = emailTextFieldString {
            let capitalizedText = emailCheck.lowercased()
            email = capitalizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return email
    }
    
    func hasEmailFormat(emailString: String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        if emailPredicate.evaluate(with: emailString) {
            return true
        } else {
            return false
        }
    }
}

extension UITextView {
    func boundingRectForCharacterRange(index: Int) -> CGRect? {
        let range = NSRange(location: index, length: 1)
        guard let attributedText = attributedText else { return nil }
        
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: bounds.size)
        
        layoutManager.addTextContainer(textContainer)
        var glyphRange = NSRange()
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
        
        let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        let adjustedRect = CGRect(x: boundingRect.minX, y: boundingRect.minY + boundingRect.height / 2 - 1, width: boundingRect.width, height: boundingRect.height)
        
        return adjustedRect
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAway() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}


