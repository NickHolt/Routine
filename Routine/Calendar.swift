//
//  Calendar.swift
//  Routine
//
//  Created by Nick Holt on 5/19/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import Foundation

extension Calendar {
    func dayOfWeek(from date: Date) -> DayOfWeek {
        let weekday = self.component(.weekday, from: date)
        
        return DayOfWeek(rawValue: (weekday + Int(5)) % 7)!
    }
    
    func daysBetween(firstDate: Date, secondDate: Date) -> Int {
        let date1 = self.startOfDay(for: firstDate)
        let date2 = self.startOfDay(for: secondDate)
        
        let components = self.dateComponents([.day], from: date1, to: date2)
        
        return components.day!
    }
}
