//
//  Utilities.swift
//  Prayer App
//
//  Created by Levi on 11/4/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation
import UIKit

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
