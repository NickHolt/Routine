//
//  CompletionStore.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import CoreData
import os.log

class CompletionStore: EntityStore<Completion> {
    
    let log = OSLog(subsystem: "com.redox.Routine", category: "CompletionStore")
        
    func getAllCompletions(for date: Date) -> Set<Completion> {
        return Set(allEntities.filter { completion in
            guard let completionDate = completion.date else {
                return false
            }
            
            return Calendar.current.isDate(completionDate, inSameDayAs: date)
        })
    }
    
    func getAllCompletions(for activity: Activity) -> Set<Completion> {
        return Set(allEntities.filter { completion in
            guard let completionActivity = completion.activity else {
                return false
            }
            
            return completionActivity == activity
        })
    }
    
    func delete(completion: Completion) throws {
        guard allEntities.contains(completion) else {
            throw EntityStore.Error.entityNotFound(completion)
        }
        
        try delete(entity: completion)
        allEntities.remove(completion)
    }
}
