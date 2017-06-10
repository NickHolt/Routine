//
//  CompletionHistory.swift
//  Routine
//
//  Created by Nick Holt on 5/28/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import Foundation
import os.log

class CompletionHistory {
        
    let log = OSLog(subsystem: "com.redox.Routine", category: "CompletionHistory")
    
    var activityStore: ActivityStore!
    var completionStore: CompletionStore!
    
    @discardableResult
    func registerCompletion(for activity: Activity, on date: Date, withStatus status: Completion.Status) -> Completion {
        
        deleteCompletion(for: activity, on: date)
        
        // MARK: TODO<nickholt> CoreData failure
        let completion = completionStore.getNewEntity()
        
        completion.activity = activity
        completion.date = date
        completion.status = status
        
        // MARK: TODO<nickholt> handle CoreDate failure
        try! completionStore.persistToDisk()
        
        return completion
    }
    
    func deleteCompletion(for activity: Activity, on date: Date) {
        
        guard let completion = getCompletion(for: activity, on: date) else {
            return
        }
        
        try! completionStore.delete(entity: completion)
    }
    
    func deleteCompletionHistory(for activity: Activity) throws {
        let completions = completionStore.getAllCompletions(for: activity)
        
        for completion in completions {
            try completionStore.delete(entity: completion)
        }
    }
    
    func getCompletion(for activity: Activity, on date: Date) -> Completion? {
        
        let completionsForDate = completionStore.getAllCompletions(for: date)
        let completionsForActivity = completionStore.getAllCompletions(for: activity)
        
        let completions = completionsForDate.intersection(completionsForActivity)
                
        if completions.count > 1 {
            os_log("Multiple completions found for Activity: %@ on %f", log: log, type: .error, activity, date.timeIntervalSinceReferenceDate)
            assertionFailure("Multiple completions found for \(activity) on \(date): \(completions)")
        }
        guard let completion = completions.first else {
            os_log("No completion data found for Activity: %@ on date: %f", log: log, type: .debug, activity, date.timeIntervalSinceReferenceDate)
            return nil
        }
        
        os_log("Retrieved completion for Activity: %@ on %@", log: log, type: .debug, completion, activity)

        return completion
    }
    
    func getCompletionStreak(for activity: Activity, endingOn lastDate: Date, withPreviousFallback fallback: Bool = false) throws -> Int {
        
        var allCompletions = Array(completionStore.getAllCompletions(for: activity))
        allCompletions = allCompletions.sorted { $0.date!.compare($1.date!) == .orderedDescending }
        
        guard let mostRecentCompletionIndex = allCompletions.index(where: {
            $0.date != nil && NSCalendar.current.isDate($0.date!, inSameDayAs: lastDate)
        }) else {
            // TODO<nick> this is weird - why do we have to have a Completion on lastDate?
            return 0
        }
        
        let mostRecentCompletion = allCompletions[mostRecentCompletionIndex]
        
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
        
        for i in mostRecentCompletionIndex + 1..<allCompletions.count {
            let completion = allCompletions[i]
            
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
            let activities = activityStore.getActivities(for: currentDate)
            
            for activity in activities {
                guard getCompletion(for: activity, on: currentDate) == nil else {
                    continue
                }
                
                os_log("Missing Completion data for Activity: %@ found on date: %f", log: log, type: .debug, activity, currentDate.timeIntervalSinceReferenceDate)
                registerCompletion(for: activity, on: currentDate, withStatus: .notCompleted)
            }
            
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
    }
}
