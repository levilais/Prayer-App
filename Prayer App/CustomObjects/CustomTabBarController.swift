//
//  CustomTabBarController.swift
//  Prayer App
//
//  Created by Levi on 11/18/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation
import UIKit

class CustomTabBarController {
    func setTabbar() -> UITabBarController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController = UITabBarController()
        
        let HomeViewController = storyboard.instantiateViewController(withIdentifier: "HomeViewController")
        let JournalViewController = storyboard.instantiateViewController(withIdentifier: "JournalViewController")
        let MainViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController")
        let CirclesViewController = storyboard.instantiateViewController(withIdentifier: "CirclesViewController")
        let SettingsViewController = storyboard.instantiateViewController(withIdentifier: "SettingsViewController")
        
        let navHome = UINavigationController(rootViewController: HomeViewController)
        let navJournal = UINavigationController(rootViewController: JournalViewController)
        let navMain = UINavigationController(rootViewController: MainViewController)
        let navCircles = UINavigationController(rootViewController: CirclesViewController)
        let navSettings = UINavigationController(rootViewController: SettingsViewController)
                
        navHome.setNavigationBarHidden(true, animated: false)
        navJournal.setNavigationBarHidden(true, animated: false)
        navMain.setNavigationBarHidden(true, animated: false)
        navCircles.setNavigationBarHidden(true, animated: false)
        navSettings.setNavigationBarHidden(true, animated: false)
        
        tabBarController.viewControllers = [navHome,navJournal,navMain,navCircles,navSettings]
        
        let tabBar = tabBarController.tabBar
        tabBar.barTintColor = UIColor.StyleFile.BackgroundColor
        tabBar.backgroundColor = UIColor.StyleFile.BackgroundColor
        tabBar.tintColor = UIColor.StyleFile.DarkGrayColor
        
        UITabBar.appearance().tintColor = UIColor.StyleFile.DarkGrayColor
        let attributes = [NSAttributedStringKey.font:UIFont(name: "Baskerville", size: 12)!,NSAttributedStringKey.foregroundColor: UIColor.StyleFile.DarkGrayColor]
        let attributes1 = [NSAttributedStringKey.font: UIFont(name: "Baskerville-SemiBold", size: 12)!,NSAttributedStringKey.foregroundColor: UIColor.StyleFile.DarkGrayColor]
        
        UITabBarItem.appearance().setTitleTextAttributes(attributes, for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes(attributes1, for: .selected)
        
        
        let tabHome = tabBar.items![0]
        tabHome.title = "Home" // tabbar titlee
        tabHome.image=UIImage(named: "homeIcon.pdf")?.withRenderingMode(.alwaysOriginal)
        tabHome.selectedImage = UIImage(named: "homeIconSelected.pdf")?.withRenderingMode(.alwaysOriginal)
        tabHome.titlePositionAdjustment.vertical = tabHome.titlePositionAdjustment.vertical
        
        let tabJournal = tabBar.items![1]
        tabJournal.title = "Journal"
        tabJournal.image=UIImage(named: "journalIcon.pdf")?.withRenderingMode(.alwaysOriginal)
        tabJournal.selectedImage=UIImage(named: "journalIconSelected.pdf")?.withRenderingMode(.alwaysOriginal)
        tabJournal.titlePositionAdjustment.vertical = tabJournal.titlePositionAdjustment.vertical
        
        let tabMain = tabBar.items![2]
        tabMain.title = "Prayer"
        tabMain.image=UIImage(named: "prayerIcon.pdf")?.withRenderingMode(.alwaysOriginal)
        tabMain.selectedImage=UIImage(named: "prayerIconSelected.pdf")?.withRenderingMode(.alwaysOriginal)
        tabMain.titlePositionAdjustment.vertical = tabMain.titlePositionAdjustment.vertical
        
        let tabCircles = tabBar.items![3]
        tabCircles.title = "Circles"
        tabCircles.image=UIImage(named: "circlesIcon.pdf")?.withRenderingMode(.alwaysOriginal)
        tabCircles.selectedImage=UIImage(named: "circlesIconSelected.pdf")?.withRenderingMode(.alwaysOriginal)
        tabCircles.titlePositionAdjustment.vertical = tabCircles.titlePositionAdjustment.vertical
        
        let tabSettings = tabBar.items![4]
        tabSettings.title = "Settings"
        tabSettings.image=UIImage(named: "settingsIcon.pdf")?.withRenderingMode(.alwaysOriginal)
        tabSettings.selectedImage=UIImage(named: "settingsIconSelected.pdf")?.withRenderingMode(.alwaysOriginal)
        tabSettings.titlePositionAdjustment.vertical = tabSettings.titlePositionAdjustment.vertical
        
        tabBarController.selectedIndex = 2
        
        return tabBarController
    }
}
