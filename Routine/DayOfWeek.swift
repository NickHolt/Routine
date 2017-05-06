//
//  DayOfWeek.swift
//  Routine
//
//  Created by Nick Holt on 5/6/17.
//  Copyright © 2017 Redox. All rights reserved.
//

import Foundation

enum DayOfWeek: UInt8, CustomStringConvertible {
    case Monday    = 1
    case Tuesday   = 2
    case Wednesday = 4
    case Thursday  = 8
    case Friday    = 16
    case Saturday  = 32
    case Sunday    = 64
    
    var description: String {
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
