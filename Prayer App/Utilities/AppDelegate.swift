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
        
//        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//        UNUserNotificationCenter.current().requestAuthorization(
//            options: authOptions,
//            completionHandler: {_, _ in })
//        application.registerForRemoteNotifications()
//        
//        if let token = InstanceID.instanceID().token() {
//            print("token: \(token)")
//        }
//        
//        if let fcmToken = Messaging.messaging().fcmToken {
//            if let userID = Auth.auth().currentUser?.uid {
//                Database.database().reference().child("users").child(userID).child("messagingTokens").child(fcmToken).setValue(fcmToken)
//                print("fcmToken in refresh: \(fcmToken)")
//            }
//        }
        
        FirebaseHelper().loadFirebaseData()
        UserDefaultsHelper().getLoads()
        
        UserDefaultsHelper().getLastContactAuthStatus()
                
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
    
    // MARK: - Core Data stack
    
//    lazy var persistentContainer: NSPersistentContainer = {
//        /*
//         The persistent container for the application. This implementation
//         creates and returns a container, having loaded the store for the
//         application to it. This property is optional since there are legitimate
//         error conditions that could cause the creation of the store to fail.
//         */
//        let container = NSPersistentContainer(name: "Prayer")
//        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error as NSError? {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//
//                /*
//                 Typical reasons for an error here include:
//                 * The parent directory does not exist, cannot be created, or disallows writing.
//                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
//                 * The device is out of space.
//                 * The store could not be migrated to the current model version.
//                 Check the error message to determine what the actual problem was.
//                 */
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        })
//        return container
//    }()
//
//    // MARK: - Core Data Saving support
//
//    func saveContext () {
//        let context = persistentContainer.viewContext
//        if context.hasChanges {
//            do {
//                try context.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nserror = error as NSError
//                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//            }
//        }
//    }


}

