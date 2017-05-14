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
    
    
    func getCompletion(for activity: Activity, on date: Date) -> Completion? {
        let completions = allCompletions.filter { (completion: Completion) -> Bool in
            
            guard let completionActivity = completion.activity,
                  let completionDate = completion.date else {
                    
                return false
            }
            
            return completionActivity == activity && completionDate == date
        }
        assert(completions.count <= 1, "Multiple completions found for \(activity) on \(date)")
        
        return completions.first ?? nil
    }
    
    @discardableResult
    private func registerCompletion(for activity: Activity, on date: Date, wasCompleted: Bool) -> Completion {
        
        deleteCompletion(for: activity, on: date)

        let context = persistentContainer.viewContext
        var completion: Completion!
        
        context.performAndWait {
            completion = Completion(context: context)
            completion.activity = activity
            completion.date = date
            completion.wasCompleted = wasCompleted
        }
        
        allCompletions.append(completion)
        
        return completion
    }
    
    @discardableResult func registerCompletion(for activity: Activity, on date: Date) -> Completion {
        return registerCompletion(for: activity, on: date, wasCompleted: true)
    }
    
    @discardableResult func registerNonCompletion(for activity: Activity, on date: Date) -> Completion {
        return registerCompletion(for: activity, on: date, wasCompleted: false)
    }
    
    private func deleteCompletion(for activity: Activity, on date: Date) {
        guard let completion = getCompletion(for: activity, on: date) else {
            return
        }
        
        persistentContainer.viewContext.delete(completion)
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
