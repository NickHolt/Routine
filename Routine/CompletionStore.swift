//
//  CompletionStore.swift
//  Routine
//
//  Created by Nick Holt on 5/14/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import CoreData

class CompletionStore: EntityStore {
    
    var allCompletions = [Completion]()
    
    func registerCompletion(for activity: Activity, on date: Date) {
        // Stub
    }
    
    func registerNonCompletion(for activity: Activity, on date: Date) {
        // Stub
    }
    
    func getCompletions(for activity: Activity) {
        // Stub
    }
    
    func getCompletions(for date: Date) {
        // Stub
    }
    
    func getCompletions(for activity: Activity, on date: Date) {
        // Stub
    }
    
    func loadFromDisk() throws {
        // Stub
    }
    
    func persistToDisk() throws {
        // Stub
    }
}
