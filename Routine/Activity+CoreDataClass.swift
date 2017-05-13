//
//  Activity+CoreDataClass.swift
//  Routine
//
//  Created by Nick Holt on 5/11/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import Foundation
import CoreData

@objc(Activity)
public class Activity: NSManagedObject {
    var daysOfWeek: [DayOfWeek]! {
        didSet {
            // Set daysOfWeekBitField
            daysOfWeekBitField = 0
            
            guard let days = daysOfWeek else {
                return
            }

            for day in days {
                daysOfWeekBitField |= Int32(1 << day.rawValue)
            }
            
            print("Set daysOfWeekBitField for \(title ?? "UNKNOWN"): \(String(daysOfWeekBitField, radix:2))")
        }
    }
    
    override public func awakeFromFetch() {
        // Set daysOfWeek
        var daysOfWeek: [DayOfWeek] = []

        for i in DayOfWeek.Monday.rawValue...DayOfWeek.Sunday.rawValue {
            if daysOfWeekBitField & Int32(1 << i) != 0 {
                daysOfWeek.append(DayOfWeek(rawValue: i)!)
            }
        }
        
        self.daysOfWeek = daysOfWeek
        print("Set daysOfWeek for \(title ?? "UNKNOWN"): \(daysOfWeek)")
    }
}
