//
//  ActivityStore.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import UIKit
import CoreData

class ActivityStore {
    enum Error: Swift.Error {
        case couldNotFetch
        case couldNotPersist
    }
    
    var allActivities = [Activity]()
    
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Routine")
        container.loadPersistentStores { (description, error) in
            if let error = error {
                preconditionFailure("Error setting up Core Data (\(error)).")
            }
        }
        return container
    }()

    @discardableResult func fetchNewActivity() -> Activity {
        let context = persistentContainer.viewContext
        var activity: Activity!
        
        context.performAndWait {
            activity = Activity(context: context)
        }

        allActivities.append(activity)

        return activity
    }
    
    func activities(for day: DayOfWeek) -> [Activity] {
        return allActivities.filter { (activity: Activity) -> Bool in
            guard let days = activity.daysOfWeek else {
                return false
            }
            
            return days.contains(day)
        }
    }
    
    func loadFromDisk() throws {
        // Load all Activities from CoreData
        let activityFetchRequest: NSFetchRequest<Activity> = Activity.fetchRequest()
        let sortByActivityTitle = NSSortDescriptor(key: #keyPath(Activity.title), ascending: true)
        activityFetchRequest.sortDescriptors = [sortByActivityTitle]
        
        let context = persistentContainer.viewContext
        var fetchError: Swift.Error?
        context.performAndWait {
            do {
                let activities = try context.fetch(activityFetchRequest)
                self.allActivities += activities
            } catch let error {
                fetchError = error
            }
        }
        
        if fetchError != nil {
            print("Could not fetch Activities from CoreData: \(String(describing: fetchError))")
            throw Error.couldNotFetch
        }
    }
    
    func persistToDisk() throws {
        do {
            try persistentContainer.viewContext.save()
        } catch let error {
            print("Error persisting Activities to disk: \(error)")
            throw Error.couldNotPersist
        }
    }
}
