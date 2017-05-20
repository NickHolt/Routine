//
//  ActivityStore.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import CoreData

class ActivityStore {
    
    enum Error: Swift.Error {
        case activityNotFound(Activity)
        case couldNotFetch
        case couldNotPersist
    }
    
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Routine")
        container.loadPersistentStores { (description, error) in
            if let error = error {
                preconditionFailure("Error setting up Core Data (\(error)).")
            }
        }
        return container
    }()
    
    var allActivities = [Activity]()
    var allCompletions = [Activity: [Completion]]()

    func loadFromDisk() throws {
        try loadActivitiesFromDisk()
        try loadCompletionsFromDisk()
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

// MARK: Methods regarding activities
extension ActivityStore {
    
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
    
    func remove(activity: Activity) throws {
        guard let activityIndex = allActivities.index(of: activity) else {
            throw Error.activityNotFound(activity)
        }
        
        allActivities.remove(at: activityIndex)
        persistentContainer.viewContext.delete(activity)
        
        do {
            try persistToDisk()
        } catch {
            print("Failed to delete \(activity) from disk. Might work on next save.")
        }
    }
    
    func loadActivitiesFromDisk() throws {
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
            print("ActivityStore retrieved \(allActivities.count) activities from CoreData")
        }
    }
}

// MARK: Methods regarding completions
extension ActivityStore {
    
    func getCompletion(for activity: Activity, on date: Date) -> Completion? {
        
        let completions = allCompletions[activity]?.filter { (completion: Completion) -> Bool in
            
            guard let completionDate = completion.date else {
                    return false
            }
            
            return Calendar.current.isDate(completionDate, inSameDayAs: date)
        }
        assert(completions?.count ?? 0 <= 1, "Multiple completions found for \(activity) on \(date)")
        
        return completions?.first ?? nil
    }
    
    func getCompletionStreak(for activity: Activity, endingOn lastDate: Date) throws -> Int {
        guard let completions = allCompletions[activity] else {
            throw Error.activityNotFound(activity)
        }
        var recentCompletions = Array(completions.reversed())
        
        let calendar = NSCalendar.current
        
        // Get completion that lies on lastDate
        guard let mostRecentCompletionIndex = recentCompletions.index(where: { $0.date != nil && calendar.daysBetween(firstDate: $0.date!, secondDate: lastDate) == 0 }) else {
            return 0
        }
        
        let mostRecentCompletion = recentCompletions[mostRecentCompletionIndex]
        guard mostRecentCompletion.status == .completed, var lastCheckedDate = mostRecentCompletion.date else {
            return 0
        }
        
        // Count until a non-completion is found
        var streak = 1
        for i in mostRecentCompletionIndex + 1..<recentCompletions.count {
            let completion = recentCompletions[i]
            
            guard completion.status == .completed else {
                return streak
            }
            guard let date = completion.date else {
                return streak
            }
            guard calendar.daysBetween(firstDate: date, secondDate: lastCheckedDate) == 1 else {
                return streak
            }
            
            lastCheckedDate = date
            streak += 1
        }
        
        return streak
    }
    
    private func add(completion: Completion, for activity: Activity) {
        if allCompletions[activity] == nil {
            allCompletions[activity] = []
        }
        
        allCompletions[activity]!.append(completion)
    }
    
    @discardableResult
    func registerCompletion(for activity: Activity, on date: Date, withStatus status: Completion.Status) -> Completion {
        
        deleteCompletion(for: activity, on: date)
        
        let context = persistentContainer.viewContext
        var completion: Completion!
        
        context.performAndWait {
            completion = Completion(context: context)
            completion.activity = activity
            completion.date = date
            completion.status = status
        }
        
        add(completion: completion, for: activity)
        
        do {
            try persistToDisk()
        } catch {
            print("ActivityStore could not save on completion change")
        }
        
        return completion
    }
    
    private func deleteCompletion(for activity: Activity, on date: Date) {
        guard let completion = getCompletion(for: activity, on: date) else {
            return
        }
        
        persistentContainer.viewContext.delete(completion)
        allCompletions[activity]!.remove(at: (allCompletions[activity]?.index(of: completion))!)
    }
    
    func loadCompletionsFromDisk() throws {
        // Load all Completions from CoreData
        let completionFetchRequest: NSFetchRequest<Completion> = Completion.fetchRequest()
        
        let sortByDate = NSSortDescriptor(key: #keyPath(Completion.date), ascending: true)
        completionFetchRequest.sortDescriptors = [sortByDate]
        
        let context = persistentContainer.viewContext
        var fetchError: Swift.Error?
        context.performAndWait {
            do {
                let completions = try context.fetch(completionFetchRequest)
                for completion in completions {
                    guard let activity = completion.activity else {
                        continue
                    }
                    
                    self.add(completion: completion, for: activity)
                }
                
                print("ActivityStore retrieved \(completions.count) completions from CoreData")
            } catch let error {
                fetchError = error
                print("Could not fetch Completions from CoreData: \(String(describing: error))")
            }
        }
        
        if fetchError != nil {
            throw Error.couldNotFetch
        }
    }
}
