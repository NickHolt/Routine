//
//  ActivityStore.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import CoreData
import os.log

class ActivityStore: EntityStore<Activity> {
    
    let log = OSLog(subsystem: "com.redox.Routine", category: "ActivityStore")
    
    func getAllActiveActivities() -> Set<Activity> {
        return Set(allEntities.filter { $0.isActive })
    }
    
    func getAllInactiveActivities() -> Set<Activity> {
        return Set(allEntities.filter { !$0.isActive })
    }
        
    func getActivities(for date: Date) -> Set<Activity> {
        let day = Calendar.current.dayOfWeek(from: date)
        
        let activities = allEntities.filter { activity in
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
    
    func archive(activity: Activity) throws {
        guard allEntities.contains(activity) else {
            throw EntityStore.Error.entityNotFound(activity)
        }
        
        activity.isActive = false
        
        try persistToDisk()
        os_log("Removed Activity: %@", log: log, type: .info, activity)
    }
    
    func delete(activity: Activity) throws {
        guard allEntities.contains(activity) else {
            throw EntityStore.Error.entityNotFound(activity)
        }
        
        try delete(entity: activity)
        allEntities.remove(activity)
    }
}
