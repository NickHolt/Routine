//
//  RoutineTestCase.swift
//  Routine
//
//  Created by Nick Holt on 6/10/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import XCTest
import CoreData

@testable import Routine

class RoutineTestCase: XCTestCase {
    
    var inMemoryContainer: NSPersistentContainer!
    
    var activityStore: ActivityStore!
    var completionStore: CompletionStore!
    
    var today: Date {
        return Date()
    }
    var yesterday: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: today)!
    }
    var tomorrow: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: today)!
    }
    
    override func setUp() {
        super.setUp()
        
        inMemoryContainer = NSPersistentContainer(name: "Routine")
        
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        
        inMemoryContainer.persistentStoreDescriptions = [description]
        inMemoryContainer.loadPersistentStores { (_, error) in
            assert(error == nil, "Unable to load in-memory store")
        }
        
        inMemoryContainer.viewContext.performAndWait {
            let _ = Activity(context: self.inMemoryContainer.viewContext)
            let _ = Completion(context: self.inMemoryContainer.viewContext)

            self.activityStore = ActivityStore(with: self.inMemoryContainer)
            self.completionStore = CompletionStore(with: self.inMemoryContainer)
        }
    }
    
    override func tearDown() {
        for activity in activityStore.allEntities {
            try! activityStore.delete(activity: activity)
        }
        for completion in completionStore.allEntities {
            try! completionStore.delete(entity: completion)
        }
    }
}
