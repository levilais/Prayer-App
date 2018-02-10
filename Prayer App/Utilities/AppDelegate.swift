//
//  AppDelegate.swift
//  Prayer App
//
//  Created by Levi on 10/23/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FirebaseDatabase
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        window=UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = CustomTabBarController().setTabbar()
        self.window?.makeKeyAndVisible()
        window?.backgroundColor=UIColor.white
        
        UITextView.appearance().tintColor = UIColor.StyleFile.DarkGrayColor
        
        UITabBar.appearance().layer.borderWidth = 0.0
        UITabBar.appearance().clipsToBounds = true
        
        UISwitch.appearance().onTintColor = UIColor.StyleFile.LightGrayColor
        UISwitch.appearance().thumbTintColor = UIColor.StyleFile.GoldColor
        
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
        
        
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        FirebaseHelper().loadFirebaseData()
        UserDefaultsHelper().getLoads()
        
        UserDefaultsHelper().getLastContactAuthStatus()
        
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                ConnectionTracker.isConnected = true
            } else {
                ConnectionTracker.isConnected = false
            }
        })
                
        return true
    }
    
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        if let userID = Auth.auth().currentUser?.uid {
            Database.database().reference().child("users").child(userID).child("messagingTokens").child(fcmToken).setValue(fcmToken)
            print("fcmToken refreshed: \(fcmToken)")
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//        self.saveContext()
    }

}

