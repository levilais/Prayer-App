//
//  CoreDataHelper.swift
//  Prayer App
//
//  Created by Levi on 11/6/17.
//  Copyright © 2017 App Volks. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class CoreDataHelper {
//    init() {
//        let container = NSPersistentContainer(name: "Prayer")
//        container.loadPersistentStores { NSPersistentStoreDescription, error in
//            if let error = error {
//                print("levil \(error)")
//            } else {
//                print("levil Core Data Fine")
//            }
//        }
//
//    }
//
    
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
//
//    func storePrayer(prayerCategory: UITextField, prayerText: UITextView) {
//        // Create a NSManagedObjectContext object from the getContext() function
//        let context = getContext()
//
//        // Create an NSEntityDescription object from the Entity name pointed at the context we just created
//        // Create the actual NSManagedObject we're going to save to the context with the description above
//        // Set the values for the object
//        if let entity = NSEntityDescription.entity(forEntityName: "Prayer", in: context) {
//            let prayer = NSManagedObject(entity: entity, insertInto: context)
//            if let category = prayerCategory.text {
//                if let text = prayerText.text {
//                    prayer.setValue(category, forKey: "prayerCategory")
//                    prayer.setValue(text, forKey: "prayerText")
//                    prayer.setValue(Date(), forKey: "timeStamp")
//                    prayer.setValue(1, forKey: "prayerCount")
//
//                    // try to save it
//                    do {
//                        try context.save()
//                        print("levil saved")
//                    } catch {
//
//                    }
//                }
//            }
//        }
//    }

    func getPrayersCategories() -> [String]? {
        var categoryHeaders: [String] = [String]()
        let fetchRequest: NSFetchRequest<Prayer> = Prayer.fetchRequest()
        
        do {
            let searchResults = try getContext().fetch(fetchRequest)
            for result in searchResults as [NSManagedObject] {
                if let prayerCategoryCheck = result.value(forKey: "prayerCategory") as? String {
                    print("levil Result: \(prayerCategoryCheck)")
                    if !categoryHeaders.contains(prayerCategoryCheck) {
                        categoryHeaders.append(prayerCategoryCheck)
                    }
                }
            }
            return categoryHeaders as [String]
        } catch {
            print("unable to get results")
            return nil
        }
    }
}
