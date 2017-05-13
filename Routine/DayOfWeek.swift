//
//  DayOfWeek.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import Foundation

public enum DayOfWeek: Int, CustomStringConvertible {
    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
    case Sunday
    
    public var description: String {
        switch self {
        case .Monday:
            return "Mon"
        case .Tuesday:
            return "Tue"
        case .Wednesday:
            return "Wed"
        case .Thursday:
            return "Thu"
        case .Friday:
            return "Fri"
        case .Saturday:
            return "Sat"
        case .Sunday:
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

extension Calendar {
    func dayOfWeek(from date: Date) -> DayOfWeek {
        let weekday = self.component(.weekday, from: date)
        
        return DayOfWeek(rawValue: (weekday + Int(5)) % 7)!
    }
}
