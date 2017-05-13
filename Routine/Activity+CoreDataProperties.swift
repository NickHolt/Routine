//
//  Activity+CoreDataProperties.swift
//  Routine
//
//  Created by Nick Holt on 5/11/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import Foundation
import CoreData


extension Activity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Activity> {
        return NSFetchRequest<Activity>(entityName: "Activity")
    }

    @NSManaged public var daysOfWeekBitField: Int32
    @NSManaged public var title: String?
    @NSManaged public var uuid: UUID?
}
