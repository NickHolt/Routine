//
//  DayOfWeek.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import Foundation

public enum DayOfWeek: Int, CustomStringConvertible {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday
    
    public var description: String {
        switch self {
        case .monday:
            return "Mon"
        case .tuesday:
            return "Tue"
        case .wednesday:
            return "Wed"
        case .thursday:
            return "Thu"
        case .friday:
            return "Fri"
        case .saturday:
            return "Sat"
        case .sunday:
            return "Sun"
        }
    }
}

func string(for days: [DayOfWeek]) -> String {
    let sortedDays = days.sorted {
        (firstDayOfWeek, secondDayOfWeek) -> Bool in
        
        return firstDayOfWeek.rawValue < secondDayOfWeek.rawValue
    }
    
    return sortedDays.map { String(describing: $0) }.joined(separator: ", ")
}
