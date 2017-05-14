//
//  ActivityStore.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import CoreData

class ActivityStore: EntityStore {
    var allActivities = [Activity]()
    
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
            return activity.daysOfWeek.contains(day)
        }
    }
    
    func loadFromDisk() throws {
        // Load all Activities from CoreData
        let activityFetchRequest: NSFetchRequest<Activity> = Activity.fetchRequest()
        activityFetchRequest.returnsObjectsAsFaults = false
        
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
        } else {
            print("ActivityStore retrieved \(allActivities.count) activities from disk")
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
