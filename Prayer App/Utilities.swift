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
    
    func setTabbar() -> UITabBarController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController = UITabBarController()
                
        let HomeViewController = storyboard.instantiateViewController(withIdentifier: "HomeViewController") // 1st tab bar viewcontroller
        let JournalViewController = storyboard.instantiateViewController(withIdentifier: "JournalViewController") // 2nd tab bar viewcontroller
        let MainViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController") // 3rd tab bar viewcontroller
        let CirclesViewController = storyboard.instantiateViewController(withIdentifier: "CirclesViewController") // 4th tab bar viewcontroller
        let SettingsViewController = storyboard.instantiateViewController(withIdentifier: "SettingsViewController") // 5th tab bar viewcontroller
        
        // all viewcontroller embedded navigationbar
        let navHome = UINavigationController(rootViewController: HomeViewController)
        let navJournal = UINavigationController(rootViewController: JournalViewController)
        let navMain = UINavigationController(rootViewController: MainViewController)
        let navCircles = UINavigationController(rootViewController: CirclesViewController)
        let navSettings = UINavigationController(rootViewController: SettingsViewController)
        
        // all viewcontroller navigationbar hidden
        navHome.setNavigationBarHidden(true, animated: false)
        navJournal.setNavigationBarHidden(true, animated: false)
        navMain.setNavigationBarHidden(true, animated: false)
        navCircles.setNavigationBarHidden(true, animated: false)
        navSettings.setNavigationBarHidden(true, animated: false)
        
        
        tabBarController.viewControllers = [navHome,navJournal,navMain,navCircles,navSettings]
        
        let tabBar = tabBarController.tabBar
        tabBar.barTintColor = UIColor.black
        tabBar.backgroundColor = UIColor.black
        tabBar.tintColor = UIColor(red: 43/255, green: 180/255, blue: 0/255, alpha: 1)
        
        //UITabBar.appearance().tintColor = UIColor.white
        let attributes = [NSAttributedStringKey.font:UIFont(name: "Baskerville", size: 10)!,NSAttributedStringKey.foregroundColor:UIColor.white]
        let attributes1 = [NSAttributedStringKey.font:UIFont(name: "Baskerville", size: 10)!,NSAttributedStringKey.foregroundColor:UIColor(red: 43/255, green: 180/255, blue: 0/255, alpha: 1)]
        
        UITabBarItem.appearance().setTitleTextAttributes(attributes, for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes(attributes1, for: .selected)
        
        
        let tabHome = tabBar.items![0]
        tabHome.title = "Home" // tabbar titlee
        tabHome.image=UIImage(named: "homeIcon.pdf")?.withRenderingMode(.alwaysOriginal) // deselect image
        tabHome.selectedImage = UIImage(named: "homeIconSelected.pdf")?.withRenderingMode(.alwaysOriginal) // select image
        tabHome.titlePositionAdjustment.vertical = tabHome.titlePositionAdjustment.vertical-4 // title position change
        
        let tabJournal = tabBar.items![1]
        tabJournal.title = "Journal"
        tabJournal.image=UIImage(named: "journalIcon.pdf")?.withRenderingMode(.alwaysOriginal)
        tabJournal.selectedImage=UIImage(named: "journalIconSelected.pdf")?.withRenderingMode(.alwaysOriginal)
        tabJournal.titlePositionAdjustment.vertical = tabJournal.titlePositionAdjustment.vertical-4
        
        let tabMain = tabBar.items![2]
        tabMain.title = "Prayer"
        tabMain.image=UIImage(named: "prayerIcon.pdf")?.withRenderingMode(.alwaysOriginal)
        tabMain.selectedImage=UIImage(named: "prayerIconSelected.pdf")?.withRenderingMode(.alwaysOriginal)
        tabMain.titlePositionAdjustment.vertical = tabMain.titlePositionAdjustment.vertical-4
        
        let tabCircles = tabBar.items![3]
        tabCircles.title = "Circles"
        tabCircles.image=UIImage(named: "circlesIcon.pdf")?.withRenderingMode(.alwaysOriginal)
        tabCircles.selectedImage=UIImage(named: "circlesIconSelected.pdf")?.withRenderingMode(.alwaysOriginal)
        tabCircles.titlePositionAdjustment.vertical = tabCircles.titlePositionAdjustment.vertical-4
        
        let tabSettings = tabBar.items![4]
        tabSettings.title = "Settings"
        tabSettings.image=UIImage(named: "settingsIcon.pdf")?.withRenderingMode(.alwaysOriginal)
        tabSettings.selectedImage=UIImage(named: "settingsIconSelected.pdf")?.withRenderingMode(.alwaysOriginal)
        tabSettings.titlePositionAdjustment.vertical = tabSettings.titlePositionAdjustment.vertical-4
        
        return tabBarController
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
