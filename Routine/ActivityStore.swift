//
//  ActivityStore.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import CoreData
import os.log

class ActivityStore {
    
    enum Error: Swift.Error {
        case activityNotFound(Activity)
        case couldNotFetch
        case couldNotPersist
    }
    
    let log = OSLog(subsystem: "com.redox.Routine", category: "ActivityStore")
    
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
            os_log("Successfully persisted to CoreData", log: log, type: .debug)
        } catch let error {
            os_log("Error persisting to CoreData: %@", log: log, type: .error, error.localizedDescription)
            throw Error.couldNotPersist
        }
    }
}

// MARK: Methods regarding activities
extension ActivityStore {
    
    func getNewActivity() -> Activity {
        let description = NSEntityDescription.entity(forEntityName: "Activity", in: persistentContainer.viewContext)!
        let activity = Activity.init(entity: description, insertInto: nil)
        
        os_log("Created new, untracked Activity: %@", log: log, type: .debug, activity)
        
        return activity
    }
    
    func insertNew(activity: Activity) throws {
        guard allActivities.index(of: activity) == nil else {
            assertionFailure("New Activity was already registered: \(activity)")
            os_log("A new Activity was inserted, which was already known: %@", log: log, type: .error, activity)
            return
        }
        
        allActivities.append(activity)
        persistentContainer.viewContext.insert(activity)
        
        if let startDate = activity.startDate {
            scrubCompletions(for: activity, startingFrom: startDate, endingOn: Date())
        } else {
            assertionFailure("New Activity entered without start date: \(activity)")
        }

        try persistToDisk()
    }
    
    func getAllActiveActivities() -> Set<Activity> {
        return Set(allActivities.filter { $0.isActive })
    }
    
    func getAllInactiveActivities() -> Set<Activity> {
        return Set(allActivities.filter { !$0.isActive })
    }
    
    func getHistoricActivities(for date: Date) -> Set<Activity> {
        let completions = getAllCompletions(for: date)
        let activities = Set(completions.filter { $0.activity != nil }.map { $0.activity! })
        
        os_log("Fetched %u archived Activities for %f", log: log, type: .debug, activities.count, date.timeIntervalSinceReferenceDate)

        return activities
    }
    
    func getNewActivities(for date: Date) -> Set<Activity> {
        let day = Calendar.current.dayOfWeek(from: date)

        let activities = allActivities.filter { activity in
            guard activity.isActive else {
                return false
            }
            guard let startDate = activity.startDate else {
                return false
            }
            
            return startDate <= date && activity.daysOfWeek.contains(day)
        }
        
        os_log("Fetched %u active Activities for %f", log: log, type: .debug, activities.count, date.timeIntervalSinceReferenceDate)
        
        return Set(activities)
    }
    
    func getAllActivities(for date: Date) -> Set<Activity> {
        return getHistoricActivities(for: date).union(getNewActivities(for: date))
    }
    
    func archive(activity: Activity) throws {
        guard allActivities.contains(activity) else {
            throw Error.activityNotFound(activity)
        }
        
        activity.isActive = false
        
        do {
            try persistToDisk()
            os_log("Removed Activity: %@", log: log, type: .info, activity)
        } catch {
            os_log("Failed to archive Activity: %@", log: log, type: .error, activity)
        }
    }
    
    func delete(activity: Activity) throws {
        guard let activityIndex = allActivities.index(of: activity) else {
            throw Error.activityNotFound(activity)
        }
        
        allActivities.remove(at: activityIndex)
        persistentContainer.viewContext.delete(activity)
        
        if let completions = allCompletions[activity] {
            for completion in completions {
                persistentContainer.viewContext.delete(completion)
            }
        }
        
        do {
            try persistToDisk()
            os_log("Removed Activity: %@", log: log, type: .info, activity)
        } catch {
            os_log("Failed to delete Activity data from CoreData: %@", log: log, type: .error, activity)
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
        
        guard fetchError == nil else {
            os_log("Could not fetch Activities from CoreData: %@", log: log, type: .error, fetchError!.localizedDescription)
            throw Error.couldNotFetch
        }
        
        os_log("ActivityStore retrieved %u activities from CoreData", log: log, type: .info, allActivities.count)
    }
}

// MARK: Methods regarding completions
extension ActivityStore {
    
    func getAllCompletions(for date: Date) -> Set<Completion> {
        var completions = Set<Completion>()
        
        for (_, activityCompletions) in allCompletions {
            for activityCompletion in activityCompletions {
                guard let completionDate = activityCompletion.date, Calendar.current.isDate(completionDate, inSameDayAs: date) else {
                    continue
                }
                
                completions.insert(activityCompletion)
            }
        }
        
        return completions
    }
    
