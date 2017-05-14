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
        let completionFetchRequest: NSFetchRequest<Completion> = Completion.fetchRequest()
        
        let sortByDate = NSSortDescriptor(key: #keyPath(Completion.date), ascending: true)
        completionFetchRequest.sortDescriptors = [sortByDate]
        
        let context = persistentContainer.viewContext
        var fetchError: Swift.Error?
        context.performAndWait {
            do {
                let completions = try context.fetch(completionFetchRequest)
                self.allCompletions += completions
            } catch let error {
                fetchError = error
            }
        }
        
        if fetchError != nil {
            print("Could not fetch Completions from CoreData: \(String(describing: fetchError))")
            throw Error.couldNotFetch
        } else {
            print("CompletionStore retrieved \(allCompletions.count) activities from CoreData")
        }
    }
    
    func persistToDisk() throws {
        do {
            try persistentContainer.viewContext.save()
        } catch let error {
            print("Error persisting Completions to disk: \(error)")
            throw Error.couldNotPersist
        }
    }
}
