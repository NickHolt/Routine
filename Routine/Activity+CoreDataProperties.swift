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

    public var daysOfWeek: [DayOfWeek] {
        set {
            // Generate bit field
            var bitField = 0
            
            for day in newValue {
                bitField |= 1 << day.rawValue
            }

            self.willChangeValue(forKey: "daysOfWeek")
            self.setPrimitiveValue(bitField, forKey: "daysOfWeek")
            self.didChangeValue(forKey: "daysOfWeek")
        }
        get {
            self.willAccessValue(forKey: "daysOfWeek")
            let bitField = self.primitiveValue(forKey: "daysOfWeek") as! Int
            self.didAccessValue(forKey: "daysOfWeek")
            
            // Generate days from bitfield
            var daysOfWeek: [DayOfWeek] = []
            
            for i in DayOfWeek.Monday.rawValue...DayOfWeek.Sunday.rawValue {
                if bitField & (1 << i) != 0 {
                    daysOfWeek.append(DayOfWeek(rawValue: i)!)
                }
            }
            
            return daysOfWeek
        }
    }
    
    @NSManaged public var title: String?
    @NSManaged public var uuid: UUID?
    @NSManaged public var startDate: Date?
    @NSManaged public var completions: NSSet?

}

// MARK: Generated accessors for completions
extension Activity {

    @objc(addCompletionsObject:)
    @NSManaged public func addToCompletions(_ value: Completion)

    @objc(removeCompletionsObject:)
    @NSManaged public func removeFromCompletions(_ value: Completion)

    @objc(addCompletions:)
    @NSManaged public func addToCompletions(_ values: NSSet)

    @objc(removeCompletions:)
    @NSManaged public func removeFromCompletions(_ values: NSSet)

}