    func getCompletion(for activity: Activity, on date: Date) -> Completion? {
        
        guard let completions = allCompletions[activity]?.filter({
            guard let completionDate = $0.date else {
                return false
            }
            
            return Calendar.current.isDate(completionDate, inSameDayAs: date)

        }) else {
            return nil
        }
        
        if completions.count > 1 {
            os_log("Multiple completions found for Activity: %@ on %f", log: log, type: .error, activity, date.timeIntervalSinceReferenceDate)
            assertionFailure("Multiple completions found for \(activity) on \(date)")
        }
        guard let completion = completions.first else {
            os_log("No completion data found for Activity: %@ on date: %f", log: log, type: .debug, activity, date.timeIntervalSinceReferenceDate)
            return nil
        }
        
        os_log("Retrieved completion for Activity: %@ on %@", log: log, type: .debug, completion, activity)

        return completion
    }
    
    func getCompletionStreak(for activity: Activity, endingOn lastDate: Date, withPreviousFallback fallback: Bool = false) throws -> Int {
        guard let completions = allCompletions[activity] else {
            os_log("Streak requested for unknown Activity: %@", log: log, type: .error, activity)
            throw Error.activityNotFound(activity)
        }
        var recentCompletions = completions.sorted { $0.date!.compare($1.date!) == .orderedDescending }
        
        let calendar = NSCalendar.current
        
        // Get completion that lies on lastDate
        guard let mostRecentCompletionIndex = recentCompletions.index(where: { $0.date != nil && calendar.isDate($0.date!, inSameDayAs: lastDate) }) else {
            return 0
        }
        
        let mostRecentCompletion = recentCompletions[mostRecentCompletionIndex]
        
        os_log("Completion streak for %@ ends with %@.", log: log, type: .debug, activity, mostRecentCompletion)
        
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
                os_log("Non-completion found: %@. Streak: %d", log: log, type: .debug, completion, streak)
                return streak
            }
            
            if completion.status == .completed {
                streak += 1
            }
        }
        
        os_log("No non-completions found. Streak: %d", log: log, type: .debug, streak)

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
        
        do {
            try persistToDisk()
            add(completion: completion, for: activity)
            os_log("New Completion: %@ registered for Activity: %@", log: log, type: .info, completion, activity)
        } catch {
            os_log("New Completion: %@ for Activity: %@ could not be saved to CoreData", log: log, type: .error, completion, activity)
        }
        
        return completion
    }
    
    private func deleteCompletion(for activity: Activity, on date: Date) {
        guard let completion = getCompletion(for: activity, on: date) else {
            return
        }
        
        persistentContainer.viewContext.delete(completion)
        allCompletions[activity]!.remove(at: (allCompletions[activity]?.index(of: completion))!)
        
        os_log("Completion data for Activity: %@ deleted for date: %f", log: log, type: .debug, activity, date.timeIntervalSinceReferenceDate)
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
                
                os_log("Retrieved %d Completions from CoreData", log: self.log, type: .debug, completions.count)
            } catch let error {
                fetchError = error
                os_log("Could not fetch Completions from CoreData: %@", log: self.log, type: .error, error.localizedDescription)
            }
        }
        
        if fetchError != nil {
            throw Error.couldNotFetch
        }
    }
    
    func scrubCompletions(for activity: Activity, startingFrom startDate: Date, endingOn endDate: Date) {
        guard let activityStartDate = activity.startDate else {
            assertionFailure("Could not find start date for Activity: \(activity)")
            return
        }

        var currentDate = startDate
        let finalDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate)! // This ensures we don't get screwed by e.g. 1PM vs 2PM

        os_log("Filling in missing Completion data for %@, dates %f to %f", log: log, type: .debug, activity, startDate.timeIntervalSinceReferenceDate, endDate.timeIntervalSinceReferenceDate)

        var count = 0
        while (currentDate <= finalDate) {
            defer {
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
            }
            
            let dayOfWeek = Calendar.current.dayOfWeek(from: currentDate)
            guard activity.daysOfWeek.contains(dayOfWeek) else {
                continue
            }
            guard activityStartDate <= currentDate else {
                continue
            }
            guard getCompletion(for: activity, on: currentDate) == nil else {
                continue
            }
            
            os_log("Missing Completion data for Activity: %@ found on date: %f", log: log, type: .debug, activity, currentDate.timeIntervalSinceReferenceDate)
            registerCompletion(for: activity, on: currentDate, withStatus: .notCompleted)
        }
    }
    
    func scrubCompletions(startingFrom startDate: Date, endingOn endDate: Date) {
        var currentDate = startDate
        let finalDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate)!
        
        os_log("Filling in missing Completion data from dates %f to %f", log: log, type: .debug, startDate.timeIntervalSinceReferenceDate, endDate.timeIntervalSinceReferenceDate)
        
        while (currentDate < finalDate) {
            let activities = getNewActivities(for: currentDate)
            
            for activity in activities {
                guard let _ = getCompletion(for: activity, on: currentDate) else {
                    continue
                }
                
                os_log("Missing Completion data for Activity: %@ found on date: %f", log: log, type: .debug, activity, currentDate.timeIntervalSinceReferenceDate)
                registerCompletion(for: activity, on: currentDate, withStatus: .notCompleted)
            }
            
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
    }
}
