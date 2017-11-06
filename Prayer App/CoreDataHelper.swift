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
    init() {
        let container = NSPersistentContainer(name: "Prayer")
        container.loadPersistentStores { NSPersistentStoreDescription, error in
            if let error = error {
                print("levil \(error)")
            } else {
                print("levil Core Data Fine")
            }
        }
        
    }
    
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    func storePrayer(prayerCategory: UITextField, prayerText: UITextView) {
        // Create a NSManagedObjectContext object from the getContext() function
        let context = getContext()
        
        // Create an NSEntityDescription object from the Entity name pointed at the context we just created
        // Create the actual NSManagedObject we're going to save to the context with the description above
        // Set the values for the object
        if let entity = NSEntityDescription.entity(forEntityName: "Prayer", in: context) {
            let prayer = NSManagedObject(entity: entity, insertInto: context)
            if let category = prayerCategory.text {
                if let text = prayerText.text {
                    prayer.setValue(category, forKey: "prayerCategory")
                    prayer.setValue(text, forKey: "prayerText")
                    prayer.setValue(Date(), forKey: "timeStamp")
                    prayer.setValue(1, forKey: "prayerCount")
                    
                    // try to save it
                    do {
                        try context.save()
                        print("levil saved")
                    } catch {
                        
                    }
                }
            }
        }
    }
    
    func getPrayers() -> [NSManagedObject]? {
        // Create a fetch request to pull an array out of the Entity
        let fetchRequest: NSFetchRequest<Prayer> = Prayer.fetchRequest()
        // Because this could fail, we need to do a do / catch
        do {
            // use the getContext function above to get a context and then use the fetch request function to pass in the NSFetchRequest we created in this function right above
            let searchResults = try getContext().fetch(fetchRequest)
            // To see how many results we have (to make sure we're retreiving data) print the count
            print("levil - number of results \(searchResults.count)")
            // For each results, we want to put them into an array (note that the function itself is returning an array of NSManagedObjects.  We're using the results to create that array now.
            for result in searchResults as [NSManagedObject] {
                if let prayerTextCheck = result.value(forKey: "prayerCategory") as? String {
                    print("levil Result: \(prayerTextCheck)")
                }
            }
            // Now that the for loop filled the searchResults up with the searchResults fetched above, return searchResults as the array
            return searchResults as [NSManagedObject]
        } catch {
            print("unable to get results")
            return nil
        }
    }
}
