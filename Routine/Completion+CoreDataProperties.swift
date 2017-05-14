//
//  Completion+CoreDataProperties.swift
//  Routine
//
//  Created by Nick Holt on 5/14/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import Foundation
import CoreData


extension Completion {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Completion> {
        return NSFetchRequest<Completion>(entityName: "Completion")
    }

    @NSManaged public var wasCompleted: Bool
    @NSManaged public var date: Date?
    @NSManaged public var activity: Activity?

}
