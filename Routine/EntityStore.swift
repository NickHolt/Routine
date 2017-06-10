//
//  EntityStore.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import CoreData
import os.log

class EntityStore<T: NSManagedObject> {
    
    enum Error: Swift.Error {
        case entityNotFound(T)
        case couldNotCreateEntity
        case couldNotDeleteEntity(T)
        case couldNotFetchEntities
        case couldNotPersistEntities
    }
    
    let entityStoreLog = OSLog(subsystem: "com.redox.Routine", category: "EntityStore")
    
    var persistentContainer: NSPersistentContainer
    
    var allEntities: Set<T>
    
    init(with persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
        allEntities = Set()
        
        do {
            allEntities = try Set(loadEntitiesFromDisk())
            
            os_log("Retrieved %u entities from CoreData", log: entityStoreLog, type: .info, allEntities.count)
        } catch {
            assertionFailure()
        }
    }
    
    func persistToDisk() throws {
        let context = persistentContainer.viewContext
        guard context.hasChanges else {
            return
        }
        
        do {
            try persistentContainer.viewContext.save()
            os_log("Successfully persisted to CoreData", log: entityStoreLog, type: .debug)
        } catch let error {
            os_log("Error persisting to CoreData: %@", log: entityStoreLog, type: .error, error.localizedDescription)
            throw Error.couldNotPersistEntities
        }
    }
    
    func loadEntitiesFromDisk(sortedBy sortDescriptors: [NSSortDescriptor] = []) throws -> [T] {
        let fetchRequest: NSFetchRequest<T> = T.fetchRequest() as! NSFetchRequest<T>
        
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.sortDescriptors = sortDescriptors
        
        var entities: [T]!
        var fetchError: Swift.Error?
        
        let context = persistentContainer.viewContext
        context.performAndWait {
            do {
                entities = try context.fetch(fetchRequest)
            } catch let error {
                fetchError = error
            }
        }
        
        guard fetchError == nil else {
            os_log("Could not fetch Activities from CoreData: %@", log: entityStoreLog, type: .error, fetchError!.localizedDescription)
            throw Error.couldNotFetchEntities
        }

        return entities
    }
    
    func getNewEntity() -> T {
        var entity: T!
        
        let context = persistentContainer.viewContext
        context.performAndWait {
            entity = T(context: context)
        }
        
        allEntities.insert(entity)
        
        return entity
    }

    func delete(entity: T) throws {
        guard allEntities.contains(entity) else {
            throw Error.entityNotFound(entity)
        }

        persistentContainer.viewContext.delete(entity)

        do {
            try persistToDisk()
            os_log("Removed entity: %@", log: entityStoreLog, type: .info, entity)
            allEntities.remove(entity)
        } catch {
            os_log("Failed to delete entity from CoreData: %@", log: entityStoreLog, type: .error, entity)
            throw Error.couldNotDeleteEntity(entity)
        }
    }
    
    func getAllEntities() -> Set<T> {
        return allEntities
    }
}
