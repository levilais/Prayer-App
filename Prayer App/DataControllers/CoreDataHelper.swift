//
//  CoreDataHelper.swift
//  Prayer App
//
//  Created by Levi on 11/6/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

//import Foundation
//import CoreData
//import UIKit
//
//class CoreDataHelper {
//    
//    func getContext () -> NSManagedObjectContext {
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        return appDelegate.persistentContainer.viewContext
//    }
//    
////    func getPrayersCategories() -> [String]? {
////        var categoryHeaders: [String] = [String]()
////        let fetchRequest: NSFetchRequest<Prayer> = Prayer.fetchRequest()
////
////        do {
////            let searchResults = try getContext().fetch(fetchRequest)
////            for result in searchResults as [NSManagedObject] {
////                if let prayerCategoryCheck = result.value(forKey: "prayerCategory") as? String {
////                    print("levil Result: \(prayerCategoryCheck)")
////                    if !categoryHeaders.contains(prayerCategoryCheck) {
////                        categoryHeaders.append(prayerCategoryCheck)
////                    }
////                }
////            }
////            return categoryHeaders as [String]
////        } catch {
////            print("unable to get results")
////            return nil
////        }
////    }
//}

