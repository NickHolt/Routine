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
    
    var persistentContainer: NSPersistentContainer!
    
    var allActivities = [Activity]()
    var allCompletions = [Activity: [Completion]]()

    func loadFromDisk() throws {
        try loadActivitiesFromDisk()
        try loadCompletionsFromDisk()
    }
    
    func persistToDisk() throws {
        let context = persistentContainer.viewContext
        guard context.hasChanges else {
            return
        }

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
    
    func getActivities(for date: Date) -> [Activity] {
        let day = Calendar.current.dayOfWeek(from: date)
        
        return allActivities.filter { activity in
            guard let startDate = activity.startDate else {
                return false
            }
            
            return startDate <= date && activity.daysOfWeek.contains(day)
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
    
    func getCompletionStreak(for activity: Activity, endingOn lastDate: Date, withPreviousFallback fallback: Bool = false) throws -> Int {
        guard let completions = allCompletions[activity] else {
            throw Error.activityNotFound(activity)
        }
        var recentCompletions = completions.sorted { $0.date!.compare($1.date!) == .orderedDescending }
        
        let calendar = NSCalendar.current
        
        // Get completion that lies on lastDate
        guard let mostRecentCompletionIndex = recentCompletions.index(where: { $0.date != nil && calendar.isDate($0.date!, inSameDayAs: lastDate) }) else {
            return 0
        }
        
        let mostRecentCompletion = recentCompletions[mostRecentCompletionIndex]
        
        // Count until a non-completion is found
        var streak: Int
        switch mostRecentCompletion.status {
        case .completed:
            streak = 1
        case .excused:
            streak = 0
        case .notCompleted:
            guard fallback else {
                return 0
            }
            streak = 0
        }
        
        for i in mostRecentCompletionIndex + 1..<recentCompletions.count {
            let completion = recentCompletions[i]
            
            guard completion.status != .notCompleted else {
                return streak
            }
            
            if completion.status == .completed {
                streak += 1
            }
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
    
    func scrubCompletions(startingFrom startDate: Date, endingOn endDate: Date) {
        var currentDate = startDate
        let finalDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate)!
        
        while (currentDate < finalDate) {
            let activities = getActivities(for: currentDate)
            
            for activity in activities {
                guard let _ = getCompletion(for: activity, on: currentDate) else {
                    continue
                }
                
                registerCompletion(for: activity, on: currentDate, withStatus: .notCompleted)
            }
            
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
    }
}
