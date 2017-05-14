//
//  EntityStore.swift
//  Routine
//
//  Created by Nick Holt on 5/14/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import CoreData

class EntityStore {
    enum Error: Swift.Error {
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
}
