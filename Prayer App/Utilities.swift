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
    func dayDifference(from interval: TimeInterval) -> String {
        let calendar = NSCalendar.current
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
        
        print("adjustedRect.midX: \(boundingRect.midX), adjustedRect.midY: \(boundingRect.midY)")
        
        return adjustedRect
    }
}

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
